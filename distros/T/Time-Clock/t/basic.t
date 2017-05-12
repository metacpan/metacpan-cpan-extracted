#!/usr/bin/perl -w

use strict;

use Test::More tests => 31;

BEGIN 
{
  use_ok('Time::Clock');
}

my $t = Time::Clock->new;
is(ref($t), 'Time::Clock', 'new()');

$t = Time::Clock->new(hour => 12, minute => 34, second => 56);

is($t->as_string, '12:34:56', 'as_string 1');
is("$t", '12:34:56', 'as_string 2');
is($t->as_integer_seconds, 45296, 'as_integer_seconds 1');
is(Time::Clock->new('00:00:01.12345')->as_integer_seconds, 1, 'as_integer_seconds 2');

$t->nanosecond(123000000);

is("$t", '12:34:56.123', 'as string 3');

$t = Time::Clock->new('01:02:03');
is($t->as_string, '01:02:03', 'as_string 4');

# Hour

is($t->hour(0), 0, 'hour 0');
is($t->hour(23), 23, 'hour 23');

eval { $t->hour(-1) };
ok($@, 'hour -1');

eval { $t->hour(24) };
ok($@, 'hour 24');

# Minute

is($t->minute(0), 0, 'minute 0');
is($t->minute(59), 59, 'minute 59');

eval { $t->minute(-1) };
ok($@, 'minute -1');

eval { $t->minute(60) };
ok($@, 'minute 60');

# Second

is($t->second(0), 0, 'second 0');
is($t->second(59), 59, 'second 59');

eval { $t->second(-1) };
ok($@, 'second -1');

eval { $t->second(60) };
ok($@, 'second 60');

# Nanosecond

is($t->nanosecond(0), 0, 'nanosecond 0');
is($t->nanosecond(999_999_999), 999_999_999, 'nanosecond 999,999,999');

eval { $t->nanosecond(-1) };
ok($@, 'nanosecond -1');

eval { $t->nanosecond(1_000_000_000) };
ok($@, 'nanosecond 1,000,000,000');

# AM/PM

$t->hour(0);
is($t->ampm, 'AM', 'am 1');
$t->hour(11);
is($t->ampm, 'AM', 'am 2');

$t->hour(12);
is($t->ampm, 'PM', 'pm 1');
$t->hour(23);
is($t->ampm, 'PM', 'pm 2');

$t->hour(1);
$t->ampm('pm');

is($t->hour, 13, 'to pm 1');

eval { $t->ampm('am') };
ok($@, 'to am 1');

$t->hour(12);
$t->ampm('am');

is($t->hour, 0, 'to am 2');
