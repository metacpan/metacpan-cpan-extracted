#!/usr/bin/perl -w

use strict;

use Test::More tests => 49;

use Time::Clock;

my $t = Time::Clock->new;

#
# Add
#

$t->add(seconds => 1);
is($t->as_string, '00:00:01', 'add 1 second');

$t->parse('00:00:00');
$t->add(nanoseconds => 1);
is($t->as_string, '00:00:00.000000001', 'add 1 nanosecond');

$t->parse('00:00:00');
$t->add(minutes => 1);
is($t->as_string, '00:01:00', 'add 1 minute');

$t->parse('00:00:00');
$t->add(hours => 1);
is($t->as_string, '01:00:00', 'add 1 hour');

# Unit wrap

$t->parse('00:00:00.999999999');
$t->add(nanoseconds => 1);
is($t->as_string, '00:00:01', 'add 1 nanosecond - unit wrap');

$t->parse('00:00:59');
$t->add(seconds => 1);
is($t->as_string, '00:01:00', 'add 1 second - unit wrap');

$t->parse('00:59:00');
$t->add(minutes => 1);
is($t->as_string, '01:00:00', 'add 1 minute - unit wrap');

$t->parse('23:00:00');
$t->add(hours => 1);
is($t->as_string, '00:00:00', 'add 1 hour - unit wrap');

$t->parse('23:59:59.999999999');
$t->add(nanoseconds => 1);
is($t->as_string, '00:00:00', 'add 1 nanosecond - unit wrap 2');

$t->parse('23:59:59');
$t->add(seconds => 1);
is($t->as_string, '00:00:00', 'add 1 second - unit wrap 2');

$t->parse('23:59:00');
$t->add(minutes => 1);
is($t->as_string, '00:00:00', 'add 1 minute - unit wrap 2');

$t->parse('23:00:00');
$t->add(hours => 1);
is($t->as_string, '00:00:00', 'add 1 hour - unit wrap 2');

# Bulk units

$t->parse('12:34:56.789');
$t->add(nanoseconds => 2_000_000_123);
is($t->as_string, '12:34:58.789000123', 'add 2,000,000,123 nanoseconds');

$t->parse('01:02:03');
$t->add(seconds => 3800);
is($t->as_string, '02:05:23', 'add 3,800 seconds');

$t->parse('01:02:03');
$t->add(minutes => 62);
is($t->as_string, '02:04:03', 'add 62 minutes');

$t->parse('01:02:03');
$t->add(hours => 24);
is($t->as_string, '01:02:03', 'add 24 hours');

$t->parse('01:02:03');
$t->add(hours => 25);
is($t->as_string, '02:02:03', 'add 25 hours');

# Mixed units

$t->parse('01:02:03');
$t->add(hours => 3, minutes => 2, seconds => 1, nanoseconds => 54321);
is($t->as_string, '04:04:04.000054321', 'add 03:02:01.000054321');

$t->parse('01:02:03');
$t->add(hours => 125, minutes => 161, seconds => 161, nanoseconds => 1_234_567_890);
is($t->as_string, '08:45:45.23456789', 'add 125:161:162.234567890');

# Strings

$t->parse('01:02:03');
$t->add('03:02:01.000054321');
is($t->as_string, '04:04:04.000054321', 'add 03:02:01.000054321 string');

$t->parse('01:02:03');
$t->add('125:161:162.234567890');
is($t->as_string, '08:45:45.23456789', 'add 125:161:162.234567890 string');

$t->parse('01:02:03');
$t->add('1');
is($t->as_string, '02:02:03', 'add 1 string');

$t->parse('01:02:03');
$t->add('1:2');
is($t->as_string, '02:04:03', 'add 1:2 string');

$t->parse('01:02:03');
$t->add('1:2:3');
is($t->as_string, '02:04:06', 'add 1:2:3 string');

$t->parse('01:02:03');
$t->add('1:2:3.456');
is($t->as_string, '02:04:06.456', 'add 1:2:3.456 string');

eval { $t->add('125:161:162.2345678901x') };
ok($@, 'bad delta string 125:161:162.2345678901');

