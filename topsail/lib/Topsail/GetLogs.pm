#!/usr/bin/env perl

package Topsail::GetLogs;

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

use List::Util 'first'; 

say "getting logs";
use Data::Dumper;
my $aws = AWS::CLIWrapper->new(
    region => 'us-east-1',
);
use DateTime::Format::ISO8601;



my $datetime_str = '2023-12-24T17:29:09.162000';
my $dt = DateTime::Format::ISO8601->parse_datetime($datetime_str);
say $dt;
say DateTime::Format::ISO8601->format_datetime($dt);
my $epoch_milliseconds =  $dt->hires_epoch * 1000;
say $epoch_milliseconds;

say $epoch_milliseconds / 1000;
my $re_dt = DateTime->from_epoch(
    epoch     => $epoch_milliseconds / 1000
);
say $re_dt;


# search for ActivityTimedOut or ActivitySucceeded with matching worker_id in the output
# aws stepfunctions get-execution-history --execution-arn "${execution-id}" --output json | jq -r '.events[] | select(.type | contains("ActivityStarted")) | .activityStartedEventDetails.workerName'
# aws stepfunctions get-execution-history --execution-arn "${execution-id}" --output json | jq -r '.events[] | select(.type | contains("ActivityStarted")) | .timestamp'

# aws logs filter-log-events --log-group-name TopsailLogGroup --log-stream-names bob1 --start-time "${WORKER_START_TIME_EPOCH}" | jq
my $activity_start;

my $execution_arn = "arn:aws:states:us-east-1:428589721254:execution:ActivityWorkflowExecutor:6f4c8af8-d00c-4995-b2a3-517ae52e2c64";
my $worker_name;
my $start_timestamp;

my $step_function_execution_history_events;

while(not defined $activity_start) {
    my $res = $aws->stepfunctions(
        'get-execution-history' => {
            "execution-arn" => $execution_arn
        },
        timeout => 65, # https://docs.aws.amazon.com/step-functions/latest/dg/troubleshooting-activities.html
    );

    if ($res) {
        $step_function_execution_history_events = $res->{events};
        $activity_start = first(sub { $_->{type} eq 'ActivityStarted' }, @$step_function_execution_history_events);
        # search for ActivityTimedOut or ActivitySucceeded with matching worker_id in the output

        if(defined $activity_start) {
            $worker_name = $activity_start->{activityStartedEventDetails}->{workerName};
            $start_timestamp = $activity_start->{timestamp};
            # eventually we want the end time too
            last;
        } else {
            sleep 5;
        }
    } else {
        warn $AWS::CLIWrapper::Error->{Code};
        warn $AWS::CLIWrapper::Error->{Message};
    }
}

my $start_dt = DateTime::Format::ISO8601->parse_datetime($start_timestamp);
my $start_epoch_milliseconds =  $start_dt->hires_epoch * 1000;

my $previous_start_epoch_milliseconds = $start_epoch_milliseconds;
my $one_min_seconds = 60 * 1;
my $one_min_milliseconds = 60 * 1 * 1000;
my $epoch_milliseconds_increment = $one_min_milliseconds;
my $next_end_epoch_milliseconds = $previous_start_epoch_milliseconds + $epoch_milliseconds_increment;


my $activity_end;
my $end_timestamp;
my $completion_type;

# my @all_logs = ();
my @new_logs = ();
while(1) {

    my $step_function_execution_history_res = $aws->stepfunctions(
        'get-execution-history' => {
            "execution-arn" => $execution_arn
        },
        timeout => 65, # https://docs.aws.amazon.com/step-functions/latest/dg/troubleshooting-activities.html
    );

    if ($step_function_execution_history_res) {
        $step_function_execution_history_events = $step_function_execution_history_res->{events};
        # search for ActivityTimedOut or ActivitySucceeded with matching worker_id in the output
    } else {
        warn $AWS::CLIWrapper::Error->{Code};
        warn $AWS::CLIWrapper::Error->{Message};
    }
    
    $activity_end = first(sub { $_->{type} eq 'ActivityTimedOut' }, @$step_function_execution_history_events);
    if(defined $activity_end) {
        $completion_type = 'ACTIVITY_TIMED_OUT';
        last;
    }
    # do a switch statement or something
    $activity_end = first(sub { $_->{type} eq 'ActivitySucceeded' }, @$step_function_execution_history_events);
    if(defined $activity_end) {
        $completion_type = 'ACTIVITY_SUCCEEDED';
        last;
    }

    my $logs_res = $aws->logs(
        'filter-log-events' => {
            "log-group-name" => "TopsailLogGroup",
            "log-stream-names" => $worker_name,
            "start-time" => $previous_start_epoch_milliseconds,
            "end-time" => $next_end_epoch_milliseconds,
            "filter-pattern" => '%^arn:aws:states:us-east-1:428589721254:execution:ActivityWorkflowExecutor:6f4c8af8-d00c-4995-b2a3-517ae52e2c64%'
        },
        timeout => 65, # https://docs.aws.amazon.com/step-functions/latest/dg/troubleshooting-activities.html
    );

    if ($logs_res) {
        # say Dumper($res);
        my $events = $logs_res->{events};
        # @all_logs = (@all_logs, @{$events});
        say Dumper(@{$events});

        $previous_start_epoch_milliseconds = $next_end_epoch_milliseconds;
        $next_end_epoch_milliseconds = $next_end_epoch_milliseconds + $epoch_milliseconds_increment;


        # sleep for the increment time
        sleep $one_min_seconds; # this isn't precise so we need to think of something else


    } else {
        warn $AWS::CLIWrapper::Error->{Code};
        warn $AWS::CLIWrapper::Error->{Message};
    }

}

$end_timestamp = $activity_end->{timestamp};
my $end_dt = DateTime::Format::ISO8601->parse_datetime($end_timestamp);
my $end_epoch_milliseconds =  $end_dt->hires_epoch * 1000;

my $log_filter_regex = "%^$execution_arn%";

my $remaining_logs_res = $aws->logs(
        'filter-log-events' => {
            "log-group-name" => "TopsailLogGroup",
            "log-stream-names" => $worker_name,
            "start-time" => $previous_start_epoch_milliseconds,
            "end-time" => $end_epoch_milliseconds,
            "filter-pattern" => $log_filter_regex
        },
        timeout => 65, # https://docs.aws.amazon.com/step-functions/latest/dg/troubleshooting-activities.html
    );

    if ($remaining_logs_res) {
        # say Dumper($res);
        my $events = $remaining_logs_res->{events};
        # @all_logs = (@all_logs, @{$events});
        say Dumper(@{$events});
        $DB::single=1;
        # eventually we want the end time too

    } else {
        warn $AWS::CLIWrapper::Error->{Code};
        warn $AWS::CLIWrapper::Error->{Message};
    }

# say Dumper(@all_logs);

1;