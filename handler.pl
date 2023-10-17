#!/usr/bin/env perl
use v5.030;
use strictures 2;
use warnings;
no warnings 'uninitialized';

#suffering from buffering
$|=1;

use Carp;
use JSON::PP;
sub handle {

    # Note: step name is confusing because there is mast step name and deployment step name
    my ($payload, $context) = @_;
    my $all_input = $payload->{input};
    my $deployment_spec = $all_input->{deployment_spec};
    my $state = $all_input->{state};
    my $execution_state = $all_input->{execution_state};

    my $completed_steps = $execution_state->{completed_steps};
    my $step_name;
    if( (not defined $completed_steps) || (scalar(@{$completed_steps}) == 0) ) {
        # use the "first step"
        $step_name = $deployment_spec->{StartAt}
    } else {
        # get the step name that the previous step points to
        my $previous_step_name = $completed_steps->[-1];
        $step_name = $deployment_spec->{States}->{$previous_step_name}->{Next};
    }
    # "Parameters": {
    #                 "step_name": "contexts_validate_service_spec",
    #                 "service_spec_json.$": "$.service_spec_json",
    #                 "context": [
    #                     "prestaging",
    #                     "standby"
    #                 ],
    #                 "output_file": "/tmp/deployment.json"
    #             },
    # get and extract parameters
    my $step_parameters = $deployment_spec->{States}->{$step_name}->{Parameters};
    my @mast_args = keys %{$step_parameters};
    my $mast_step_name = $step_parameters->{step_name};

    confess "step_name not provided. exiting. also needs to be caught in the spec" unless defined $mast_step_name;
    my $script_location = "/opt/bin/$mast_step_name"; # don't know how to not hardcode this

    my @p_args = ($script_location,);
    @mast_args = grep(!/step_name/, @mast_args); # need to hardcode this

    for(@mast_args) {
        
        my $hyphens_arg = $_;
        my $next_val = $step_parameters->{$_};

        # check if arg has .$ suffix which means we need to pull from arguments and drop the .$
        # we want it to start with any alpha numberic and it can contain underscores and hyphens
        # it can not end with a hyphen or an underscore
        if($hyphens_arg =~ /^[a-zA-Z0-9]+[a-zA-Z0-9_-]*[a-zA-Z0-9]+\.\$$/){
            # the value will be prefixed with $. which indicates where to grab the arguments from in the state key
            if($next_val !~ /^(\$\.)[a-zA-Z0-9]+[\.a-zA-Z0-9_-]*[a-zA-Z0-9]+$/){
                confess "keys with .\$ suffix are expected to have values with \$. prefix. $next_val was provided as the value for the $hyphens_arg argument";
            }
            # resolve the value from the state
            # drop the $.
            my $data_path_in_state = substr($next_val, 2);
            my @x = split(/\./, $data_path_in_state); # ("a", "c")
            my $current_value = $state;
            for my $k (@x){
                $current_value = $current_value->{$k};
            }
            confess "value was not found for $data_path_in_state" unless defined $current_value;
            $next_val = $current_value;
            # drop the .$
            $hyphens_arg = substr($hyphens_arg, 0, -2);
        }
        $hyphens_arg=~s/_/-/g;
        $hyphens_arg = "--${hyphens_arg}";
        # if a val is an array, then split the array into individual arguments
        if (ref $next_val eq 'ARRAY'){
            for my $val (@{$next_val}) {
                my @arg_pair = ($hyphens_arg, $val);
                push(@p_args, @arg_pair);
            }
        } else {
            my @arg_pair = ($hyphens_arg, $next_val);
            push(@p_args, @arg_pair);
        }
    }
    # TODO: capture output instead of exiting program on failure
    system("perl", @p_args) == 0
        or die "system perl @p_args failed: $?";

    # $deployment_spec->{States}->{$step_name}->{Parameters}->{output_file}
    # This is a weird implementation of our output management
    # basically mast only outputs IF output file is found. Not sure if there's a way
    # we could change it out to stdout, but then we'd likely need to buffer and parse
    # or stream the response or something that I don't completely understand
    # it seems reasonable to just read from a file since we have access to it
    if(defined $deployment_spec->{States}->{$step_name}->{Parameters}->{output_file}) {

    
        # if output file exists, read from output file and populate the return payload
        my %step_output;
        my $file = $deployment_spec->{States}->{$step_name}->{Parameters}->{output_file};

        open my $info, $file or die "Could not open $file: $!";
        while( my $line = <$info>)  {
            chomp $line; 
            my @spl = split("=", $line);
            my $key = $spl[0];
            my $value = $spl[1];
            $step_output{$key} = $value;
        }
        close $info;
        my $step_result_path = $deployment_spec->{States}->{$step_name}->{ResultPath};
        $state->{$step_result_path} = \%step_output;
    }
    # make updates to the input that will be passed
    # you cannot make changes to the deployment_spec by definition
    push(@{$completed_steps}, $step_name);
    $all_input->{execution_state}->{completed_steps} = $completed_steps;

    if(defined $deployment_spec->{States}->{$step_name}->{Next}){
        $all_input->{execution_state}->{status} = "EXECUTING";
    } elsif(defined $deployment_spec->{States}->{$step_name}->{End}) {
        $all_input->{execution_state}->{status} = "DONE";
    } else {
        confess "Workflow step validation failed. This needs to be caught in a spec valiation step and not here";
    }
    return $all_input;
}
1;
