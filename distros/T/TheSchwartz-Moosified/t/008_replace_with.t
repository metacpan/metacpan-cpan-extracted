#!/usr/bin/perl

use strict;
use warnings;
use t::Utils;
use TheSchwartz::Moosified;

plan tests => 10;

our @Jobs_completed;

foreach $::prefix ("", "someprefix") {

run_test {
    my $dbh = shift;
    my $sch = TheSchwartz::Moosified->new(prioritize => 1);
    ok $sch, 'got TheSchwartz';
    $sch->databases([$dbh]);
    $sch->prefix($::prefix) if $::prefix;

    my $jh = $sch->insert(TheSchwartz::Moosified::Job->new(
        funcname => 'Worker',
        uniqkey => 'aaaa',
        arg => { again => 'again' },
    ));
    ok $jh && $jh->jobid, "created job";

    @Jobs_completed = ();
    $sch->can_do('Worker');
    $sch->work_until_done;
    is scalar(@Jobs_completed), 2, '2 jobs completed';
    is $Jobs_completed[0], $jh->jobid, 'first job was the scheduled one';
    isnt $Jobs_completed[1], $jh->jobid, 'second job wasn\'t the scheduled one';
};

} # prefix

{
    package Worker;
    use base 'TheSchwartz::Moosified::Worker';
    sub work {
        my ($class, $job) = @_;
        my $clone = TheSchwartz::Moosified::Job->new(
            funcname => $job->funcname,
            uniqkey => $job->uniqkey,
            arg => { again => 0 }
        );
        if ($job->arg->{again}) {
            $job->replace_with($clone);
        }
        else {
            $job->completed();
        }
        push @Jobs_completed, $job->jobid;
    }
}
