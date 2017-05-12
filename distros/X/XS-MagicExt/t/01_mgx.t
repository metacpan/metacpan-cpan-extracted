#!perl -w

use strict;
use Test::More;

use FindBin qw($Bin);
use File::Spec;
use Config;

my $dist_dir = File::Spec->join($Bin, 'test');
chdir $dist_dir or die "Cannot chdir to $dist_dir: $!";

my $make = $Config{make};

my $out;

ok($out = `$^X Makefile.PL`, "$^X Makefile.PL");
is $?, 0, '... success' or diag $out;

ok($out = `$make`, $make);
is $?, 0, '... success' or diag $out;

ok($out = `$make test`, "$make test");
is $?, 0, '... success' or diag $out;

ok($out = `$make clean`, "$make clean");
is $?, 0, '... success' or diag $out;

done_testing;
