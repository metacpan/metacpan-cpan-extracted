#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Strict;

my $f1 = "1.pl~";
my $f2 = "2.pl";
my $f3 = "3.pm~";
my $f4 = "4.pm";

ok(!Test::Strict::_is_perl_script("1.pl~"));
ok(Test::Strict::_is_perl_script("1.pl"));

ok(!Test::Strict::_is_perl_module("3.pm~"));
ok(Test::Strict::_is_perl_module("4.pm"));

done_testing();
