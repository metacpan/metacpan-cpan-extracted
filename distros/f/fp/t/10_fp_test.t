#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 41;

BEGIN { 
    use_ok('fp');
}

is_deeply [ list(1, 2, 3, 4, 5) ], [ 1 .. 5 ], '... got a list';
cmp_ok    len(list(1, 2, 3, 4, 5)), '==', 5, '... length of a list';
is_deeply [ range(1, 10) ], [ 1 .. 10 ], '... got a numeric range';
is_deeply [ range("f", "m") ], [ 'f' .. 'm' ], '... got an alphabetical range';
cmp_ok    sum(range(1, 10)), '==', 55, '... sum a range';
cmp_ok    product(range(1, 5)), '==', 120, '... product of a range';
is        concat(range("a", "z")), (join "" => ('a' .. 'z')), '... concatenate the alphabet';	
ok        !is_even(5), '... 5 is not even';
ok        is_odd(3), '... 3 is odd';
is_deeply [ explode("this is the end of the world as we know it") ], [ split // => "this is the end of the world as we know it" ], '... splitting a string';
is_deeply [ slice_by(123) ], [ 1, 2, 3 ], '... slice a number';

cmp_ok    nth(3, list(1, 2, 3, 4, 5, 6, 7, 8)), '==', 4, '... get the nth member of the list';
cmp_ok    end(list(1, 2, 3, 4, 5, 6, 7, 8)), '==', 8, '... get the end of the list';
cmp_ok    first(list(1, 2, 3, 4, 5, 6)), '==', 1, '... get the 1st member of the list';
cmp_ok    second(list(1, 2, 3, 4, 5, 6)), '==', 2, '... get the 2nd member of the list';
cmp_ok    third(list(1, 2, 3, 4, 5, 6)), '==', 3, '... get the 3rd member of the list';
cmp_ok    fourth(list(1, 2, 3, 4, 5, 6)), '==', 4, '... get the 4th member of the list';
cmp_ok    fifth(list(1, 2, 3, 4, 5, 6)), '==', 5, '... get the 5th member of the list';
cmp_ok    sixth(list(1, 2, 3, 4, 5, 6)), '==', 6, '... get the 6th member of the list';

ok        !member(8, list(1, 2, 3, 4)), '... 8 is not a member of this list';
is_deeply [ filter(\&is_even, list(1, 2, 3, 4, 5, 6, 7, 8, 9)) ], [ 2, 4, 6, 8 ], '... filter out only the even ones';
ok        !is_empty(list(1, 2)), '... this list is not empty';
is_deeply [ apply(function { $_[0] + 1 }, list(1, 2, 3, 4, 5)) ], [ 2, 3, 4, 5, 6 ], '... adding one to each element in the list';
is_deeply [ prepend(1, range(1, 20)) ], [ 1, 1 .. 20 ], '... prepend a list';
is_deeply [ append(1, range(1, 20)) ], [ 1 .. 20, 1 ], '... append a list';
is_deeply [ combine(range(1, 5), range(10, 15)) ], [ 1 .. 5, 10 .. 15 ], '... combine two lists';
is_deeply [ rev(range(1, 5)) ], [ reverse 1 .. 5 ], '... reverse a list';
is_deeply [ unique(list(1, 3, 2, 4, 6, 1, 5, 3, 4)) ], [ 2, 6, 1, 5, 3, 4 ], '... just the unique elements of the list';
is_deeply [ unique_prepend(1, list(2, 3, 4)) ], [ 1, 2, 3, 4 ], '...';
is_deeply [ unique_append(5, list(2, 3, 4)) ], [ 2, 3, 4, 5 ], '...';
is_deeply [ unique_combine(list(1, 2, 3), list(2, 3, 4)) ], [ 1, 2, 3, 4 ], '...';
is_deeply [ adjoin(list(1, 2, 3, 4), list(9, 3, 1, 4, 5)) ], [ 2, 9, 3, 1, 4, 5 ], '...';
is_deeply [ union(list(1, 2, 3, 4), list(9, 3, 1, 4, 5)) ], [ 2, 9, 3, 1, 4, 5 ], '...';
is_deeply [ intersection(list(1, 3, 4, 2, 5, 8), list(9, 3, 1, 4, 5)) ], [1, 3, 4, 5 ], '...';

ok is_digit(5), '... 5 is a digit';
ok !is_digit('a'), '... a is not a digit';
ok is_whitespace(' '), '... " " is whitespace';
ok !is_whitespace(6), '... 6 is not whitespace';
ok is_alpha('b'), '... b is alpha';
ok !is_alpha(8), '... 8 is not alpha';


