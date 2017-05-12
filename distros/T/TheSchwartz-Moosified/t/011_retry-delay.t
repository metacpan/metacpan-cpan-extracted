#!/usr/bin/perl

use strict;
use warnings;
use t::Utils;
use TheSchwartz::Moosified;

plan tests => 22;

foreach $::prefix ("", "someprefix") {

run_test {
    my $dbh = shift;
    my $client = TheSchwartz::Moosified->new();
    $client->databases([$dbh]);
    $client->prefix($::prefix) if $::prefix;

    $client->can_do("Worker::Fail");
    $client->can_do("Worker::Complete");
    
    # insert a job which will fail, fail, then succeed.
    {
        my $handle = $client->insert("Worker::CompleteEventually");
        isa_ok $handle, 'TheSchwartz::Moosified::JobHandle', "inserted job";
        my $eventually_run_after = $handle->job->run_after;

        my $h2 = $client->insert("Worker::Complete");
        isa_ok $h2, 'TheSchwartz::Moosified::JobHandle',
            "inserted job that won't get run";
        my $h2_after = $h2->job->run_after;

        my $table_job = $client->prefix . 'job';
        my ($before_retry) = $dbh->selectall_arrayref(qq{
            SELECT * FROM $table_job WHERE jobid=?
        }, {}, $h2->jobid);

        $client->reset_abilities();
        $client->can_do("Worker::CompleteEventually");
        $client->work_until_done;

        is($handle->failures, 1, "job has failed once");

        my ($after_retry) = $dbh->selectall_arrayref(qq{
            SELECT * FROM $table_job WHERE jobid=?
        }, {}, $h2->jobid);
        is_deeply $after_retry, $before_retry,
            'odd job wasn\'t affected by the retry';

        my $job = Worker::CompleteEventually->grab_job($client);
        ok(!$job, "a job isn't ready yet"); # hasn't been two seconds
        sleep 3;   # 2 seconds plus 1 buffer second

        $job = Worker::CompleteEventually->grab_job($client);
        ok($job, "got a job, since time has gone by");

        Worker::CompleteEventually->work_safely($job);
        is($handle->failures, 2, "job has failed twice");

        $job = Worker::CompleteEventually->grab_job($client);
        ok($job, "got the job back");

        Worker::CompleteEventually->work_safely($job);
        ok(! $handle->is_pending, "job has exited");
        is($handle->exit_status, 0, "job succeeded");

        my ($far_after_retry) = $dbh->selectall_arrayref(qq{
            SELECT * FROM $table_job WHERE jobid=?
        }, {}, $h2->jobid);
        is_deeply $far_after_retry, $before_retry,
            'odd job still wasn\'t affected by the retry';
    }
};

}

############################################################################
package Worker::CompleteEventually;
use base 'TheSchwartz::Moosified::Worker';

sub work {
    my ($class, $job) = @_;
    my $failures = $job->failures;
    if ($failures < 2) {
        $job->failed;
    } else {
        $job->completed;
    }
    return;
}

sub keep_exit_status_for { 20 }  # keep exit status for 20 seconds after on_complete

sub max_retries { 2 }

sub retry_delay {
    my $class = shift;
    my $fails = shift;
    return [undef,2,0]->[$fails];  # fails 2 seconds first time, then immediately
}

package Worker::Complete;
use base 'TheSchwartz::Moosified::Worker';
sub work {
    my ($class, $job) = @_;
    $job->completed;
}
