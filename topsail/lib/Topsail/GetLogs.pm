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

my $execution_arn = "arn:aws:states:us-east-1:124176715436:execution:ActivityWorkflowExecutor:b62d83dd-3f9a-4e09-88b0-10e64ef4e978";
my $worker_name;
my $start_timestamp;
my $end_timestamp;

while(not defined $activity_start) {
    my $res = $aws->stepfunctions(
        'get-execution-history' => {
            "execution-arn" => $execution_arn
        },
        timeout => 65, # https://docs.aws.amazon.com/step-functions/latest/dg/troubleshooting-activities.html
    );

    if ($res) {
        my $events = $res->{events};
        $activity_start = first(sub { $_->{type} eq 'ActivityStarted' }, @$events);
        # search for ActivityTimedOut or ActivitySucceeded with matching worker_id in the output

        if(defined $activity_start) {
            $worker_name = $match->{activityStartedEventDetails}->{workerName};
            $start_timestamp = $match->{timestamp};
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

my $all_logs;
while(1) {
    my $start_dt = DateTime::Format::ISO8601->parse_datetime($start_timestamp);
    my $start_epoch_milliseconds =  $start_dt->hires_epoch * 1000;
    my $five_mins_milliseconds = 60 * 5 * 1000;
    my $logs_res = $aws->logs(
        'filter-log-events' => {
            "log-group-name" => "TopsailLogGroup",
            "log-stream-names" => $worker_name,
            "start-time" => $start_epoch_milliseconds,
            "end-time" => $start_epoch_milliseconds + $five_mins_milliseconds
        },
        timeout => 65, # https://docs.aws.amazon.com/step-functions/latest/dg/troubleshooting-activities.html
    );

    if ($logs_res) {
        # say Dumper($res);
        my $events = $logs_res->{events};
        $DB::single=1;
        # eventually we want the end time too

    } else {
        warn $AWS::CLIWrapper::Error->{Code};
        warn $AWS::CLIWrapper::Error->{Message};
    }

}

check_if_succeeded_or_timed_out($events);



sub check_if_succeeded_or_timed_out {
    my ($events) = @_;
    my $match = first(sub { $_->{type} eq 'ActivityTimedOut' }, @$events);
    $match = first(sub { $_->{type} eq 'ActivitySucceeded' }, @$events) unless defined $match;

    return $match;
    
}

1;