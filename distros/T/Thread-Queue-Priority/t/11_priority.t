#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More 'tests' => 15;

use Thread::Queue::Priority;

my $q = Thread::Queue::Priority->new();
ok($q, 'New queue');

# add some things to it
$q->enqueue(1);
is($q->peek(), 1);
$q->enqueue(2, 50);
is($q->peek(), 1);
$q->enqueue(3, 1);
is($q->peek(0), 3);
is($q->peek(1), 1);
is($q->peek(2), 2);
$q->enqueue(4, 99);
is($q->peek(0), 3);
is($q->peek(1), 1);
is($q->peek(2), 2);
is($q->peek(3), 4);
$q->enqueue(5, 98);
is($q->peek(0), 3);
is($q->peek(1), 1);
is($q->peek(2), 2);
is($q->peek(3), 5);
is($q->peek(4), 4);

