#! /usr/bin/env perl

use 5.014;
use warnings;

use Var::Mystic;

      my $untracked = 'untracked';
track my $tracked = 'tracked';

for (1..5) {
    $untracked++;
    $tracked++;
}

sub foo {
    my ($varref) = @_;
    $$varref = 'foo';
}

foo(\$untracked);
foo(\$tracked);

say $untracked;
say $tracked;
