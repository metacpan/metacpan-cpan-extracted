#!/usr/bin/perl -w

use Test::More 'tests' => 14;

	BEGIN { use_ok('Time::Simple::Range') };

	my $r = new Time::Simple::Range('12:00:01');

	ok(defined $r,				'new returned a object');
	ok($r->isa('Time::Simple::Range'),	' and class is correct');
	ok(!$r,					" it's not complete");

	my $end = Time::Simple->new('13:20:02');
	$r->end($end);
	
	ok($r,					" but can be completed");

	is($r->start, '12:00:01',		'we can keep the start time');
	is($r->end, '13:20:02',			'and the end time too');


	ok($r->duration,			'we have a duration');
	is($r->duration, 60 * 80 + 1,		' w/ correct number of seconds');
	is(int $r->minutes, 80,			' and minutes');

	is("$r", '12:00:01-13:20:02',		'we can stringify correctly');

	my $r2 = $r->clone;
	
	ok($r2,					'we can be cloned');
	is($r->start, $r2->start,		' and still keep the time');
	is($r->end, $r2->end,			' (both of them)');
