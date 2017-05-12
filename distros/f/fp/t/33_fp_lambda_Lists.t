#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 42;

use_ok('fp::lambda');
use_ok('fp::lambda::utils');

cmp_ok(head(cons(\&one)->(\&NIL)), '==', \&one, "head cons 1 NIL == 1");
cmp_ok(tail(cons(\&one)->(\&NIL)), '==', \&NIL, "tail cons 1 NIL == NIL");

cmp_ok(head(cons(\&two)->(cons(\&one)->(\&NIL))), '==', \&two, "head(cons 2 (cons 1 NIL)) == 2");
cmp_ok(head(tail(cons(\&two)->(cons(\&one)->(\&NIL)))), '==', \&one, "head(tail(cons 2 (cons 1 NIL))) == 1");

cmp_ok(is_NIL(tail(tail(cons(\&two)->(cons(\&one)->(\&NIL))))), '==', \&TRUE, "is_NIL(tail(tail(cons 2 (cons 1 NIL)))) == TRUE");
cmp_ok(is_not_NIL(tail(cons(\&two)->(cons(\&one)->(\&NIL)))), '==', \&TRUE, "is_not_NIL(head(tail(cons 2 (cons 1 NIL)))) == TRUE");

cmp_ok(size(\&NIL), '==', \&zero, "size NIL == zero");
cmp_ok(church_numeral_to_int(size(cons(\&five)->(cons(\&four)->(cons(\&two)->(cons(\&NIL)->(\&NIL)))))), '==', 4, 
    'size cons 5 cons 4 cons 2 cons 2 cons NIL == 4');

my $one_through_five = cons(\&one)->(cons(\&two)->(cons(\&three)->(cons(\&four)->(cons(\&five)->(\&NIL)))));

cmp_ok(church_numeral_to_int(head($one_through_five)), '==', 1, 'head 1 .. 5 == 1');
cmp_ok(church_numeral_to_int(head(tail($one_through_five))), '==', 2, 'head tail 1 .. 5 == 2');
cmp_ok(church_numeral_to_int(head(tail(tail($one_through_five)))), '==', 3, 'head tail tail 1 .. 5 == 3');
cmp_ok(church_numeral_to_int(head(tail(tail(tail($one_through_five))))), '==', 4, 'head tail tail tail 1 .. 5 == 4');
cmp_ok(church_numeral_to_int(head(tail(tail(tail(tail($one_through_five)))))), '==', 5, 'head tail tail tail tail 1 .. 5 == 5');
ok(is_NIL(head(tail(tail(tail(tail(tail($one_through_five))))))), 'is_NIL head tail tail tail tail tail 1 .. 5');

ok(is_equal(size($one_through_five))->(\&five), "is_equal (size (1 .. 5)) 5");
cmp_ok(church_numeral_to_int(sum($one_through_five)), '==', 15, "sum (1 .. 5) == 15");

my $reversed_one_through_five = rev($one_through_five);
cmp_ok(church_numeral_to_int(head($reversed_one_through_five)), '==', 5, 'head reverse 1 .. 5 == 1');
cmp_ok(church_numeral_to_int(head(tail($reversed_one_through_five))), '==', 4, 'head tail reverse  1 .. 5 == 2');
cmp_ok(church_numeral_to_int(head(tail(tail($reversed_one_through_five)))), '==', 3, 'head tail tail reverse  1 .. 5 == 3');
cmp_ok(church_numeral_to_int(head(tail(tail(tail($reversed_one_through_five))))), '==', 2, 'head tail tail tail reverse  1 .. 5 == 4');
cmp_ok(church_numeral_to_int(head(tail(tail(tail(tail($reversed_one_through_five)))))), '==', 1, 'head tail tail tail tail reverse  1 .. 5 == 5');
ok(is_NIL(head(tail(tail(tail(tail(tail($reversed_one_through_five))))))), 'is_NIL head tail tail tail tail tail reverse 1 .. 5');

my $appended_to = cons(\&one)->(\&NIL);

cmp_ok(church_numeral_to_int(head($appended_to)), '==', 1, 'head [1] == 1');

$appended_to = append($appended_to)->(cons(\&two)->(\&NIL));

cmp_ok(church_numeral_to_int(head($appended_to)), '==', 1, 'head [1 2] == 1');
cmp_ok(church_numeral_to_int(head(tail($appended_to))), '==', 2, 'head tail [1 2] == 2');

$appended_to = append($appended_to)->(cons(\&three)->(\&NIL));

cmp_ok(church_numeral_to_int(head($appended_to)), '==', 1, 'head [1 2 3] == 1');
cmp_ok(church_numeral_to_int(head(tail($appended_to))), '==', 2, 'head tail [1 2 3] == 2');
cmp_ok(church_numeral_to_int(head(tail(tail($appended_to)))), '==', 3, 'head tail tail [1 2 3] == 3');

cmp_ok(church_numeral_to_int(nth(\&zero)->($reversed_one_through_five)), '==', 5, 'nth 0 [5 4 3 2 1] == 5');
cmp_ok(church_numeral_to_int(nth(\&one)->($reversed_one_through_five)), '==', 4, 'nth 1 [5 4 3 2 1] == 4');
cmp_ok(church_numeral_to_int(nth(\&two)->($reversed_one_through_five)), '==', 3, 'nth 2 [5 4 3 2 1] == 3');
cmp_ok(church_numeral_to_int(nth(\&three)->($reversed_one_through_five)), '==', 2, 'nth 3 [5 4 3 2 1] == 2');
cmp_ok(church_numeral_to_int(nth(\&four)->($reversed_one_through_five)), '==', 1, 'nth 4 [5 4 3 2 1] == 1');
ok(is_NIL(nth(\&five)->($reversed_one_through_five)),, 'nth 5 [5 4 3 2 1] == NIL');

my $mapped_list = apply(sub { my $x = shift; multiply($x)->(\&ten) })->($reversed_one_through_five);

cmp_ok(church_numeral_to_int(nth(\&zero)->($mapped_list)), '==', 50, 'nth 0 map ( x * 10 ) [5 4 3 2 1] == 5');
cmp_ok(church_numeral_to_int(nth(\&one)->($mapped_list)), '==', 40, 'nth 1 map ( x * 10 ) [5 4 3 2 1] == 4');
cmp_ok(church_numeral_to_int(nth(\&two)->($mapped_list)), '==', 30, 'nth 2 map ( x * 10 ) [5 4 3 2 1] == 3');
cmp_ok(church_numeral_to_int(nth(\&three)->($mapped_list)), '==', 20, 'nth 3 map ( x * 10 ) [5 4 3 2 1] == 2');
cmp_ok(church_numeral_to_int(nth(\&four)->($mapped_list)), '==', 10, 'nth 4 map ( x * 10 ) [5 4 3 2 1] == 1');
ok(is_NIL(nth(\&five)->($mapped_list)),, 'nth 5 map ( x * 10 ) [5 4 3 2 1] == NIL');