eval { $t->add(':161:162.2345678901') };
ok($@, 'bad delta string :161:162.2345678901');

#
# Subtract
#

$t->parse('00:00:01');
$t->subtract(seconds => 1);
is($t->as_string, '00:00:00', 'subtract 1 second');

$t->parse('00:00:00.000000001');
$t->subtract(nanoseconds => 1);
is($t->as_string, '00:00:00', 'subtract 1 nanosecond');

$t->parse('00:01:00');
$t->subtract(minutes => 1);
is($t->as_string, '00:00:00', 'subtract 1 minute');

$t->parse('01:00:00');
$t->subtract(hours => 1);
is($t->as_string, '00:00:00', 'subtract 1 hour');

# Unit wrap

$t->parse('00:00:01');
$t->subtract(nanoseconds => 1);
is($t->as_string, '00:00:00.999999999', 'subtract 1 nanosecond - unit wrap');

$t->parse('00:01:00');
$t->subtract(seconds => 1);
is($t->as_string, '00:00:59', 'subtract 1 second - unit wrap');

$t->parse('01:00:00');
$t->subtract(minutes => 1);
is($t->as_string, '00:59:00', 'subtract 1 minute - unit wrap');

$t->parse('00:00:00');
$t->subtract(hours => 1);
is($t->as_string, '23:00:00', 'subtract 1 hour - unit wrap');

$t->parse('00:00:00');
$t->subtract(nanoseconds => 1);
is($t->as_string, '23:59:59.999999999', 'subtract 1 nanosecond - unit wrap 2');

$t->parse('00:00:00');
$t->subtract(seconds => 1);
is($t->as_string, '23:59:59', 'subtract 1 second - unit wrap 2');

$t->parse('00:00:00');
$t->subtract(minutes => 1);
is($t->as_string, '23:59:00', 'subtract 1 minute - unit wrap 2');

$t->parse('00:00:00');
$t->subtract(hours => 1);
is($t->as_string, '23:00:00', 'subtract 1 hour - unit wrap 2');

# Bulk units

$t->parse('12:34:58.789000123');
$t->subtract(nanoseconds => 2_000_000_123);
is($t->as_string, '12:34:56.789', 'subtract 2,000,000,123 nanoseconds');

$t->parse('02:05:23');
$t->subtract(seconds => 3800);
is($t->as_string, '01:02:03', 'subtract 3,800 seconds');

$t->parse('02:04:03');
$t->subtract(minutes => 62);
is($t->as_string, '01:02:03', 'subtract 62 minutes');

$t->parse('01:02:03');
$t->subtract(hours => 24);
is($t->as_string, '01:02:03', 'subtract 24 hours');

$t->parse('02:02:03');
$t->subtract(hours => 25);
is($t->as_string, '01:02:03', 'subtract 25 hours');

# Mixed units

$t->parse('04:04:04.000054321');
$t->subtract(hours => 3, minutes => 2, seconds => 1, nanoseconds => 54321);
is($t->as_string, '01:02:03', 'subtract 03:02:01.000054321');

$t->parse('08:45:45.234567890');
$t->subtract(hours => 125, minutes => 161, seconds => 161, nanoseconds => 1_234_567_890);
is($t->as_string, '01:02:03', 'subtract 125:161:162.234567890');

$t->parse('08:45:45.234567890');
for(1 .. 125) { $t->subtract(hours => 1) }
for(1 .. 161) { $t->subtract(minutes => 1) }
for(1 .. 161) { $t->subtract(seconds => 1) }
is($t->as_string, '01:02:04.23456789', 'subtract 125:161:161 by 1s');

$t->parse('08:45:45.234567890');
$t->subtract(nanoseconds => 1_234_567_890);
is($t->as_string, '08:45:44', 'subtract 0.234567890');

$t->parse('24:00');
$t->subtract(hours => 3, minutes => 2, seconds => 1, nanoseconds => 54321);
is($t->as_string, '20:57:58.999945679', 'subtract 03:02:01.000054321');
