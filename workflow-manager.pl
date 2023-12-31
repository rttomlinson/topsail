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
use AWS::CLIWrapper;
use POSIX;

# Logger helper module for aws lambda request
use Topsail::CustomLogger qw(get_logger);
my $log = get_logger();

sub handle {

    # Note: step name is confusing because there is mast step name and deployment step name
    my ($payload, $context) = @_;
    # Create the step function
    my $aws_region = "us-east-1";
    my $aws = AWS::CLIWrapper->new(
        region => $aws_region,
        croak_on_error => 1,
    );
    
    my $json_file = '/tmp/service_manifest.json';
    my $json_text = do { open my $fh, '<', $json_file; local $/; <$fh> };
    my $perl_data = decode_json $json_text;

    # $DB::single=1;
    # create the step function (via cloud formation)
    my $stack_name = "plsplsplswork";
    my $stack_id = do {
        my $res = $aws->cloudformation('create-stack', {
        'stack-name' => $stack_name,
        'template-body' => encode_json $perl_data->{deployment_spec}->{cloud_formation},
        'capabilities' => ["CAPABILITY_AUTO_EXPAND", "CAPABILITY_NAMED_IAM"],
        });
        $log->info("creating-stack");
        $res->{StackId};
    };   

    # Wait until state COMPLETE
    # CREATE_COMPLETE

    # or ROLLBACK COMPLETE

    # wait for the step function to be created (cloud formation)
    my $stack_status;
    while($stack_status ne 'CREATE_COMPLETE'){
        if($stack_status eq 'ROLLBACK_COMPLETE'){
            $log->info("Status reached ROLLBACK_COMPLETE. Deleting stack...");
            $aws->cloudformation('delete-stack', {
                'stack-name' => $stack_name,
            });
            $log->logconfess("stack failed to create");
        }
        $stack_status = do {
            my $res = $aws->cloudformation('describe-stacks', {
                'stack-name' => $stack_name,
            });
            $log->info("waiting for stack to complete");
            $res->{Stacks}->[0]->{StackStatus};
        };
        sleep(3);
    }
    # Get Step Function ARN Output from stack
    my $res = $aws->cloudformation('describe-stacks', {
        'stack-name' => $stack_name,
    });
    $log->info("grabbing-output-stack");
    my $outputs = $res->{Stacks}->[0]->{Outputs};
    my ($state_function_output) = grep {$_->{OutputKey} eq 'StepFunctionArn'} @{$outputs};
    
    my $state_function_arn = $state_function_output->{OutputValue};
    # Execute the step function
    my $execution_name = "hello-name";
    my $input = {"cloud_spec_json" => $perl_data->{state}->{cloud_spec_json} };
    my $execution_res = $aws->stepfunctions('start-execution', {
        'state-machine-arn' => $state_function_arn,
        "input" => encode_json($input),
        "trace-header" => "hello",
        "name" => $execution_name,
    });
    my $execution_arn = $execution_res->{executionArn};
    my $console_url = "https://us-east-1.console.aws.amazon.com/states/home?region=us-east-1#/v2/executions/details/${execution_arn}";
    $log->info($console_url);
    # output where to get details about stack
    # my $execution_history = $aws->stepfunctions('get-execution-history', { 'execution-arn' => $execution_res->{executionArn} });
    # wait for execution completion
    my $execution_details = $aws->stepfunctions('describe-execution', { 'execution-arn' => $execution_res->{executionArn} });
    my $execution_status = $execution_details->{status};
    # RUNNING | SUCCEEDED | FAILED | TIMED_OUT | ABORTED
    while($execution_status eq 'RUNNING'){
        $execution_details = $aws->stepfunctions('describe-execution', { 'execution-arn' => $execution_res->{executionArn} });
        $execution_status = $execution_details->{status};
        # $execution_history = $aws->stepfunctions('get-execution-history', { 'execution-arn' => $execution_res->{executionArn} });
        last if $execution_status eq 'SUCCEEDED';
        if($execution_status =~ /(FAILED|TIMED_OUT|ABORTED)/) {
            $log->info("execution has unexpected status: $execution_status. Aborting");
            last;
        } 
        $log->info("waiting 10 seconds before checking execution status...");
        sleep(10);
    }

    # Grab information about the execution of the step function
    # $execution_history = $aws->stepfunctions('get-execution-history', { 'execution-arn' => $execution_res->{executionArn} });
    $execution_details = $aws->stepfunctions('describe-execution', { 'execution-arn' => $execution_res->{executionArn} });
    my $trace_header = $execution_details->{traceHeader};
    # extract traceHeaderId
    # Using crude matching pattern since expected pattern is not known at this time
    my $index = index ($trace_header, '=');
    $trace_header = substr($trace_header, $index+1);
    $index = index ($trace_header, ';');
    $trace_header = substr($trace_header, 0, $index);
    my $trace_header_id = $trace_header;
    # 'Root=1-65411689-72a13f748cbdfaea6aeef640;Sampled=1'
    $log->info("https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#xray:traces/${trace_header_id}");
    # type => LambdaFunctionScheduled

    # Reorder the subsegments to match the actual execution order
    # What happens if it gets replayed? We can't handle that yet.
    # I.E. Can't reuse a step. That's bad...

    ##############################################################
    ## This section need to happen independently while the stack/step function exists. and in particular _this_ execution of it.
    # Use request_id to parse cloudwatch logs
    ###
    # We need some kind of interface for getting the logs

    my $workflow_name = "MyCustomWorkflowExecutor";
    my $segment_name_matcher = "\"name\":\"${workflow_name}\"";
    my $segments = $aws->xray('batch-get-traces', { 'trace-ids' => [$trace_header_id] })->{Traces}->[0]->{Segments};
    my ($step_function_segment) = grep {$_->{Document} =~ /$segment_name_matcher/} @{$segments};
    my $segment_document_payload = decode_json $step_function_segment->{Document};

    # by default newest to oldest
    my @subsegments = @{$segment_document_payload->{subsegments}};
    my @sorted_subsegments = sort { $a->{start_time} + 0 <=> $b->{start_time} + 0 } @subsegments;
    # describe lambda?
    # arn:aws:lambda:us-east-1:860426437628:function:mast-lambda
    my %request_ids;
    for my $subsegment_data (@sorted_subsegments){
        $request_ids{$subsegment_data->{subsegments}->[0]->{aws}->{request_id}} = 1;
    }
    my @request_ids = keys %request_ids;
    
    # I think start-query will also make this assumption since it expects seconds.
    my $first_subsegment_start_time_in_seconds_utc = $sorted_subsegments[0]->{start_time}+0;
    my $last_sebsegment_end_time_in_seconds_utc = $sorted_subsegments[-1]->{end_time}+0;

    my $start_time_utc = floor($first_subsegment_start_time_in_seconds_utc);
    my $end_time_utc   = ceil($last_sebsegment_end_time_in_seconds_utc);

    # my $log_query_filter_start = 'fields @log, @timestamp, @message | filter ';
    # my $log_query_filter_end = ' | sort @timestamp, @message desc';
    my @filters;
    my $or_joiner = " or ";

    for my $request_id (@request_ids) {
        my $request_id_filter_match_template = "\@requestId = \"$request_id\"";
        my $request_id_in_message = "\@message like \"$request_id\"";
        push(@filters, ($request_id_filter_match_template, $request_id_in_message));
    }
    my $trace_substr = substr $trace_header_id, 2;
    my $trace_id_filter_in_message = "\@message like \"$trace_header_id\" or \@message like \"$trace_substr\"";
    push(@filters, $trace_id_filter_in_message);
    my $complete_filter = join $or_joiner, @filters;

    my $query_string = "fields \@log, \@timestamp, \@message | filter $complete_filter | sort \@timestamp, \@message desc";
    # my $query_string = 'fields @log, @timestamp, @message | filter @requestId = "3d23d996-681a-44a9-8bd0-3e497d9532e5" or @requestId = "b63d64bc-8159-4f44-ab7e-6cf606c5122b" or @requestId = "2e69870f-929b-42c3-8d20-cd3ed0db9d81" or @message like "1-6542afac-abd7a333a0cfa58d2636a909" or @message like "6542afac-abd7a333a0cfa58d2636a909" or @message like "b63d64bc-8159-4f44-ab7e-6cf606c5122b" | sort @timestamp, @message desc';
    $log->info("Query string: $query_string");
    $log->info("Start time (UTC seconds): $start_time_utc");
    $log->info("End time (UTC seconds): $end_time_utc");
    my %logs_query = ("query_string" => $query_string, "start_time" => $start_time_utc, "end_time" => $end_time_utc);
    my $log_group_name = "/aws/lambda/mast-lambda";
    my $query_res = $aws->logs('start-query', { 'log-group-name' => $log_group_name, 'query-string' => $query_string, 'start-time' => $start_time_utc, 'end-time' => $end_time_utc });
    my $query_id = $query_res->{queryId};
        # use these to get log streams then parse it for relevant logs
    my $query_results;
    # $aws->logs('get-log-record', { 'log-record-pointer' => "CmcKKAokODYwNDI2NDM3NjI4Oi9hd3MvbGFtYmRhL21hc3QtbGFtYmRhEAESNxoYAgZJy1GnAAAAATnreecABlQUzmAAAAByIAEo87HUuLgxMPr71bi4MTgUQNjuAUiNxQFQ+WMYACABEBIYAQ==" });
    while($query_results->{status} ne 'Complete'){
        $query_results = $aws->logs('get-query-results', { 'query-id' => $query_id });
        if($query_results->{status} eq 'Running' or $query_results->{status} eq 'Scheduled'){
            $log->info("waiting for query results...");
            sleep(5);
        } elsif($query_results->{status} eq 'Complete') {
            last;
        } else {
            my $query_status = $query_results->{status};
            $log->info("we dont know how to handle $query_status");
            last;
        }
    }
    say Dumper($query_results);
    ######################################

    # Possible values are Cancelled , Complete , Failed , Running , Scheduled , Timeout , and Unknown .
    # Output logging details
    $DB::single=1;

    # basically the idea here would be to keep scanning for new logs until we're told to clean everything up
    # Clean up the step function
    # Determine if should clean-up immediately?
    my $delete_stack_status;
    my $delete_res = do {
        $aws->cloudformation('delete-stack', {
            'stack-name' => $stack_name,
        });
    };

    while(1){
        $delete_stack_status = eval {
            my $res = $aws->cloudformation('describe-stacks', {
                'stack-name' => $stack_name,
            });
            $res->{Stacks}->[0]->{StackStatus};
        };
        if($@) {
            my $error_message_matcher = "Stack with id ${stack_name} does not exist";
            if($@ =~ /$error_message_matcher/){
                $log->info("stack was deleted");
                last;
            } else {
                $log->logconfess($@);
            }
        }

        if($delete_stack_status eq 'DELETE_IN_PROGRESS'){
            $log->info("deleting in progress. waiting 3 seconds...");
            sleep(3);
        }
        
    }
    $log->info("goodbye");
    return;


    # my $all_input = $payload->{input};
    # return $payload;
    # my $deployment_spec = $all_input->{deployment_spec};
    # my $state = $all_input->{state};
    # my $execution_state = $all_input->{execution_state};

    # my $completed_steps = $execution_state->{completed_steps};
    # my $step_name;
    # if( (not defined $completed_steps) || (scalar(@{$completed_steps}) == 0) ) {
    #     # use the "first step"
    #     $step_name = $deployment_spec->{StartAt}
    # } else {
    #     # get the step name that the previous step points to
    #     my $previous_step_name = $completed_steps->[-1];
    #     $step_name = $deployment_spec->{States}->{$previous_step_name}->{Next};
    # }
    # # "Parameters": {
    # #                 "step_name": "contexts_validate_service_spec",
    # #                 "service_spec_json.$": "$.service_spec_json",
    # #                 "context": [
    # #                     "prestaging",
    # #                     "standby"
    # #                 ],
    # #                 "output_file": "/tmp/deployment.json"
    # #             },
    # # get and extract parameters
    # my $step_parameters = $deployment_spec->{States}->{$step_name}->{Parameters};
    # my @mast_args = keys %{$step_parameters};
    # my $mast_step_name = $step_parameters->{step_name};

    # confess "step_name not provided. exiting. also needs to be caught in the spec" unless defined $mast_step_name;
    # my $script_location = "/opt/bin/$mast_step_name"; # don't know how to not hardcode this

    # my @p_args = ($script_location,);
    # @mast_args = grep(!/step_name/, @mast_args); # need to hardcode this

    # for(@mast_args) {
        
    #     my $hyphens_arg = $_;
    #     my $next_val = $step_parameters->{$_};

    #     # check if arg has .$ suffix which means we need to pull from arguments and drop the .$
    #     # we want it to start with any alpha numberic and it can contain underscores and hyphens
    #     # it can not end with a hyphen or an underscore
    #     if($hyphens_arg =~ /^[a-zA-Z0-9]+[a-zA-Z0-9_-]*[a-zA-Z0-9]+\.\$$/){
    #         # the value will be prefixed with $. which indicates where to grab the arguments from in the state key
    #         if($next_val !~ /^(\$\.)[a-zA-Z0-9]+[\.a-zA-Z0-9_-]*[a-zA-Z0-9]+$/){
    #             confess "keys with .\$ suffix are expected to have values with \$. prefix. $next_val was provided as the value for the $hyphens_arg argument";
    #         }
    #         # resolve the value from the state
    #         # drop the $.
    #         my $data_path_in_state = substr($next_val, 2);
    #         my @x = split(/\./, $data_path_in_state); # ("a", "c")
    #         my $current_value = $state;
    #         for my $k (@x){
    #             $current_value = $current_value->{$k};
    #         }
    #         confess "value was not found for $data_path_in_state" unless defined $current_value;
    #         $next_val = $current_value;
    #         # drop the .$
    #         $hyphens_arg = substr($hyphens_arg, 0, -2);
    #     }
    #     $hyphens_arg=~s/_/-/g;
    #     $hyphens_arg = "--${hyphens_arg}";
    #     # if a val is an array, then split the array into individual arguments
    #     if (ref $next_val eq 'ARRAY'){
    #         for my $val (@{$next_val}) {
    #             my @arg_pair = ($hyphens_arg, $val);
    #             push(@p_args, @arg_pair);
    #         }
    #     } else {
    #         my @arg_pair = ($hyphens_arg, $next_val);
    #         push(@p_args, @arg_pair);
    #     }
    # }
    # # TODO: capture output instead of exiting program on failure
    # system("perl", @p_args) == 0
    #     or die "system perl @p_args failed: $?";

    # # $deployment_spec->{States}->{$step_name}->{Parameters}->{output_file}
    # # This is a weird implementation of our output management
    # # basically mast only outputs IF output file is found. Not sure if there's a way
    # # we could change it out to stdout, but then we'd likely need to buffer and parse
    # # or stream the response or something that I don't completely understand
    # # it seems reasonable to just read from a file since we have access to it
    # if(defined $deployment_spec->{States}->{$step_name}->{Parameters}->{output_file}) {

    
    #     # if output file exists, read from output file and populate the return payload
    #     my %step_output;
    #     my $file = $deployment_spec->{States}->{$step_name}->{Parameters}->{output_file};

    #     open my $info, $file or die "Could not open $file: $!";
    #     while( my $line = <$info>)  {
    #         chomp $line; 
    #         my @spl = split("=", $line);
    #         my $key = $spl[0];
    #         my $value = $spl[1];
    #         $step_output{$key} = $value;
    #     }
    #     close $info;
    #     my $step_result_path = $deployment_spec->{States}->{$step_name}->{ResultPath};
    #     $state->{$step_result_path} = \%step_output;
    # }
    # # make updates to the input that will be passed
    # # you cannot make changes to the deployment_spec by definition
    # push(@{$completed_steps}, $step_name);
    # $all_input->{execution_state}->{completed_steps} = $completed_steps;

    # if(defined $deployment_spec->{States}->{$step_name}->{Next}){
    #     $all_input->{execution_state}->{status} = "EXECUTING";
    # } elsif(defined $deployment_spec->{States}->{$step_name}->{End}) {
    #     $all_input->{execution_state}->{status} = "DONE";
    # } else {
    #     confess "Workflow step validation failed. This needs to be caught in a spec valiation step and not here";
    # }
    # return $all_input;
}

my %payload = ("hello" => "world");

handle(\%payload);


1;
