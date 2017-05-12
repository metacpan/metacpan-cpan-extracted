use strict;
use warnings;

require 't/lib/db-common.pl';

use TheSchwartz;
use Test::More tests => (5 + 21) * 3;

our $decline = 1;

run_tests(
    5,
    sub {
        my $client = test_client( dbs => ['ts1'] );

        # insert a job which will fail, fail, then succeed.
        {
            my $handle = $client->insert("Worker::CompleteEventually");
            isa_ok $handle, 'TheSchwartz::JobHandle', "inserted job";

            $client->can_do("Worker::CompleteEventually");
            $client->work_until_done;

            is( $handle->failures,   0, "job hasn't failed" );
            is( $handle->is_pending, 1, "job is still pending" );

            my $job = Worker::CompleteEventually->grab_job($client);
            ok( !$job, "a job isn't ready yet" );    # hasn't been two seconds
            sleep 3;    # 2 seconds plus 1 buffer second

            $job = Worker::CompleteEventually->grab_job($client);
            ok( !$job,
                "didn't get a job, because job is 'held' not retrying" );
        }

        teardown_dbs('ts1');
    }
);

run_tests(
    21,
    sub {
        my $client = test_client( dbs => ['ts2'] );

        {
            $decline = 1;
            $client->reset_abilities;
            $client->can_do("Worker::DeclineWithTime");
            $client->verbose(1);
            Worker::DeclineWithTime->set_client($client);

            for ( 1 .. 5 ) {
                my $job = TheSchwartz::Job->new(
                    funcname => 'Worker::DeclineWithTime',
                    arg      => { num => $_ },
                );
                my $h = $client->insert($job);
                ok( $h, "inserted job $_" );
            }

            for ( 1 .. 5 ) {
                my $rv = eval { $client->work_once; };
                ok( $rv, "did stuff 1-5" );
            }

            my $job = Worker::DeclineWithTime->grab_job($client);
            ok( !$job, "didn't get a job, because run_after" );

            sleep 5;

            $decline = 0;

            for ( 1 .. 5 ) {
                my $rv = eval { $client->work_once; };
                ok( $rv, "end stuff 1-5" );
            }
        }

        teardown_dbs('ts2');
    }
);

done_testing();

############################################################################
package Worker::CompleteEventually;
use base 'TheSchwartz::Worker';

sub work {
    my ( $class, $job ) = @_;
    $job->declined;
    return;
}

sub keep_exit_status_for {
    20;
}    # keep exit status for 20 seconds after on_complete

sub max_retries {2}

sub retry_delay {
    my $class = shift;
    my $fails = shift;
    return [ undef, 2, 0 ]->[$fails]
        ;    # fails 2 seconds first time, then immediately
}

1;
############################################################################
package Worker::DeclineWithTime;
use base 'TheSchwartz::Worker';
use strict;
use Test::More;

my $client;
sub set_client { $client = $_[1]; }

sub work {
    my ( $class, $job ) = @_;
    if ($main::decline) {
        $job->declined( time() + 2 );
    }
    else {
        ok( $job->run_after < time(), 'ensure time out' );
    }

    return;
}

sub keep_exit_status_for {
    20;
}    # keep exit status for 20 seconds after on_complete
1;
