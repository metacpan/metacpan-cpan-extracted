#!/usr/bin/env perl

use uni::perl;
use Test::More skip_all => 'TODO: unimplemented syn';
use Test::More tests => 3;
use Test::NoWarnings;
use lib::abs '../lib';
use Variable::Eject;

my $hash = { scalar => 'scalar value' };

eject $hash => $scalar;

is $scalar, 'scalar value', 'scalar ejected';
$scalar .= ' modified';

is_deeply $hash, {
	scalar => 'scalar value modified',
}, 'original modified';
