use strict;
use warnings;
use t::Utils;
use TheSchwartz::Simple;
plan tests => 20;

foreach $::prefix ("", "someprefix") {

run_test {
    my $dbh = shift;
    my $sch = TheSchwartz::Simple->new($dbh);
    $sch->prefix($::prefix) if $::prefix;

    $sch->insert('fetch', 'http://wassr.jp/');
    $sch->insert(
        TheSchwartz::Simple::Job->new(
            funcname => 'fetch',
            arg      => 'http://pathtraq.com/',
            priority => 3,
        )
    );

    my @jobs = $sch->list_jobs({funcname => 'fetch'});

    my $row = $jobs[0];
    ok $row;
    is $row->jobid,    1;
    is $row->funcid,   $sch->funcname_to_id( $dbh, 'fetch' );
    is $row->arg,      'http://wassr.jp/';
    is $row->priority, undef;

    $row = $jobs[1];
    ok $row;
    is $row->jobid,    2;
    is $row->funcid,   $sch->funcname_to_id( $dbh, 'fetch' );
    is $row->arg,      'http://pathtraq.com/';
    is $row->priority, 3;
};

}
