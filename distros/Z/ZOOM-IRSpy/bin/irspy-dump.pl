#!/usr/bin/perl

# Invoke as:
#	$ mkdir records-2010-04-06
#	$ cd records-2010-04-06
#	$ irspy-dump.pl irspy.indexdata.com:8018/IR-Explain---1
#	$ cd ..
#	$ tar cfz records-2010-04-06.tar.gz records-2010-04-06
#
# or: cd zebra; make dump

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
print "$0: dumping $n records\n";

my $step = 200;
my $step2 = 10;
foreach my $i (1..$n) {
    print "." if $i % $step2 == 0;
    print " $i/$n (", int($i*100/$n), "%)\n" if $i % $step == 0;
    my $rec = $rs->record($i-1);
    my $xml = $rec->render();
    open F, ">$i.xml" or die "open $i.xml: $!\n";
    print F $xml;
    close F;
}
print " $n/$n (100%)\n" if $n % $step != 0;
print "complete\n";
