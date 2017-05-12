#!/usr/bin/env perl

#use uni::perl;
use strict;
use warnings;
use Test::More tests => 3;
use Test::NoWarnings;
use lib::abs '../lib';
use Variable::Eject;

sub test {}
my $hash = { test => 'scalar value' };

eject( $hash => $test );

is $test, 'scalar value', 'scalar ejected';
$test .= ' modified';

is_deeply $hash, {
	test => 'scalar value modified',
}, 'original modified';
