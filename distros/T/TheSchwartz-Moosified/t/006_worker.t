#!/usr/bin/perl

use strict;
use warnings;
use t::Utils;
use TheSchwartz::Moosified;
use List::Util qw/shuffle/;

plan tests => 34;

our @Jobs_completed;

foreach $::prefix ("", "someprefix") {

run_test {
    my $dbh = shift;
    my $sch = TheSchwartz::Moosified->new(prioritize => 1);
    ok $sch, 'got TheSchwartz';
    ok $sch->prioritize, 'prioritization is turned on';
    $sch->databases([$dbh]);
    $sch->prefix($::prefix) if $::prefix;

    # disable the effects of shuffling found jobs
    local $TheSchwartz::Moosified::FIND_JOB_BATCH_SIZE = 1;

    my @expected_prio = (5,4,3,2,1,undef,-1);
    my %job_map;
    for my $prio (shuffle(@expected_prio)) {
        my $funcname = (($prio||0)%2) ? 'Worker::Ok' : 'Worker::Ok2';
        my $jh = $sch->insert(TheSchwartz::Moosified::Job->new(
            funcname => $funcname,
            priority => $prio,
            arg => 'arg',
        ));
        ok $jh && $jh->jobid, "created $funcname job for prio ".($prio||'undef');
        $job_map{$jh->jobid} = $prio;
    }

    @Jobs_completed = ();
    $sch->can_do($_) for qw(Worker::Ok Worker::Ok2);
    $sch->work_until_done();

    my @actual_prio = map {$job_map{$_}} @Jobs_completed;
    is_deeply \@actual_prio, \@expected_prio,
        'jobs completed in the expected priority order';
};

} # prefix

{
    package Worker::Ok;
    use base 'TheSchwartz::Moosified::Worker';
    sub grab_for { 86400 }
    sub work {
        my ($class, $job) = @_;
        Test::More::pass("job ".$job->jobid);
        push @::Jobs_completed, $job->jobid;
        $job->success;
    }

    package Worker::Ok2;
    use base 'Worker::Ok';
}
