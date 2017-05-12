#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;
use Unwind::Protect;

my @calls;

my $ret = unwind_protect { 1 + 1 }
          after => sub { push @calls, 'protected' };

is($ret, 2);
is_deeply([splice @calls], ['protected']);

my @ret = unwind_protect { (1, 2) }
          after => sub { push @calls, 'protected' };

is_deeply(\@ret, [1, 2]);
is_deeply([splice @calls], ['protected']);

$ret = unwind_protect { (1, 2) }
       after => sub { push @calls, 'protected' };

is($ret, 2);
is_deeply([splice @calls], ['protected']);

