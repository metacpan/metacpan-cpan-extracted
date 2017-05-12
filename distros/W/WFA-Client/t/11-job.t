#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::More;

use HTTP::Response;
use WFA::Client;
use WFA::Job;

my $wfa_client = WFA::Client->new(
    server   => 'server',
    username => 'username',
    password => 'password',
);

my $wfa_response = {
    job => {
        'atom:link' => {
            'command-execution-arguments' => { href => 'https://isglivewfa1/rest/workflows/executions/25185' },
            add                           => { href => 'https://isglivewfa1/rest/workflows/26140bc4-4e99-4783-ba3d-8fd27f0c185d/jobs' },
            cancel                        => { href => 'https://isglivewfa1/rest/workflows/26140bc4-4e99-4783-ba3d-8fd27f0c185d/jobs/25185/cancel' },
            out                           => { href => 'https://isglivewfa1/rest/workflows/26140bc4-4e99-4783-ba3d-8fd27f0c185d/jobs/25185/plan/out' },
            reservation                   => { href => 'https://isglivewfa1/rest/workflows/26140bc4-4e99-4783-ba3d-8fd27f0c185d/jobs/25185/reservation' },
            resume                        => { href => 'https://isglivewfa1/rest/workflows/26140bc4-4e99-4783-ba3d-8fd27f0c185d/jobs/25185/resume' },
            self                          => { href => 'https://isglivewfa1/rest/workflows/26140bc4-4e99-4783-ba3d-8fd27f0c185d/jobs/25185' }
        },
        jobId => '25185',
        'xmlns:atom' => 'http://www.w3.org/2005/Atom',
        workflow => {
            name => 'Test - Noop'
        },
        jobStatus => {
            jobStatus => 'COMPLETED',
            'workflow-execution-progress' => {
                'current-command-index' => '1',
                'current-command' => 'Send email',
                'commands-number' => '1'
            },
            returnParameters => {},
            phase => 'EXECUTION',
            userInputValues => {
                'userInputEntry' => [
                    {
                        key => '$Recipient',
                        value => 'test@test.com',
                    },
                    {
                        key => '$Message',
                        value => '',
                    },
                ],
            },
            'scheduleType' => 'Immediate',
            'plannedExecutionTime' => 'Jan 30, 2015 3:18:20 PM',
            'startTime' => 'Jan 30, 2015 3:18:23 PM',
            'endTime' => 'Jan 30, 2015 3:18:27 PM',
            'jobType' => 'Workflow Execution - Test - Noop'
        },
    },
};

my $job = WFA::Job->new(
    client   => $wfa_client,
    response => $wfa_response,
);

subtest metadata => sub {
    is($job->id(), $wfa_response->{job}->{jobId});
    is($job->start_time(), $wfa_response->{job}->{jobStatus}->{startTime});
    is($job->end_time(), $wfa_response->{job}->{jobStatus}->{endTime});
    is($job->status(), $wfa_response->{job}->{jobStatus}->{jobStatus});

    isnt($job->running(), 1);
    is($job->success(), 1);

    is($job->workflow()->name(), $wfa_response->{job}->{workflow}->{name});

    is_deeply(
        { $job->parameters() },
        {
            '$Recipient' => 'test@test.com',
            '$Message' => '',
        },
    );

    is($job->url_for_action('self'), $wfa_response->{job}->{'atom:link'}->{self}->{href});
};

done_testing();
