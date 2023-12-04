#!/usr/bin/env perl
use v5.030;
use strictures 2;
use warnings;
no warnings 'uninitialized';

#suffering from buffering
$|=1;

use Carp;
use JSON::PP;
use Scalar::Util 'looks_like_number';
use Data::Dumper;
use Data::UUID;
 

use Data::UUID;
 

# use AWS::CLIWrapper;
use POSIX;

# Logger helper module for aws lambda request
# use Topsail::CustomLogger qw(get_logger);
# my $log = get_logger();

sub handle {

    # Note: step name is confusing because there is mast step name and deployment step name
    my ($service_manifest, $pipeline_variables, $deployment_spec) = @_;

    my $HOME = $ENV{HOME};

    my $ug    = Data::UUID->new;
    my $uuid = $ug->create();
    my $dir_path = $ug->to_string( $uuid );
    my $temporary_path_prefix = "tmp/${dir_path}";
    my $workflow_temporary_directory_path = "${HOME}/${temporary_path_prefix}";
    $ENV{HOST_TEMPORARY_DIRECTORY} = $workflow_temporary_directory_path;

    system("mkdir -p $workflow_temporary_directory_path") == 0
        or die "system mkdir failed: $?";
    my $overall_state_of_the_workflow = "NORMAL";
    # We just need the deployment manifest - The fact of keeping them together is just a technicality
    # So we need a "get service manifest" from label or tag or url or directly from file
    # We should pass "raw" service manifest
    ####
    # Initializing the pipeline
    ###
    
    my $workflow_state = $pipeline_variables;
    my %workflow_state = %{$workflow_state};
    my @workflow_contexts = ();
   

    ### "deploy" will need to be removed. since itself is context
    ### We do this is everything is a-ok
    # This needs to be "global" so that if the overall deployment context "shifts" we can get the new deployment context


    my $step_name = $deployment_spec->{StartAt};
    ### List of executed steps
    ### Log location
    ### Abort button
    ### All the "scaffolding"
    ### Get collapsed pipeline based on current contexts
    

    # my $context = '["prestaging", "active"]';
    # $workflow_state{context} = $context;
    

    my @executed_steps = ();
    my @completed_steps = ();

    my $step_script;
    while(1){

        # If step of type PASS then we just end it.
        my $step_type = $deployment_spec->{States}->{$step_name}->{Type};
        if($step_type eq 'PASS' and defined $deployment_spec->{States}->{$step_name}->{End}){ #we're just going to assume this is how we want it for now
            return 'END';
        }
        # get "state" of pipeline
        # get failure type
        $step_script = $deployment_spec->{States}->{$step_name}->{scriptString};
        my $output_var = $deployment_spec->{States}->{$step_name}->{ResultPath};

        my $arguments_as_env_vars = $deployment_spec->{States}->{$step_name}->{variables};

        # what if the value has 'single quotes in it'?
        # Oh, we need to do that heredoc thing?
        # We gotta do something weird here for escaping purposes

        my @script_args = ();
        for my $arg (@{$arguments_as_env_vars}) {
            my $cloud_spec_json_arg;

            if($arg->{value} =~ /^\$\{([a-z\.A-Z_]+)\}?/){
                    # we need to look up in state following pattern of characters. periods. and underscores. no restriction on double periods so we will fail
                    my @lookup_keys = split(/\./, $1);

                    my $item = shift(@lookup_keys);
                    my $state_lookup_pointer;
                    
                    if($item eq 'workflow'){
                        $state_lookup_pointer = \%workflow_state;
                        for my $next_key (@lookup_keys) {
                            $state_lookup_pointer = $state_lookup_pointer->{$next_key};
                        }
                    }
                    $cloud_spec_json_arg = $state_lookup_pointer;
            } else {
                $cloud_spec_json_arg = $arg->{value};
            }
            # Injecting variables as env vars
            $ENV{$arg->{name}} = $cloud_spec_json_arg;
            push(@script_args, $arg->{name} . "=" . "\'${cloud_spec_json_arg}\'" . "\n");
        }
        
        

        # script name path on the host to invoke the script?
        my $script_file_uuid = $ug->create();
        my $script_filename = $ug->to_string( $script_file_uuid );
        $script_filename = "${workflow_temporary_directory_path}/${script_filename}";
        open(FH, '>', $script_filename) or die $!;
        print FH $step_script;
        close(FH);

        # output filename
        my $output_file_uuid = $ug->create();
        my $output_filename = $ug->to_string( $output_file_uuid );
        my $output_filename_path = "/${temporary_path_prefix}/${output_filename}";
        $ENV{TMPDIR} = "/${temporary_path_prefix}";
        $ENV{OUTPUT_FILE} = $output_filename_path;

        # my @p_args = ("help",);
        my $script_exit_code = system("$^X $script_filename");
        if($script_exit_code == 0) {
            # Check if anything was written
            my $home_dir = $ENV{HOME};
            # read file from "${home_dir}/tmp/${output_var}"
            my $file = "${workflow_temporary_directory_path}/${output_filename}";
            if(-e $file) {
                open my $info, $file or die "Could not open $file: $!";
                my %script_output = ();
                $workflow_state{$output_var} = \%script_output;
                while( my $line = <$info>)  {
                    my($key, $value) = split(/=/, $line, 2);
                    $workflow_state{$output_var}{$key} = $value;
                }
                close $info;
            } #else assume there was no output. we aren't dealing with host permission stuff here
        } else {
            say "system call failed with exit code: $script_exit_code";
            $overall_state_of_the_workflow = "FAILURE";
            # an error occurred during the script execution and we need to decide what to do next
        }

        if($overall_state_of_the_workflow eq 'NORMAL') {
            if(defined $deployment_spec->{States}->{$step_name}->{Next}) {
                say "found next value $deployment_spec->{States}->{$step_name}->{Next}";
                $step_name = $deployment_spec->{States}->{$step_name}->{Next};

            } elsif(defined $deployment_spec->{States}->{$step_name}->{End}) {
                say "last step completed. exiting now";
                last;
            }
        } elsif($overall_state_of_the_workflow eq 'FAILURE') {
            if(defined $deployment_spec->{States}->{$step_name}->{OnErrorContext}) {
                say "found next value $deployment_spec->{States}->{$step_name}->{OnErrorContext}";
                return "CHANGE", $deployment_spec->{States}->{$step_name}->{OnErrorContext};

            } else {
                say "No errorContext found steps found";
                return "CHANGE";
            }

        } else {
            say "unknown state tbh: $overall_state_of_the_workflow";
            last;
        }
        

    }

    # system clean up
    system("rm -rf $workflow_temporary_directory_path") == 0
        or die "system rm -rf failed: $?";
    return "END";
}

