#!/usr/bin/env perl
use v5.030;
use strictures 2;
use warnings;
no warnings 'uninitialized';

#suffering from buffering
$|=1;

use Carp;
use JSON::PP;
use Data::Dumper;
# use AWS::CLIWrapper;
use POSIX;

# Logger helper module for aws lambda request
# use Topsail::CustomLogger qw(get_logger);
# my $log = get_logger();

sub handle {

    # Note: step name is confusing because there is mast step name and deployment step name
    my ($lambda_payload, $lambda_context) = @_;
    # Create the step function
    my $aws_region = "us-east-1";
    # my $aws = AWS::CLIWrapper->new(
    #     region => $aws_region,
    #     croak_on_error => 1,
    # );
    my $HOME = $ENV{HOME};
    system("mkdir -p ${HOME}/tmp") == 0
        or die "system mkdir failed: $?";
    
    my $json_file = '/tmp/big.json';
    my $json_text = do { open my $fh, '<', $json_file; local $/; <$fh> };
    my $perl_data = decode_json $json_text;

    say "hello world";
    # say Dumper($perl_data);
    ####
    # Initializing the pipeline
    ###
    my %workflow_state = ();
    ### "deploy" will need to be removed. since itself is context
    my $step_name = $perl_data->{deployment_spec}->{deploy}->{StartAt};
    ### List of executed steps
    ### Log location
    ### Abort button
    ### All the "scaffolding"
    ### Get collapsed pipeline based on current contexts
    # say $first_step;
    my $cloud_spec_json = $perl_data->{state}->{cloud_spec_json};
    my $deployment_spec = $perl_data->{deployment_spec};
    my $context = '["prestaging", "active"]';
    $workflow_state{context} = $context;
    $workflow_state{cloud_spec_json} = $cloud_spec_json;
    my $step_script;

    while(1){
        $step_script = $perl_data->{deployment_spec}->{deploy}->{States}->{$step_name}->{scriptString};
        my $output_var = $perl_data->{deployment_spec}->{deploy}->{States}->{$step_name}->{outputVars};

        my $arguments_as_env_vars = $perl_data->{deployment_spec}->{deploy}->{States}->{$step_name}->{variables};

        # what if the value has 'single quotes in it'?
        # Oh, we need to do that heredoc thing?

        # We gotta do something weird here for escaping purposes

        # "outputVars=\'$output_var\'\n"
        # "cloud_spec_json=\'${cloud_spec_json}\'\n"
        # "environment=\'prestaging\'\n"
        my @script_args = ();
        for my $arg (@{$arguments_as_env_vars}) {
            my $cloud_spec_json_arg;

            if($arg->{value} =~ /^\$\{([a-z\.A-Z_]+)\}?/){
                    say $1; # we need to look up in state following pattern of characters. periods. and underscores. no restriction on double periods so we will fail
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
            $ENV{$arg->{name}} = $cloud_spec_json_arg;
            push(@script_args, $arg->{name} . "=" . "\'${cloud_spec_json_arg}\'" . "\n");
        }
        push(@script_args, "outputVars" . "=" . $output_var . "\n");
        
        my @p_args = ("help",);
        my $filename = '/tmp/hello.pl';
        open(FH, '>', $filename) or die $!;
        print FH $step_script;
        close(FH);

        $ENV{TMPDIR} = "/tmp";
        $ENV{OUTPUT_FILE} = "/tmp/${output_var}.json";

        # print "Writing to file successfully!\n";
        system("$^X $filename") == 0
            or die "system perl @p_args failed: $?";
        # system("docker", @p_args) == 0
        #     or die "system perl @p_args failed: $?";
        my $home_dir = $ENV{HOME};
        # read file from "${home_dir}/tmp/${output_var}"
        my $file = "${home_dir}/tmp/${output_var}.json";
        open my $info, $file or die "Could not open $file: $!";
        my %script_output = ();
        $workflow_state{$output_var} = \%script_output;
        while( my $line = <$info>)  {
            my($key, $value) = split(/=/, $line, 2);
            $workflow_state{$output_var}{$key} = $value;
        }
        # say Dumper(%workflow_state);
        
        close $info;
        if(defined $deployment_spec->{deploy}->{States}->{$step_name}->{Next}) {
            say "found next value $deployment_spec->{States}->{$step_name}->{Next}";
            $step_name = $deployment_spec->{deploy}->{States}->{$step_name}->{Next};

        } elsif(defined $deployment_spec->{deploy}->{States}->{$step_name}->{End}) {
            say "last step completed. exiting now";
            last;
        }

    }

    system("rm -rf ${HOME}/tmp") == 0
        or die "system rm -rf failed: $?";

}

my %payload = ("hello" => "world");

handle(\%payload);


1;
