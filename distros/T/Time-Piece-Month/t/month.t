#!/usr/bin/perl -w

use strict;
use Test::More;

my @tests = (
	[ "2000-01-13", "2000-01-01", "2000-01-31", "1999-12-26", "2000-02-05" ],
	[ "2000-02-13", "2000-02-01", "2000-02-29", "2000-01-30", "2000-03-04" ],
	[ "2001-02-13", "2001-02-01", "2001-02-28", "2001-01-28", "2001-03-03" ],
	[ "2001-09-18", "2001-09-01", "2001-09-30", "2001-08-26", "2001-10-06" ],
	[ "2002-12-31", "2002-12-01", "2002-12-31", "2002-11-24", "2003-01-04" ],
);

plan tests => 1 + @tests * 8;

use_ok 'Time::Piece::Month';

foreach my $data (@tests) {
	my ($date, $start, $end, $wstart, $wend) = @$data;
	my $month = Time::Piece::Month->new($date);
	isa_ok $month => 'Time::Piece::Month';
	isa_ok $month => 'Time::Piece::Range';
	is $month->start->ymd, $start, "Start date: $start";
	is $month->end->ymd,   $end,   "End date: $end";

	my ($s, $e) = map $_->ymd, ($month->dates)[ 0, -1 ];
	is $s, $start, "First day: $start";
	is $e, $end,   "Last day: $end";

	my ($ws, $we) = map $_->ymd, ($month->wraparound_dates)[ 0, -1 ];
	is $ws, $wstart, "First wrap: $wstart";
	is $we, $wend,   "Last wrap: $wend";

}
