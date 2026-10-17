#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

sub rt { Time::Keeper::_i64_roundtrip($_[0]) }

is(rt(0), 0, 'zero');
is(rt(-1), -1, 'minus one');
is(rt(1.0), 1, 'a whole number held as a float');
is(rt('42'), 42, 'a string of digits');
is(rt('+42'), 42, 'with a plus sign');
is(rt('-42'), -42, 'with a minus sign');
is(rt('007'), 7, 'with leading zeros');
is(rt('9223372036854775807'), '9223372036854775807', 'the largest 64-bit integer, from a string');
is(rt('-9223372036854775808'), '-9223372036854775808', 'the smallest');
is(rt(~0 >> 1), '9223372036854775807', 'the largest, from an unsigned integer') if ~0 > 4294967295;

is(rt('9223372036854775808'), undef, 'one past the largest is refused');
is(rt('-9223372036854775809'), undef, 'one before the smallest');
is(rt('99999999999999999999'), undef, 'twenty digits');
is(rt(~0), undef, 'the largest unsigned integer') if ~0 > 4294967295;
is(rt(1.5), undef, 'a fraction');
is(rt(1e20), undef, 'a float too large');
is(rt(9**9**9), undef, 'infinity');
is(rt(-9**9**9), undef, 'minus infinity');
is(rt(''), undef, 'an empty string');
is(rt('-'), undef, 'a sign alone');
is(rt('+'), undef, 'a plus alone');
is(rt(' 5'), undef, 'a leading space');
is(rt('5 '), undef, 'a trailing space');
is(rt('1e3'), undef, 'an exponent in a string');
is(rt('1.0'), undef, 'a decimal point in a string');
is(rt('0x10'), undef, 'hex');
is(rt('--5'), undef, 'two signs');
is(rt('1:'), undef, 'a colon, the character after 9');
is(rt('1/'), undef, 'a slash, the character before 0');
is(rt('12a'), undef, 'a letter after digits');
is(rt(undef), undef, 'undef');
is(rt([]), undef, 'a reference');

{
    my $n = 12;
    my $s = "$n";
    is(rt($n), 12, 'a number that has been used as a string');
    my $str = '13';
    my $x = $str + 0;
    is(rt($str), 13, 'a string that has been used as a number');
}

done_testing;
