#!perl -T

use Test::More tests => 71;

use Tree::MultiNode;

my $tree   = Tree::MultiNode->new;
my $handle = Tree::MultiNode::Handle->new($tree);
isa_ok($tree, 'Tree::MultiNode');
isa_ok($handle, 'Tree::MultiNode::Handle');

$handle->add_child("a", 1);
$handle->add_child("b", 1);
$handle->add_child("c", 1);

$handle->remove_child(1);
my %pairs = $handle->kv_pairs();

pass("**** [$0] Pairs: " .  join(', ',%pairs));

ok(!defined $pairs{'b'}, "pair b not defined");
ok( defined $pairs{'a'}, "pair a defined");
ok( defined $pairs{'c'}, "pair c defined");

pass("**** testing traverse...");
pass("**** ....t digit formatting...");
$tree   = new Tree::MultiNode();
$handle = new Tree::MultiNode::Handle($tree);
isa_ok($tree, 'Tree::MultiNode');
isa_ok($handle, 'Tree::MultiNode::Handle');

is($handle->set_key('1'),             1,     'set_key');
is($handle->set_value('foo'),         'foo', 'set_value');
is($handle->add_child('1:1','bar'),   undef, '  add_child("1:1", "bar")');
is($handle->down(0),                  1,     '  down(0)');;
is($handle->add_child('1:1:1','baz'), undef, '    add_child("1:1:1", "baz")');
is($handle->add_child('1:1:2','boz'), undef, '    add_child("1:1:1", "boz")');
is($handle->up(),                     1,     '    up');
is($handle->add_child('1:2','qux'),   undef, '  add_child("1:2", "qux")');
is($handle->down(1),                  1,     '  down(1)');
is($handle->add_child('1:2:1','qaz'), undef, '    add_child("1:2:1","qaz")');
is($handle->add_child('1:2:2','qoz'), undef, '    add_child("1:2:2","qoz")');

is($handle->top(), 1, "move to top of tree");
my $count = 0;
$handle->traverse(sub {
    my $h = pop;
    pass(sprintf("**** %sk: %- 5s v: %s", '  ' x $handle->depth, $h->get_data));

    $count++;
    isa_ok($h, 'Tree::MultiNode::Handle');
    is($_[0], 'arg1', "Traverse argument 1 received");
    is($_[1], 'arg2', "Traverse argument 2 received");
    is($_[2], 'arg3', "Traverse argument 3 received");
  },
  'arg1',
  'arg2',
  'arg3'
);


pass("**** Testing select...");
is($handle->top(), 1, "move to top of tree");
pass("**** Children: " . join(', ',$handle->child_keys()));

is($handle->select('1:2'), 1, "Select 1:2") or die("Error, select() failed");

is($handle->down(), 1, "down()");
is($handle->get_value, 'qux', "select(1:2) positioned on the correct child");

is($count, 7, "Traversed 7 nodes");

pass("**** test storing 'zero' as a child key");
is($handle->add_child('zero','fuzz'), undef, 'add_child("zero", "fuzz")');
is($handle->last, 2, 'last() -- TODO: Why is this a 2 return?');
is($handle->down, 1, "down()");
is($handle->get_value, 'fuzz', "down sent us to key with value fuzz");
is($handle->set_key(0), 0, "set_key(0)");
is($handle->get_key, 0, "0 Stores as a key");

#done_testing();
