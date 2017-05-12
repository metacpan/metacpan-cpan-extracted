use strict;
use warnings;
use t::Utils;
use TheSchwartz::Simple;

plan tests => 30;

foreach $::prefix ("", "someprefix") {

run_test {
    my $dbh = shift;
    my $sch = TheSchwartz::Simple->new($dbh);
    $sch->prefix($::prefix) if $::prefix;
    my @jobid;

    push @jobid, $sch->insert('fetch', 'http://wassr.jp/');
    push @jobid, $sch->insert(
        TheSchwartz::Simple::Job->new(
            funcname => 'fetch',
            arg      => 'http://pathtraq.com/',
            priority => 3,
        )
    );
    push @jobid, $sch->insert('fetch', { url => 'http://example.com' });

    my $sth = $dbh->prepare("SELECT jobid, funcid, arg, priority FROM ${main::prefix}job WHERE jobid IN (?, ?, ?) ORDER BY jobid ASC");
    $sth->execute(@jobid);

    my $row = $sth->fetchrow_hashref;
    ok $row;
    is $row->{jobid},    $jobid[0];
    is $row->{funcid},   $sch->funcname_to_id( $dbh, 'fetch' );
    is $row->{arg},      'http://wassr.jp/';
    is $row->{priority}, undef;

    $row = $sth->fetchrow_hashref;
    ok $row;
    is $row->{jobid},    $jobid[1];
    is $row->{funcid},   $sch->funcname_to_id( $dbh, 'fetch' );
    is $row->{arg},      'http://pathtraq.com/';
    is $row->{priority}, 3;

    $row = $sth->fetchrow_hashref;
    ok $row;
    is $row->{jobid},    $jobid[2];
    is $row->{funcid},   $sch->funcname_to_id( $dbh, 'fetch' );
    is $row->{priority}, undef;
    is_deeply Storable::thaw($row->{arg}), { url => 'http://example.com' };
};

}
