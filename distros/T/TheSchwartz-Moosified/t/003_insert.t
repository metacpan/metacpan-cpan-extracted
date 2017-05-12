use strict;
use warnings;
use t::Utils;
use TheSchwartz::Moosified;

plan tests => 20;

foreach $::prefix ("", "someprefix") {

run_test {
    my $dbh = shift;
    my $sch = TheSchwartz::Moosified->new();
    $sch->databases([$dbh]);
    $sch->prefix($::prefix) if $::prefix;

    $sch->insert('fetch', 'http://wassr.jp/');
    $sch->insert(
        TheSchwartz::Moosified::Job->new(
            funcname => 'fetch',
            arg      => 'http://pathtraq.com/',
            priority => 3,
        )
    );

    my $table_job = $sch->prefix . 'job';
    my $sth = $dbh->prepare("SELECT jobid, funcid, arg, priority FROM $table_job ORDER BY jobid ASC");
    $sth->execute;

    my $row = $sth->fetchrow_hashref;
    ok $row;
    is $row->{jobid},    1;
    is $row->{funcid},   $sch->funcname_to_id( $dbh, 'fetch' );
    is $row->{arg},      'http://wassr.jp/';
    is $row->{priority}, undef;

    $row = $sth->fetchrow_hashref;
    ok $row;
    is $row->{jobid},    2;
    is $row->{funcid},   $sch->funcname_to_id( $dbh, 'fetch' );
    is $row->{arg},      'http://pathtraq.com/';
    is $row->{priority}, 3;
};

}