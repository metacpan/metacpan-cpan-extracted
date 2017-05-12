#!/usr/bin/perl
use strict;
use warnings;
use t::Utils;
use TheSchwartz::Moosified;

plan tests => 16;

{
    package Worker::Fail;

    use base 'TheSchwartz::Moosified::Worker';
    sub work {
        my ($class, $job) = @_;
        my $message = $job->arg->{message};
        $job->permanent_failure($message, 100);
    }
}

foreach $::prefix ("", "someprefix") {

run_test {
    my $dbh = shift;
    my $sch = TheSchwartz::Moosified->new(
        databases => [$dbh],
        prefix => $::prefix,
    );

    {
        my $handle = $sch->insert('Worker::Fail', {message => '0' x 256});
        ok $handle, 'job created for truncating';
        $sch->can_do('Worker::Fail');
        $sch->work_until_done;

        my ($count) = @{$dbh->selectcol_arrayref("SELECT COUNT(*) FROM ".$::prefix."error") || []};
        is $count, 1, 'single error';
        my @log = $handle->failure_log;
        is scalar(@log), 1, "one logged error";
        is length($log[0]), 255, "error was truncated";
    }

    $sch->error_length(0);
    {
        my $handle = $sch->insert('Worker::Fail', {message => '0' x 1024});
        ok $handle, 'job created for preserving';
        $sch->can_do('Worker::Fail');
        $sch->work_until_done;

        my ($count) = @{$dbh->selectcol_arrayref("SELECT COUNT(*) FROM ".$::prefix."error") || []};
        is $count, 2, 'another error';
        my @log = $handle->failure_log;
        is scalar(@log), 1, "one logged error";
        is length($log[0]), 1024, "error was *not* truncated";
    }

};

}
