#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
    if ($ENV{HARNESS_ACTIVE} && $ENV{HARNESS_PERL_SWITCHES} && $ENV{HARNESS_PERL_SWITCHES} =~ /Devel::Cover/) {
        print("1..0 # SKIP Cannot run tests that use threads when Devel::Cover is enabled\n");
        exit(0);
    }
}

use threads;
use Thread::Queue::MaxSize;
use Thread::Semaphore;

if ($] == 5.008) {
    require 't/test.pl';   # Test::More work-alike for Perl 5.8.0
} else {
    require Test::More;
}
Test::More->import();
plan('tests' => 3);

# The following tests locking a queue

my $q = Thread::Queue::MaxSize->new({});
$q->enqueue($_) for (1 .. 10);
ok($q, 'New queue');

my $sm = Thread::Semaphore->new(0);
my $st = Thread::Semaphore->new(0);

threads->create(sub {
    {
        lock($q);
        $sm->up();
        $st->down();
        threads::yield();
        select(undef, undef, undef, 0.1);
        my @x = $q->extract(5,2);
        is_deeply(\@x, [6,7], 'Thread dequeues under lock');
    }
})->detach();

$sm->down();
$st->up();
my @x = $q->dequeue_nb(100);
is_deeply(\@x, [1 .. 5, 8 .. 10], 'Main dequeues');
threads::yield();

