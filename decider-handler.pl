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
    $execution_state //= {};

    # completed_steps should be a map instead of list?
    my $completed_steps = $execution_state->{completed_steps};
    # should we grab something like "contexts" here?
    # call something like collapser to get the "deployment spec"
    my $step_name;
    if( (not defined $completed_steps) || (scalar(@{$completed_steps}) == 0) ) {
        # use the "first step"
        $step_name = $deployment_spec->{StartAt};

        $all_input->{execution_state}->{step_type} = $deployment_spec->{States}->{$step_name}->{Type};
    } else {
        # get the step name that the previous step points to
        my $previous_step_name = $completed_steps->[-1];
        if(defined $deployment_spec->{States}->{$previous_step_name}->{Next}) {
            $step_name = $deployment_spec->{States}->{$previous_step_name}->{Next};

            $all_input->{execution_state}->{step_type} = $deployment_spec->{States}->{$step_name}->{Type};

        } elsif(defined $deployment_spec->{States}->{$step_name}->{End}) {
            $all_input->{execution_state}->{step_type} = "COMPLETE";
        }
    }

    return $all_input;

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
    # $all_input->{execution_state}->{step_type} = "TASK";

    # $all_input->{execution_state}->{step_type} = "MANUAL_APPROVAL";

    # $all_input->{execution_state}->{step_type} = "APPROVAL";
    # $all_input->{execution_state}->{step_type} = "SYNC";
    # $all_input->{execution_state}->{step_type} = "PARALLEL"; ???
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
1;
