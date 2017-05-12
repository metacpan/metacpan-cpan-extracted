#!/usr/bin/env perl
use 5.12.1;

use Git::Repository;
use Test::More;

unless (Git::Repository->version_ge('1.7.2')) {
    diag "With git versions less than 1.7.2, diffs will not work.\n";
}

pass;
done_testing;
