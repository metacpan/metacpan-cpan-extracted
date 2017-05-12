#!/usr/bin/perl

use warnings;
use strict;

# test that we can create a frame with a size but no position

use Test::More 'no_plan';

use_ok('Wx');
use_ok('wxPerl::Constructors');

my $frame = eval {
  wxPerl::Frame->new(undef, 'a frame', size => Wx::Size->new(800,600));
};
ok(! $@);
ok($frame);

# vim:ts=2:sw=2:et:sta
