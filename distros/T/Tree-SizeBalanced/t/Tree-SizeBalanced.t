# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Tree-SizeBalanced.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 978;
BEGIN { use_ok('Tree::SizeBalanced', ':all') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

{
    my $tree = sbtreei;

    for(1..20) {
        $tree->insert($_);
        my @check = $tree->check;
        is_deeply([$tree->check], [1,1,1]);
        is($tree->size, $_);
    }

    for(reverse(1..20)) {
        $tree->insert($_);
        is_deeply([$tree->check], [1,1,1]);
    }

    $tree->dump;
    for(0..39) {
        is($tree->skip_l($_), int($_/2+1), "skip_l $_");
        is($tree->skip_g($_), int((39-$_)/2+1), "skip_g $_");
    }

    for(1..20) {
        is($tree->count_lt($_), ($_ - 1) * 2);
        is($tree->count_gt($_), (20 - $_) * 2);
        is($tree->count_le($_), $_ * 2);
        is($tree->count_ge($_), (21 - $_) * 2);
    }
    is($tree->find_max, 20);
    is($tree->find_min, 1);
    is($tree->find_lt(1), undef);
    is($tree->find_gt(20), undef);
    is($tree->find_le(0), undef);
    is($tree->find_ge(21), undef);
    is($tree->find(0), undef);
    is($tree->find(21), undef);
    for(2..19) {
        is($tree->find_lt($_), $_-1);
        is($tree->find_gt($_), $_+1);
        is($tree->find_le($_), $_);
        is($tree->find_ge($_), $_);
        is($tree->find($_), $_);
    }
    is($tree->find_le(999), 20);
    is($tree->find_ge(-10), 1);

    for(1..20) {
        $tree->delete($_);
        is_deeply([$tree->check], [1,1,1]);
        is($tree->find($_), $_, "delete $_ once");
    }
    for(1..20) {
        $tree->delete($_);
        is_deeply([$tree->check], [1,1,1]);
        is($tree->find($_), undef, "deleted $_ twice");
    }
}

{
    my $tree = sbtreen;

    for(1..20) {
        $tree->insert($_ / 2);
        my @check = $tree->check;
        is_deeply([$tree->check], [1,1,1]);
        is($tree->size, $_);
    }

    for(reverse(1..20)) {
        $tree->insert($_ / 2);
        is_deeply([$tree->check], [1,1,1]);
    }

    for(0..39) {
        is($tree->skip_l($_), int($_/2+1)/2);
        is($tree->skip_g($_), int((39-$_)/2+1)/2);
    }

    for(1..20) {
        is($tree->count_lt($_/2), ($_ - 1) * 2);
        is($tree->count_gt($_/2), (20 - $_) * 2);
        is($tree->count_le($_/2), $_ * 2);
        is($tree->count_ge($_/2), (21 - $_) * 2);
    }
    is($tree->find_max, 10);
    is($tree->find_min, .5);
    is($tree->find_lt(.5), undef);
    is($tree->find_gt(10), undef);
    is($tree->find_le(0), undef);
    is($tree->find_ge(10.5), undef);
    is($tree->find(0), undef);
    is($tree->find(10.5), undef);
    for(2..19) {
        is($tree->find_lt($_/2), ($_-1)/2);
        is($tree->find_gt($_/2), ($_+1)/2);
        is($tree->find_le($_/2), $_/2);
        is($tree->find_ge($_/2), $_/2);
        is($tree->find($_/2), $_/2);
    }
    is($tree->find_le(999), 10);
    is($tree->find_ge(-10), .5);

    for(1..20) {
        $tree->delete($_/2);
        is_deeply([$tree->check], [1,1,1]);
        is($tree->find($_/2), $_/2, "delete $_/2 once");
    }
    for(1..20) {
        $tree->delete($_/2);
        is_deeply([$tree->check], [1,1,1]);
        is($tree->find($_/2), undef, "deleted $_/2 twice");
    }
}

{
    my $tree = Tree::SizeBalanced::int_int->new;
    for(1..10) {
        $tree->insert($_*2, 10-$_);
    }
    for(1..10) {
        my($found, $value) = $tree->find($_*2);
        is($found, $_*2);
        is($value, 10-$_);
    }
    for(1..10) {
        my($found, $value) = $tree->find_lt($_*2+1);
        is($found, $_*2);
        is($value, 10-$_);
    }
    for(1..10) {
        my $found = $tree->find_lt($_*2+1);
        is($found, $_*2);
    }
}

{
    my $tree = Tree::SizeBalanced->new;
    for(1..10) {
        $tree->insert($_*2, 10-$_);
    }
    for(1..10) {
        my($found, $value) = $tree->find($_*2);
        is($found, $_*2);
        is($value, 10-$_);
    }
    for(1..10) {
        my($found, $value) = $tree->find_lt($_*2+1);
        is($found, $_*2);
        is($value, 10-$_);
    }
}

{
    my $tree = sbtreeia;
    for(1..10) {
        $tree->insert($_, 'a'.$_);
    }
    for(1..10) {
        my($found, $value) = $tree->find($_);
        is($found, $_);
        is($value, 'a'.$_);
    }
}

{
    my $tree = sbtreesa;
    for('a'..'g') {
        $tree->insert($_, 'x'.$_);
    }
    for('a'..'g') {
        my($found, $value) = $tree->find($_);
        is($found, $_);
        is($value, 'x'.$_);
    }
    is($tree->count_lt('f'), 5);
    is($tree->count_le('f'), 6);
    is($tree->count_gt('f'), 1);
    is($tree->count_ge('f'), 2);
    is_deeply([$tree->find_lt('a')], []);
    is_deeply([$tree->find_lt('c')], ['b', 'xb']);
}

{
    my $tree = sbtreea { length($b) <=> length($a) };
    for(1..9) {
        $tree->insert('x' x $_);
    }
    for(1..9) {
        is($tree->count_lt('o' x $_), 9-$_);
    }
}

{
    my $tree = sbtreea { length($a) <=> length($b) };
    for(1..3) {
        $tree->insert('c' x $_);
        $tree->insert_after('a' x $_);
        $tree->insert_before('b' x $_);
    }
    is(join(' ', $tree->find_min(-1)), 'b c a bb cc aa bbb ccc aaa');
    is(join(' ', $tree->find_max(-1)), 'aaa ccc bbb aa cc bb a c b');
    is(join(' ', $tree->find_min(4)), 'b c a bb');
    is(join(' ', $tree->find_max(4)), 'aaa ccc bbb aa');

    is(join(' ', $tree->find_first('xx', -1)), 'bb cc aa');
    is(join(' ', $tree->find_last('xx', -1)), 'aa cc bb');
    is(join(' ', $tree->find_first('xx', 2)), 'bb cc');
    is(join(' ', $tree->find_last('xx', 2)), 'aa cc');

    is(join(' ', $tree->find_gt('xx', -1)), 'bbb ccc aaa');
    is(join(' ', $tree->find_ge('xx', -1)), 'bb cc aa bbb ccc aaa');
    is(join(' ', $tree->find_lt('xx', -1)), 'a c b');
    is(join(' ', $tree->find_le('xx', -1)), 'aa cc bb a c b');
    is(join(' ', $tree->find_gt('xx', 2)), 'bbb ccc');
    is(join(' ', $tree->find_ge('xx', 4)), 'bb cc aa bbb');
    is(join(' ', $tree->find_lt('xx', 2)), 'a c');
    is(join(' ', $tree->find_le('xx', 4)), 'aa cc bb a');

    is(join(' ', $tree->find_gt_lt('x', 'xxx')), 'bb cc aa');
    is(join(' ', $tree->find_gt_le('x', 'xxx')), 'bb cc aa bbb ccc aaa');
    is(join(' ', $tree->find_ge_lt('x', 'xxx')), 'b c a bb cc aa');
    is(join(' ', $tree->find_ge_le('x', 'xxx')), 'b c a bb cc aa bbb ccc aaa');

    is(join(' ', $tree->skip_l(5, -1)), 'aa bbb ccc aaa');
    is(join(' ', $tree->skip_l(5, 3)), 'aa bbb ccc');
    is(join(' ', $tree->skip_g(5, -1)), 'bb a c b');
    is(join(' ', $tree->skip_g(5, 3)), 'bb a c');

    $tree->delete_first('xx');
    is(join(' ', $tree->find_min(-1)), 'b c a cc aa bbb ccc aaa');

    $tree->delete_last('xx');
    is(join(' ', $tree->find_min(-1)), 'b c a cc bbb ccc aaa');
}

{
    my $tree = sbtreeia;
    $tree->insert(5, 'x');
    $tree->insert(3, 24);
    $tree->insert(3, 'y');
    is(join(' ', $tree->find_min(-1)), '3 24 3 y 5 x');
    is(join(' ', $tree->find_max(-1)), '5 x 3 y 3 24');
    is(join(' ', $tree->skip_g(1, -1)), '3 y 3 24');
    is(join(' ', $tree->skip_l(1, -1)), '3 y 5 x');
    is(join(' ', $tree->find_lt(4, -1)), '3 y 3 24');
    is(join(' ', $tree->find_le(4, -1)), '3 y 3 24');
    is(join(' ', $tree->find_gt(4, -1)), '5 x');
    is(join(' ', $tree->find_ge(4, -1)), '5 x');
    is(join(' ', $tree->find_gt_lt(3, 5)), '');
    is(join(' ', $tree->find_gt_le(3, 5)), '5 x');
    is(join(' ', $tree->find_ge_lt(3, 5)), '3 24 3 y');
    is(join(' ', $tree->find_ge_le(3, 5)), '3 24 3 y 5 x');
}
