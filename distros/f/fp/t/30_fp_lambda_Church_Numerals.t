#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 30;

use_ok('fp::lambda');
use_ok('fp::lambda::utils');

cmp_ok(is_zero(\&zero), '==', \&TRUE, 'is_zero 0 == TRUE');
cmp_ok(is_zero(\&one),  '!=', \&TRUE, 'is_zero 1 != TRUE');

cmp_ok(church_numeral_to_int(\&zero),  '==', 0, 'zero == 0');
cmp_ok(church_numeral_to_int(\&one),   '==', 1, 'one == 1');
cmp_ok(church_numeral_to_int(\&two),   '==', 2, 'two == 2');
cmp_ok(church_numeral_to_int(\&three), '==', 3, 'three == 3');
cmp_ok(church_numeral_to_int(\&four),  '==', 4, 'four == 4');
cmp_ok(church_numeral_to_int(\&five),  '==', 5, 'five == 5');
cmp_ok(church_numeral_to_int(\&six),   '==', 6, 'six == 6');
cmp_ok(church_numeral_to_int(\&seven), '==', 7, 'seven == 7');
cmp_ok(church_numeral_to_int(\&eight), '==', 8, 'eight == 8');
cmp_ok(church_numeral_to_int(\&nine),  '==', 9, 'nine == 9');
cmp_ok(church_numeral_to_int(\&ten),   '==', 10, 'ten == 10');

ok(is_equal(\&ten)->(\&ten), '... is_equal 10 10');
ok(is_equal(\&ten)->(succ(\&nine)), '... is_equal 10 (succ 9)');
ok(is_equal(\&ten)->(plus(\&five)->(\&five)), '... is_equal 10 (plus 5 5)');
ok(is_equal(\&two)->(pred(\&three)), '... is_equal 2 (pred 3)');
ok(is_equal(\&two)->(subtract(\&ten)->(\&eight)), '... is_equal 2 (subtract 10 8)');

cmp_ok(church_numeral_to_int(succ(\&ten)), '==', 11, 'succ 10 == 11');
cmp_ok(church_numeral_to_int(succ(succ(\&ten))), '==', 12, 'succ succ 10 == 12');

cmp_ok(church_numeral_to_int(pred(\&ten)), '==', 9, 'pred 10 == 9');
cmp_ok(church_numeral_to_int(pred(\&five)), '==', 4, 'pred 5 == 4');

cmp_ok(church_numeral_to_int(plus(\&two)->(\&two)), '==', 4, 'plus two two == 4');
cmp_ok(church_numeral_to_int(plus(\&ten)->(\&seven)), '==', 17, 'plus ten seven == 17');

cmp_ok(church_numeral_to_int(subtract(\&two)->(\&two)), '==', 0, 'subtract two two == 0');
cmp_ok(church_numeral_to_int(subtract(\&ten)->(\&seven)), '==', 3, 'subtract ten seven == 3');

cmp_ok(church_numeral_to_int(multiply(\&five)->(\&two)), '==', 10, 'multiply five two == 10');
cmp_ok(church_numeral_to_int(multiply(\&ten)->(\&five)), '==', 50, 'multiply ten five == 50');
