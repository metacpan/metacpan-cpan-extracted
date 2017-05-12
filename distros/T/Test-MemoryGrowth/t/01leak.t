#!/usr/bin/perl -w

use strict;

use Test::Builder::Tester tests => 2;

use Test::MemoryGrowth;

my $l = 10;
my $r = 20;
my $sum;

test_out( "ok 1 - addition does not grow" );
no_growth { $sum = $l + $r } "addition does not grow";
test_test( "no_growth addition succeeds" );

my @arr;
test_out( "not ok 1 - push does not grow" );
test_fail( +3 );
test_err( qr/^# Lost \d+ bytes of memory over \d+ calls, average of \d+\.\d\d per call\n/ );
test_err( qr/^# Writing heap dump to \S+\n/ ) if Test::MemoryGrowth::HAVE_DEVEL_MAT_DUMPER;
no_growth { push @arr, "hello"; } "push does not grow";
test_test( "no_growth push fails" );

END {
   # Clean up Devel::MAT dumpfile
   my $pmat = $0;
   $pmat =~ s/\.t$/-1.pmat/;
   unlink $pmat if -f $pmat;
}
