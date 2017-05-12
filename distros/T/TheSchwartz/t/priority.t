# -*-perl-*-

use strict;
use warnings;

require 't/lib/db-common.pl';

use TheSchwartz;
use Test::More tests => ( ( 31 * 3 ) + ( 16 * 3 ) + ( 12 * 3 ) );

our $record_expected;
our $testnum = 0;
our $floor   = 3;

$TheSchwartz::FIND_JOB_BATCH_SIZE = 1;

run_tests(
    59,
    sub {
        my $client = test_client( dbs => ['ts1'] );

        # Define that we want to use priority selection
        # limit batch size to 1 so we always process jobs in
        # priority order
        $client->set_prioritize(1);

        for ( 1 .. 10 ) {

            # Postgres uses ORDER BY priority NULLS FIRST when DESC is used
            my $job = TheSchwartz::Job->new(
                funcname => 'Worker::PriorityTest',
                arg      => { num => $_ },
                ( !$ENV{USE_PGSQL} && $_ == 1 ? () : ( priority => $_ ) ),
            );
            my $h = $client->insert($job);
            ok( $h, "inserted job (priority $_)" );
        }

        $client->reset_abilities;
        $client->can_do("Worker::PriorityTest");

        Worker::PriorityTest->set_client($client);

        for ( 1 .. 10 ) {

            # Postgres uses ORDER BY priority NULLS FIRST when DESC is used
            $record_expected
                = !$ENV{USE_PGSQL} && 11 - $_ == 1 ? undef : 11 - $_;

            my $rv = eval { $client->work_once; };
            ok( $rv, "did stuff" );
        }
        my $rv = eval { $client->work_once; };
        ok( !$rv, "nothing to do now" );

        teardown_dbs('ts1');

        # test we get in jobid order for equal priority RT #99075
        $testnum = 1;
        my $client2 = test_client( dbs => ['ts2'] );

        $client2->reset_abilities;
        $client2->can_do("Worker::PriorityTest");

        Worker::PriorityTest->set_client($client2);

        # Define that we want to use priority selection
        # limit batch size to 1 so we always process jobs in
        # priority order
        $client2->set_prioritize(1);

        for ( 1 .. 5 ) {
            my $job = TheSchwartz::Job->new(
                funcname => 'Worker::PriorityTest',
                arg      => { num => $_ },
                priority => 5,
            );
            my $h = $client2->insert($job);
            ok( $h, "inserted job (priority $_)" );
        }

        for ( 1 .. 5 ) {
            $record_expected = $_;
            my $rv = eval { $client2->work_once; };
            ok( $rv, "did stuff 1-5" );
        }
        $rv = eval { $client2->work_once; };
        ok( !$rv, "nothing to do now 1-5" );

        teardown_dbs('ts2');

        # test floor RT #50842
        $testnum = 2;

        $client2 = test_client( dbs => ['ts3'] );
        $client2->set_prioritize(1);
        $client2->reset_abilities;
        $client2->can_do("Worker::PriorityTest");

        Worker::PriorityTest->set_client($client2);

        $client2->set_floor($floor);

        for ( 1 .. 5 ) {
            my $job = TheSchwartz::Job->new(
                funcname => 'Worker::PriorityTest',
                arg      => { num => $_ },
                priority => $_,
            );
            my $h = $client2->insert($job);
            ok( $h, "inserted job (priority $_)" );
        }

        for ( $floor .. 5 ) {
            $record_expected = $_;
            my $rv = eval { $client2->work_once; };
            ok( $rv, "did stuff 3-5" );
        }
        $rv = eval { $client2->work_once; };
        ok( !$rv, "sub-floor jobs remaining but you can't have them" );

        teardown_dbs('ts3');
        $testnum = 0;
    }
);

############################################################################
package Worker::PriorityTest;
use base 'TheSchwartz::Worker';
use Test::More;

use strict;
my $client;
sub set_client { $client = $_[1]; }

sub work {
    my ( $class, $job ) = @_;
    my $priority = $job->priority;

    if ( $main::testnum == 1 ) {
        ok( $job->jobid == $main::record_expected,
            "order by ID for same priority"
        );
    }
    elsif ( $main::testnum == 2 ) {
        ok( $job->priority >= $floor, "check floor" );
    }
    else {
        ok( ( !defined($main::record_expected) && ( !defined($priority) ) )
                || ( $priority == $main::record_expected ),
            "priority matches expected priority"
        );
    }

    $job->completed;
}

sub keep_exit_status_for {
    20;
}    # keep exit status for 20 seconds after on_complete

sub grab_for {10}

sub max_retries {1}

sub retry_delay { my $class = shift; my $fails = shift; return 2**$fails; }

