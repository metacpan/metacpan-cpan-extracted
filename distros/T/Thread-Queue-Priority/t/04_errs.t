#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Thread::Queue::Priority;

use Test::More 'tests' => 14;

my $q = Thread::Queue::Priority->new();
$q->enqueue($_) for (1 .. 10);
ok($q, 'New queue');

eval { $q->dequeue(undef); };
like($@, qr/Invalid 'count'/, $@);
eval { $q->dequeue(0); };
like($@, qr/Invalid 'count'/, $@);
eval { $q->dequeue(0.5); };
like($@, qr/Invalid 'count'/, $@);
eval { $q->dequeue(-1); };
like($@, qr/Invalid 'count'/, $@);
eval { $q->dequeue('foo'); };
like($@, qr/Invalid 'count'/, $@);

eval { $q->dequeue_nb(undef); };
like($@, qr/Invalid 'count'/, $@);
eval { $q->dequeue_nb(0); };
like($@, qr/Invalid 'count'/, $@);
eval { $q->dequeue_nb(-0.5); };
like($@, qr/Invalid 'count'/, $@);
eval { $q->dequeue_nb(-1); };
like($@, qr/Invalid 'count'/, $@);
eval { $q->dequeue_nb('foo'); };
like($@, qr/Invalid 'count'/, $@);

eval { $q->peek(undef); };
like($@, qr/Invalid 'index'/, $@);
eval { $q->peek(3.3); };
like($@, qr/Invalid 'index'/, $@);
eval { $q->peek('foo'); };
like($@, qr/Invalid 'index'/, $@);

