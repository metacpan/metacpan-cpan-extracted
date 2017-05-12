#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More 'tests' => 1;

use_ok('Thread::Queue::MaxSize');
if ($Thread::Queue::MaxSize::VERSION) {
    diag('Testing Thread::Queue::MaxSize ' . $Thread::Queue::MaxSize::VERSION);
}

