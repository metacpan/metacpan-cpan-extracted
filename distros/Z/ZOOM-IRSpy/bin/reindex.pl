#!/usr/bin/perl

use strict;
use warnings;
use ZOOM;

if (@ARGV != 1) {
    print STDERR "Usage: $0 target\n";
    exit 1;
}

my $conn = new ZOOM::Connection($ARGV[0]);
$conn->option(preferredRecordSyntax => "xml");
$conn->option(elementSetName => "zebra::data");
my $rs = $conn->search_pqf('@attr 1=_ALLRECORDS @attr 2=103 ""');
my $n = $rs->size();
$| = 1;
print "$0: reindexing $n records\n";
foreach my $i (1..$n) {
    print ".";
    print " $i/$n (", int($i*100/$n), "%)\n" if $i % 50 == 0;
    my $rec = $rs->record($i-1);
    my $xml = $rec->render();
    update($conn, $xml);
}
print " $n/$n (100%)\n" if $n % 50 != 0;
commit($conn);
print "committed\n";


# These might be better as ZOOM::Connection methods
sub update {
    my($conn, $xml) = @_;

    my $p = $conn->package();
    $p->option(action => "specialUpdate");
    $p->option(record => $xml);
    $p->send("update");
    $p->destroy();
}

sub commit {
    my($conn) = @_;

    my $p = $conn->package();
    $p->send("commit");
    $p->destroy();
}
