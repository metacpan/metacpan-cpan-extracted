#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More tests => 4;
use Capture::Tiny ':all';

my $shared_arguments = qq{path => "$Bin/test_data", perltidyrc => "$Bin/test_data/perltidyrc", mute => 1};
my $output_of_sequential = capture_merged {qx(perl -MTest::PerlTidy -e 'run_tests($shared_arguments);')};
my $output_of_concurrent =
  capture_merged {qx(perl -I$Bin/../lib -MTest::PerlTidy::Concurrent -e 'run_tests($shared_arguments, j => 9);')};

like($output_of_sequential, qr/Failed test .*bad\.pl/, 'The bad test is succeeded in sequentual module.');
like($output_of_concurrent, qr/Failed test .*bad\.pl/, 'The bad test is succeeded in concurrent module.');

my $last_string_of_sequential = (split("\n", $output_of_sequential))[-1];
my $last_string_of_concurrent = (split("\n", $output_of_concurrent))[-1];

is(
    $last_string_of_sequential,
    '# Looks like you failed 1 test of 2.',
    'The sequentual version succeeded test number is correct.'
  );
is(
    $last_string_of_concurrent,
    '# Looks like you failed 1 test of 2.',
    'The concurrent version succeeded test number is correct.'
  );

exit;
