#!/usr/bin/perl -w

use strict;

use Test::More tests => 33;

use Time::Clock;

eval { require Time::HiRes };
our $Have_HiRes_Time = $@ ? 0 : 1;

my $t = Time::Clock->new;

ok($t->parse('12:34:56.123456789'), 'parse 12:34:56.123456789');
is($t->as_string, '12:34:56.123456789', 'check 12:34:56.123456789');

ok($t->parse('12:34:56.123456789 pm'), 'parse 12:34:56.123456789 pm');
is($t->as_string, '12:34:56.123456789', 'check 12:34:56.123456789 pm');

ok($t->parse('12:34:56. A.m.'), 'parse 12:34:56. A.m.');
is($t->as_string, '00:34:56', 'check 12:34:56 am');

ok($t->parse('12:34:56 pm'), 'parse 12:34:56 pm');
is($t->as_string, '12:34:56', 'check 12:34:56 pm');

ok($t->parse('2:34:56 pm'), 'parse 2:34:56 pm');
is($t->as_string, '14:34:56', 'check 14:34:56 pm');

ok($t->parse('2:34 pm'), 'parse 2:34 pm');
is($t->as_string, '14:34:00', 'check 2:34 pm');

ok($t->parse('2 pm'), 'parse 2 pm');
is($t->as_string, '14:00:00', 'check 2 pm');

ok($t->parse('3pm'), 'parse 3pm');
is($t->as_string, '15:00:00', 'check 3pm');

ok($t->parse('4 p.M.'), 'parse 4 p.M.');
is($t->as_string, '16:00:00', 'check 4 p.M.');

ok($t->parse('24:00:00'), 'parse 24:00:00');
is($t->as_string, '24:00:00', 'check 24:00:00');

ok($t->parse('24:00:00 PM'), 'parse 24:00:00 PM');
is($t->as_string, '24:00:00', 'check 24:00:00 PM');

ok($t->parse('24:00'), 'parse 24:00');
is($t->as_string, '24:00:00', 'check 24:00');

eval { $t->parse('24:00:00.000000001') };
ok($@ =~ /only allowed if/,  'parse fail 24:00:00.000000001');

eval { $t->parse('24:00:01') };
ok($@ =~ /only allowed if/,  'parse fail 24:00:01');

eval { $t->parse('24:01') };
ok($@ =~ /only allowed if/,  'parse fail 24:01');

ok(eval { $t->parse('7:41:50.1272602510') }, 'extended fractional seconds');

if($Have_HiRes_Time)
{
  ok($t->parse('now'), 'parse now hires');
  ok($t->as_string =~ /^\d\d:\d\d:\d\d\.\d+$/, 'now hires');

  local $Time::Clock::Have_HiRes_Time = 0;
  ok($t->parse('now'), 'parse now lowres');
  ok($t->as_string =~ /^\d\d:\d\d:\d\d$/, 'check now lowres');
}
else
{
  ok($t->parse('now'), 'parse now hires (skipped) 1');
  ok($t->as_string =~ /^\d\d:\d\d:\d\d$/, 'now hires (skipped) 2');
  SKIP: { skip('parse now lowres', 2) }
}

$t = Time::Clock->new->parse('12:34:56.123456789');

is($t->format('%H %k %I %i %M %S %N %n %p %P %T'), '12 12 12 12 34 56 123456789 .123456789 PM pm 12:34:56', 'new->parse');
