#!/usr/bin/env perl

use v5.14;
use warnings
  FATAL    => qw(all),
  NONFATAL => qw(deprecated exec internal malloc newline once portable redefine recursion uninitialized);

use Test::Builder::Tester tests => 2;

use Test::Expander;

my ($expected, $title);

$title    = 'RegEx expected (stringified exception comparison)';
test_out("ok 1 - $title");
$expected = qr/DIE TEST/;
throws_ok(sub { die($expected) }, $expected, $title);
test_test($title);

$title    = 'scalar expected (exception class comparison)';
test_out("ok 1 - $title");
$expected = 'DIE_TEST';
throws_ok(sub { die(bless({}, $expected)) }, $expected, $title);
test_test($title);