sub collapser {
    my ($contexts, $spec) = @_;

    my $collapsed_spec = $spec;

    for my $context (@$contexts) {
        $collapsed_spec = collapse_value($context, $collapsed_spec);
    }
    return $collapsed_spec;
}

# we look for the env as a key in hashes and will replace the entire hash value with the value of the env key
sub collapse_value {
    my ($context, $value) = @_;

    if (not ref $value) {
        # return looks_like_number($value) ? $value + 0 : $value; # what was this even used for?
        return $value;
    }

    return $value if JSON::PP::is_bool($value);

    if ('ARRAY' eq ref $value) {
        return [map { collapse_value($context, $_) } @$value];
    }

    if ('HASH' eq ref $value) {
        if(exists $value->{$context}) {
            my $actual = $value->{$context};
            return collapse_value($context, $actual);
        }
        return { map { $_ => collapse_value($context, $value->{$_}) } keys %$value };
    }

    confess "Something unexpected happened?";
}

my %payload = ();
my $json_file = '/tmp/big.json';
my $json_text = do { open my $fh, '<', $json_file; local $/; <$fh> };
my $service_manifest = decode_json $json_text;
# Is it okay to change the deployment context for each step? Probably but we should want to record it somewhere whats happening and _how_ we got to the deployment spec we're using

my @deployment_contexts = ("deploy");
my $overall_state_of_the_system = "";
# Need to be env var equivalents
### "deploy" will need to be removed. since itself is context
### We do this is everything is a-ok
my $deployment_spec = collapser(\@deployment_contexts, $service_manifest->{deployment_spec});

my @pipeline_variable_keys = keys %{$deployment_spec->{variables}};
for my $pipeline_variable_key (@pipeline_variable_keys) {
    my $val_key_type = ref $deployment_spec->{variables}->{$pipeline_variable_key};
    if($val_key_type eq '') {
        $payload{$pipeline_variable_key} = $deployment_spec->{variables}->{$pipeline_variable_key};
    } else {
        # if hash or array, then encode_json
        $payload{$pipeline_variable_key} = encode_json $deployment_spec->{variables}->{$pipeline_variable_key};
    }
}

# grab variables here?
$DB::single=1;
my $deployment_contexts = \@deployment_contexts;
while(1) {
    #decider
    my $deployment_spec = collapser($deployment_contexts, $service_manifest->{deployment_spec});

    my @pipeline_variable_keys = keys %{$deployment_spec->{variables}};
    for my $pipeline_variable_key (@pipeline_variable_keys) {
        my $val_key_type = ref $deployment_spec->{variables}->{$pipeline_variable_key};
        if($val_key_type eq '') {
            $payload{$pipeline_variable_key} = $deployment_spec->{variables}->{$pipeline_variable_key};
        } else {
            # if hash or array, then encode_json
            $payload{$pipeline_variable_key} = encode_json $deployment_spec->{variables}->{$pipeline_variable_key};
        }
    }

    if($overall_state_of_the_system eq '') {
        my ($new_overall_state_of_the_system, $new_next_deployment_contexts) = handle($service_manifest, \%payload, $deployment_spec);
        $overall_state_of_the_system = $new_overall_state_of_the_system if defined $new_overall_state_of_the_system;
        $deployment_contexts = $new_next_deployment_contexts if defined $new_next_deployment_contexts;
    } elsif($overall_state_of_the_system eq 'CHANGE') {
        say "one of the steps failed";
        my ($new_overall_state_of_the_system, $new_next_deployment_contexts) = handle($service_manifest, \%payload, $deployment_spec);
        $overall_state_of_the_system = $new_overall_state_of_the_system if defined $new_overall_state_of_the_system;
        $deployment_contexts = $new_next_deployment_contexts if defined $new_next_deployment_contexts;
        say "we should show you the logs";
        last;
    } elsif($overall_state_of_the_system eq 'END') {
        say "we done";
        last;
    } else {
        say "unknown state tbh: $overall_state_of_the_system";
        last;
    }
}



1;
