#! /usr/bin/env perl

use 5.024;
use warnings;

use Var::Mystic;

my $untracked = 'untracked';
mystic $tracked = 'tracked';

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
