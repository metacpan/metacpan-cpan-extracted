# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BinaryTree-Dictionary.t'
#########################
use strict;
use Data::Dumper;
use Test::More tests => 26 ;

#
# Class Tests 1,2

BEGIN { use_ok('Tree::Binary::Dictionary') };
can_ok('Tree::Binary::Dictionary', qw(new keys values to_hash delete add exists get));


#
# Object tests 3 - 23

# construction
my $dictionary = Tree::Binary::Dictionary->new;
isa_ok($dictionary, 'Tree::Binary::Dictionary');

# populate
ok($dictionary->add(aaaa => "One"), 'added object');
$dictionary->add(cccc => "Three");
$dictionary->add(dddd => "Four");
$dictionary->add(eeee => "Five");
$dictionary->add(foo => "Foo");
$dictionary->add(bar => "quuz");

# interact
ok($dictionary->exists('bar'), 'expected value exists');
ok(!$dictionary->exists('homer'), 'expected value does not exist');

ok($dictionary->count == 6, 'count is correct');

ok($dictionary->delete('cccc'), 'deletes value ok');
ok(!$dictionary->delete('cccc'), 'returns false when deleting non-existant value');

ok($dictionary->get('bar'), 'can get value from valid key');
ok(!$dictionary->get('cccc'), 'returns false when getting non-existant value');

ok($dictionary->count == 5, 'count is correct');

ok(!$dictionary->add('bar' => 'quuuz'), 'adding duplicate key returns false');

ok($dictionary->count == 5, 'count is still correct');

$dictionary->set('bar' => 'quuuz');

ok($dictionary->count == 5, 'count is still correct');

$dictionary->set('qwerty' => 'quuuz');

ok($dictionary->count == 6, 'count is still correct');

$dictionary->delete('qwerty');

ok($dictionary->rebuild(), 'rebuilt binary tree');

ok($dictionary->get('aaaa') eq 'One','rebuilt tree contains old keys/values');

ok($dictionary->count == 5, 'count is still correct');

# vistor / hash
my %hash = $dictionary->to_hash;
my @values = $dictionary->values;
my @keys = $dictionary->keys;
ok(eq_hash({
	    'aaaa' => 'One',
	    'foo' => "Foo",
	    'bar' => 'quuuz',
	    'dddd' => 'Four',
	    'eeee' => 'Five',
	   }, \%hash),'Hash exports ok');
ok(eq_array([qw/One quuuz Four Five Foo/], \@values),'values works ok');
ok(eq_array([qw/aaaa bar dddd eeee foo/], \@keys),'keys works ok');

$dictionary->add(homer => "simpson");
$dictionary->add(bart => "simpson");
$dictionary->delete('foo');
%hash = $dictionary->to_hash;
@values = $dictionary->values;
@keys = $dictionary->keys;
ok(eq_hash({
	    'aaaa' => 'One',
	    'bar' => 'quuuz',
	    'bart' => 'simpson',
	    'dddd' => 'Four',
	    'eeee' => 'Five',
	    'homer' => 'simpson',
	   }, \%hash));
ok(eq_array([qw/One quuuz simpson Four Five simpson/], \@values));
ok(eq_array([qw/aaaa bar bart dddd eeee homer/], \@keys));


#
# references 17

my $little_hash = { a => 1};
$dictionary->add('little_hash' => $little_hash);
ok($dictionary->get('little_hash')->{a} == 1, 'can get and set references as values');
