# $Id: from_mssql.t,v 1.2 2004/10/26 17:00:09 rjbs Exp $
use strict;
use warnings;

use Test::More tests => 55;

BEGIN { use_ok('Time::Piece::MSSQL'); }

{
	my $time = Time::Piece->from_mssql_datetime("2004-01-02 12:34:56.000");
	isa_ok($time, 'Time::Piece');
	is($time->year, 2004, "year");
	is($time->mon,     1, "month");
	is($time->mday,    2, "day of month");
	is($time->hour,   12, "hour");
	is($time->min,    34, "minutes");
	is($time->sec,    56, "seconds");
}

{
	my $time = Time::Piece->from_mssql_datetime("2004-01-02 12:34:56.089");
	isa_ok($time, 'Time::Piece');
	is($time->year, 2004, "year");
	is($time->mon,     1, "month");
	is($time->mday,    2, "day of month");
	is($time->hour,   12, "hour");
	is($time->min,    34, "minutes");
	is($time->sec,    56, "seconds");
}

{
	my $time = Time::Piece->from_mssql_datetime("2004-01-02 21:34:56.089");
	isa_ok($time, 'Time::Piece');
	is($time->year, 2004, "year");
	is($time->mon,     1, "month");
	is($time->mday,    2, "day of month");
	is($time->hour,   21, "hour");
	is($time->min,    34, "minutes");
	is($time->sec,    56, "seconds");
}

{
	my $time = Time::Piece->from_mssql_datetime(undef);
	is($time, undef, 'invalid string returns undef (undef)');
}

{
	my $time = Time::Piece->from_mssql_datetime("2004-01-02 12:34:56");
	is($time, undef, 'invalid string returns undef (no ms)');
}

{
	my $time = Time::Piece->from_mssql_datetime("2004-01-02 89:34:56.089");
	is($time, undef, 'invalid string returns undef (out of range)');
}

{
	my $time = Time::Piece->from_mssql_smalldatetime("2004-01-02 12:34:56");
	isa_ok($time, 'Time::Piece');
	is($time->year, 2004, "year");
	is($time->mon,     1, "month");
	is($time->mday,    2, "day of month");
	is($time->hour,   12, "hour");
	is($time->min,    34, "minutes");
	is($time->sec,    56, "seconds");
}

{
	my $time = Time::Piece->from_mssql_smalldatetime("2004-01-02 12:34:56");
	isa_ok($time, 'Time::Piece');
	is($time->year, 2004, "year");
	is($time->mon,     1, "month");
	is($time->mday,    2, "day of month");
	is($time->hour,   12, "hour");
	is($time->min,    34, "minutes");
	is($time->sec,    56, "seconds");
}

{
	my $time = Time::Piece->from_mssql_smalldatetime("2004-01-02 21:34:56");
	isa_ok($time, 'Time::Piece');
	is($time->year, 2004, "year");
	is($time->mon,     1, "month");
	is($time->mday,    2, "day of month");
	is($time->hour,   21, "hour");
	is($time->min,    34, "minutes");
	is($time->sec,    56, "seconds");
}

{
	my $time = Time::Piece->from_mssql_smalldatetime("2004-01-02");
	isa_ok($time, 'Time::Piece');
	is($time->year, 2004, "year");
	is($time->mon,     1, "month");
	is($time->mday,    2, "day of month");
	is($time->hour,    0, "hour");
	is($time->min,     0, "minutes");
	is($time->sec,     0, "seconds");
}

{
	my $time = Time::Piece->from_mssql_smalldatetime(undef);
	is($time, undef, 'invalid string returns undef (undef)');
}

{
	my $time = Time::Piece->from_mssql_smalldatetime("2004-01-02 89:34:56");
	is($time, undef, 'invalid string returns undef (out of range)');
}
