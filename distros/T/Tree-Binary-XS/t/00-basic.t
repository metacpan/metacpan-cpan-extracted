# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Tree::Binary.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 24;
BEGIN { use_ok('Tree::Binary::XS') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $tree = Tree::Binary::XS->new({ by_key => 'id' });
ok($tree);

my $options = $tree->options();
ok($options);
is('HASH', ref $options);

my $ret;

$ret = $tree->insert({ id => 10, 'name' => 'Bob' });
ok($ret, 'normal insert');

ok $ret->exists(10);
ok $ret->exists({ id => 10, 'name' => 'Bob' });
ok !$ret->exists(99);

my $n;
$n = $tree->search(10);
is('Bob', $n->{name});
is(10, $n->{id});


$ret = $tree->insert({ id => 8, 'name' => 'John' });
ok($ret, 'normal insert');

$ret = $tree->update({ id => 8, 'name' => 'Johnson' });
ok($ret, 'normal update');


$n = $tree->search(8);
is('Johnson', $n->{name});
is(8, $n->{id});


$ret = $tree->insert({ id => 12, 'name' => 'Connie' });
ok($ret, 'normal insert');

$ret = $tree->delete(12);
ok($ret, 'delete successfully @ 12');

$ret = $tree->delete(12);
ok(!$ret, 'inexistent key deletion');

$ret = $tree->delete(99);
ok(!$ret, 'inexistent key deletion');

ok $tree->insert({ id => 13, 'name' => 'Wendy' }), "insert Wendy @ 13";
ok $tree->insert({ id => 12, 'name' => 'Samma' }), "insert Samma @ 12";
ok $tree->insert({ id => 3, 'name' => 'Amy' }), "insert Amy @ 3";
$tree->delete(13);
$tree->delete(13, 12, 3);

ok !$tree->search(13), 'key 13 is deleted';
ok !$tree->search(12), 'key 12 is deleted';
ok !$tree->search(3), 'key 3 is deleted';

my @keys = ();
$tree->preorder_traverse(sub { 
        my ($key, $node) = @_;
        use Data::Dumper; warn Dumper( $key, $node );
    });
# $tree->dump();


