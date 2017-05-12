# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Thread-Stack.t'

#########################

use Test::More tests => 5;
BEGIN { use_ok('Thread::Stack') };

my $stack = Thread::Stack->new;
ok(defined($stack));

$stack->push("foo");
$stack->push("bar", "baz");
ok($stack->size == 3);

my $val = $stack->pop;
ok($val eq "baz");
ok($stack->size == 2);

# TODO: actually do tests with threads...

#########################
