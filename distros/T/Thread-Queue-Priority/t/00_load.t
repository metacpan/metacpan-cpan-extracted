#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More 'tests' => 1;

use_ok('Thread::Queue::Priority');
if ($Thread::Queue::Priority::VERSION) {
    diag('Testing Thread::Queue::Priority ' . $Thread::Queue::Priority::VERSION);
}

