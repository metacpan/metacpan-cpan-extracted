#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Builder::Tester;

use Test::MemoryGrowth;

my $l = 10;
my $r = 20;
my $sum;

test_out( "ok 1 - addition does not grow" );
no_growth { $sum = $l + $r } "addition does not grow";
test_test( "no_growth addition succeeds" );

my @arr;
test_out( "not ok 1 - push does not grow" );
test_fail( +10 );
test_err( qr/^# Lost \d+ bytes of memory over \d+ calls, average of \d+\.\d\d per call\n/ );
if( Test::MemoryGrowth::HAVE_DEVEL_GLADIATOR ) {
   test_err( qr/^# Growths in arena object counts:\n/ );
   test_err( qr/^#   SCALAR \d+ -> \d+ \(1\.00 per call\)\n/ );
}
if( Test::MemoryGrowth::HAVE_DEVEL_MAT_DUMPER ) {
   test_err( qr/^# Writing heap dump to \S+\n/ );
   test_err( qr/^# Writing heap dump after one more iteration to \S+\n/ );
}
no_growth { push @arr, "hello"; } "push does not grow";
test_test( "no_growth push fails" );

done_testing;

END {
   # Clean up Devel::MAT dumpfile
   ( my $basename = $0 ) =~ s/\.t$//;

   -f and unlink for "$basename-1.pmat", "$basename-1-after.pmat";
}
