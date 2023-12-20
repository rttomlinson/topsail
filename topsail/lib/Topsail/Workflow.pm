#!/usr/bin/env perl

package Topsail::Workflow;

$| = 1;
use v5.030;
use warnings;
use strictures 2;
no warnings 'uninitialized';
use Errno;
use Carp 'confess';
use JSON::PP;
use AWS::CLIWrapper;
use JSON::PP;
use POSIX ":sys_wait_h";
use Getopt::Long;
use Data::UUID;
Getopt::Long::Configure("pass_through");

# init logger
use Log::Log4perl qw(get_logger);
Log::Log4perl->init("log4perl.cfg");
my $logger = get_logger("Foo");
$logger->debug("Hello from Workflow.pm");

use Exporter 'import';
our @EXPORT_OK = qw(execute_workflow);

sub execute_workflow {
    my %params = @_;
    my ($contexts, $original_deployment_spec) = @params{qw(starting_contexts original_deployment_spec)};
    $contexts //= ();
    my %payload = ();
    my $deployment_contexts = $contexts;
    my $overall_state_of_the_system = '';

    my @steps_performed = ();
    say "starting workflow execution";
    while(1) {
        #decider
        my $deployment_spec = collapser($deployment_contexts, $original_deployment_spec);

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
        say "executing deployment spec with following contexts: @{$deployment_contexts}";
        # unique execution flow here
        my ($new_overall_state_of_the_system, $new_next_deployment_contexts) = handle(\%payload, $deployment_spec);

        $overall_state_of_the_system = $new_overall_state_of_the_system if defined $new_overall_state_of_the_system;

        if($overall_state_of_the_system eq 'CHANGE') {
            confess "System detected a change, but no new workflow was provided. Aborting the workflow" unless defined $new_next_deployment_contexts;
            $deployment_contexts = $new_next_deployment_contexts;
            say "one of the steps failed";
            say "we should show you the logs";
        } elsif($overall_state_of_the_system eq 'END') {
            say "we done";
            last;
        } else {
            say "unknown state tbh: $overall_state_of_the_system";
            last;
        }
    }
    say "ending workflow execution";
    # process the workflow spec

    my $task_output;

    $task_output //= '{}';

    # TODO: Implement this
    return \@steps_performed;

}

sub handle {

    # Note: step name is confusing because there is mast step name and deployment step name
    my ($pipeline_variables, $deployment_spec) = @_;

    my $ug    = Data::UUID->new;
    my $uuid = $ug->create();
    my $dir_path = $ug->to_string( $uuid );
    my $execution_unique_id = $dir_path;
    
    my $HOST_TEMPDIR = $ENV{HOST_TEMPDIR}; # can we guarentee this will always be the absolute path? possible /root/tmp or /tmp
    $HOST_TEMPDIR //= "$ENV{HOME}/tmp"; # not sure this is safe


    my $temporary_path_prefix = "$HOST_TEMPDIR/${dir_path}";
    my $workflow_temporary_directory_path = $temporary_path_prefix;

    # SEE TMPDIR env var set below
    $ENV{HOST_TEMPORARY_DIRECTORY} = $workflow_temporary_directory_path;

    system("mkdir -p $workflow_temporary_directory_path") == 0
        or die "system mkdir failed: $?";
    # say "created tmp dir for script invocation at $workflow_temporary_directory_path";
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

    my $step_name = $deployment_spec->{StartAt};
    ### List of executed steps
    ### Log location
    ### Abort button
    ### All the "scaffolding"
    ### Get collapsed pipeline based on current contexts
    
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
        
        # TODO: Create a unique namespace for each step within the execution tmpdir
        # so at this point # my $workflow_temporary_directory_path is the path for _all_ the "exection" of a collection of scripts
        my $unique_tmpdir_for_single_step; # i.e. one script execution
        my $ug    = Data::UUID->new;
        my $uuid = $ug->create();
        my $dir_path = $ug->to_string( $uuid );
        $unique_tmpdir_for_single_step = "$workflow_temporary_directory_path/${dir_path}";

        # Create the tmp dir within the fs
        system("mkdir -p $unique_tmpdir_for_single_step") == 0
            or die "system mkdir failed: $?";
        # say "created tmp dir for script invocation at $unique_tmpdir_for_single_step";
        # Create logs file
        # system("mkdir -p $unique_tmpdir_for_single_step/logs") == 0
        #     or die "system mkdir failed: $?";

        # script name path on the host to invoke the script?
        my $script_file_uuid = $ug->create();
        my $script_filename = $ug->to_string( $script_file_uuid );
        $script_filename = "${unique_tmpdir_for_single_step}/${script_filename}";
        open(FH, '>', $script_filename) or die $!;
        print FH $step_script;
        close(FH);
        $ENV{TMPDIR} = $unique_tmpdir_for_single_step;

        # $ENV{OUTPUT_FILE} = $output_filename_path;

        # my @p_args = ("help",);
        # How to handle specific logs to this. Each time
        # say "execution unique id: $execution_unique_id";
        # say "script unique id: $dir_path";
        my $script_unique_id = $dir_path;

        say "starting execution of $step_name with id $script_unique_id";

        my $script_exit_code;
        if(defined $ENV{LOG_SCRIPTS_TO_FILE}) {
            $script_exit_code = system("$^X $script_filename >$unique_tmpdir_for_single_step/logs.txt 2>&1");
        } else {
            
            # $script_exit_code = system("$^X $script_filename");
            use IPC::Run qw(run);
            my ( $out, $err );
            my @cmd = (
                "$^X",
                
                "$script_filename"
                # "perl",
                # '-le', 
                # 'STDOUT->autoflush(1); for (qw( abc def ghi )) { print; sleep 1; }'
            );

            run \@cmd, '>', sub { say "$script_unique_id: $_[0]" };

            say "finishing execution of $step_name with id $script_unique_id";
            # how to catch errors?
            # $script_exit_code = system("$^X $script_filename");
            $script_exit_code = 0;
        } 

        if($script_exit_code == 0) {

            # list files at path
            opendir(DIR, $unique_tmpdir_for_single_step) or die "can't opendir $unique_tmpdir_for_single_step: $!";
            my $file;
            while (defined (my $file = readdir DIR)) {

                # split on last period to get file name and file extension
                my ($file_name, $file_extension) = split /\.([^\.]+)$/, $file;

                if($file_extension eq 'type') { # we aren't going to read it. just assume 'envvar' type
                    if(-e "$unique_tmpdir_for_single_step/$file_name") { # instead, check if anything is in the directory. look for file to thats reader the type of file
                        open my $info, "$unique_tmpdir_for_single_step/$file_name" or die "Could not open $unique_tmpdir_for_single_step/$file_name: $!";
                        my %script_output = ();
                        $workflow_state{$output_var} = \%script_output;
                        while( my $line = <$info>)  {
                            my($key, $value) = split(/=/, $line, 2);
                            $workflow_state{$output_var}{$key} = $value;
                        }
                        close $info;
                    } #else assume there was no output. we aren't dealing with host permission stuff here
                }
                # do something with "$dirname/$file"
            }
            closedir(DIR);
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
                say "found next context(s) values: " . join(" ", @{$deployment_spec->{States}->{$step_name}->{OnErrorContext}});
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
    # delete the entire directory
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

1;