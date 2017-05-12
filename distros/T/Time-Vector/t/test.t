#!/usr/bin/perl -w

use Test::More 'tests' => 23;

	BEGIN { use_ok('Time::Vector') };

	my $wt = new Time::Vector;

	ok(defined $wt,				'new returned a object');
	ok($wt->isa('Time::Vector'),		' and class is correct');
	ok(defined $wt->vec,			' and there\'s a vector');
	ok($wt->vec->isa('Bit::Vector'),	' a Bit::Vector!');
	is($wt->vec->Size, 1440,		' correctly sized');

	ok(!defined $wt->first,			' first is not defined');
	ok(!defined $wt->last,			' neither is last');

	$wt = Time::Vector->new_range('08:30', '12:30', '14:00', '18:00');	
	
	ok(defined $wt,				'new_range returned a object');
	ok($wt->isa('Time::Vector'),		' and class is correct');
	ok(defined $wt->vec,			' and there\'s a vector');
	ok($wt->vec->isa('Bit::Vector'),	' a Bit::Vector!');

	ok(defined $wt->first,			' first is defined');
	ok(defined $wt->last,			' and last too');

	ok(defined $wt->after,			'after range is ok');
	ok(defined $wt->before,			'before too');

	is("$wt", "08:30-12:30,14:00-18:00",	'stringification is ok');

#	my @expected = ('08:30-12:30', '14:00-18:00');
#	is_deeply([ map { "$_" } $wt->range], \@expected,	'range is ok');

	my $wc = $wt->clone;
	ok(defined $wc,				'we can be cloned');
	is($wt->vec, $wc->vec,			' and our DNA is not malformed');

	ok($wt->duration,			'we have a duration');
	is($wt->duration, 60 * 60 * 8,		' w/ correct number of seconds');

	# XXX verify after and before

	my $w1 = Time::Vector->new_range('08:30', '12:30');
	my $w2 = Time::Vector->new_range('14:00', '18:00');

	is(($w1 | $w2)->vec, $wt->vec,		'the or operator works nicely');
	is(($wt & $w1)->vec, $w1->vec,		'the and operator too');
