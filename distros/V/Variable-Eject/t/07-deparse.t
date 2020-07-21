#!/usr/bin/env perl

use strict;
use Test::More tests => 2;
use Test::NoWarnings;
use lib::abs '../lib';
use Variable::Eject;
use B::Deparse;

my $hash = {
	scalar => 'scalar value',
	array  => [1..3],
	hash   => { my => 'value' },
};

sub test {
	eject($hash => $scalar, @array, %hash);
}
test();
my $text = B::Deparse->new->coderef2text(\&test);
diag $text;
like($text , qr{'\?\?\?'}s, 'sub optimized out' );
