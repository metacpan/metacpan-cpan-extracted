#!/usr/bin/perl

use strict;
use warnings;
use t::Utils;
use TheSchwartz::Moosified;

plan tests => 20;

# for testing:
$TheSchwartz::Moosified::T_EXITSTATUS_CLEAN_THRES = 1; # delete 100% of the time, not 10% of the time
$TheSchwartz::Moosified::T_ERRORS_MAX_AGE = 2;         # keep errors for 3 seconds, not 1 week

foreach $::prefix ("", "someprefix") {

run_test {
    my $dbh = shift;
    my $client = TheSchwartz::Moosified->new();
    $client->databases([$dbh]);
    $client->prefix($::prefix) if $::prefix;

    $client->can_do("Worker::Fail");
    $client->can_do("Worker::Complete");
    
    my $table_exitstatus = $client->prefix . 'exitstatus';
    my $table_error = $client->prefix . 'error';
    
    # insert a job which will fail, then succeed.
    {
        my $handle = $client->insert("Worker::Fail");
        isa_ok $handle, 'TheSchwartz::Moosified::JobHandle', "inserted job";

        $client->work_until_done;
        is($handle->failures, 1, "job has failed once");

        my $min;
        my $rows = $dbh->selectrow_array("SELECT COUNT(*) FROM $table_exitstatus");
        is($rows, 1, "has 1 $table_exitstatus row");

        ok($client->insert("Worker::Complete"), "inserting to-pass job");
        $client->work_until_done;
        $rows = $dbh->selectrow_array("SELECT COUNT(*) FROM $table_exitstatus");
        is($rows, 2, "has 2 $table_exitstatus rows");
        ($rows, $min) = $dbh->selectrow_array("SELECT COUNT(*), MIN(jobid) FROM $table_error");
        is($rows, 1, "has 1 $table_error rows");
        is($min, 1, "$table_error jobid is the old one");

        # wait for exit status to pass
        sleep 3;

        # now make another job fail to cleanup some errors
        $handle = $client->insert("Worker::Fail");
        $client->work_until_done;

        $rows = $dbh->selectrow_array("SELECT COUNT(*) FROM $table_exitstatus");
        is($rows, 1, "1 exit status row now");

        ($rows, $min) = $dbh->selectrow_array("SELECT COUNT(*), MIN(jobid) FROM $table_error");
        is($rows, 1, "has 1 $table_error row still");
        is($min, 3, "$table_error jobid is only the new one");

    }
};

}

############################################################################
############################################################################
package Worker::Fail;
use base 'TheSchwartz::Moosified::Worker';

sub work {
    my ($class, $job) = @_;
    $job->failed("an error message");
    return;
}

sub keep_exit_status_for { 1 }  # keep exit status for 20 seconds after on_complete

sub max_retries { 0 }

sub retry_delay { 1 }

# ---------------

package Worker::Complete;
use base 'TheSchwartz::Moosified::Worker';
sub work {
    my ($class, $job) = @_;
    $job->completed;
    return;
}

sub keep_exit_status_for { 1 }
