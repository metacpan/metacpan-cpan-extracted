#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;

BEGIN { 
    use_ok('fp');
    use_ok('fp::functionals');
}

ok disjoin(sub { true }, sub { false })->(), '... disjoins properly';
ok !conjoin(sub { true }, sub { false })->(), '... conjoins properly';

defun defun_test => always 1;

ok defined &defun_test, '... defun worked';
cmp_ok defun_test(), '==', 1, '... always worked as well';

defun combine_list => disjoin(conjoin (\&is_alpha, \&concat), conjoin(\&is_digit, \&sum));

ok defined &combine_list, '... defun worked again';
cmp_ok combine_list(range 1, 5), '==', 15, '... disjoin and conjoin together worked';
is combine_list(range 'a', 'g'), 'abcdefg', '... disjoin and conjoin together worked again';

defun filter_even => curry(\&filter, \&is_even);

ok defined &filter_even, '... defun worked again';
is_deeply [ filter_even(range 1, 10) ], [ 2, 4, 6, 8, 10 ], '... curry worked';

defun filter_one_through_ten => rcurry(\&filter, range(1, 10));

ok defined &filter_one_through_ten, '... defun worked again';
is_deeply [ filter_one_through_ten(\&is_odd) ], [ 1, 3, 5, 7, 9 ], '... rcurry worked';

defun add_ten_to_range => simple_compose(\&range, curry(\&apply, curry(function { ((first @_) + (second @_)) }, 10)));

ok defined &add_ten_to_range, '... defun worked again';
is_deeply [ add_ten_to_range(1, 5) ], [ 11, 12, 13, 14, 15 ], '... simple compose and a funky curry work well';

defun add_to_sum_of_one_through_five => compose(apply(curry(\&curry, sub { (first @_) + (second @_) }), range(1, 5)));

cmp_ok add_to_sum_of_one_through_five(10), '==', 25, '... composing is crazzzzyyyy';

                    