#!/usr/bin/env perl
use v5.20;
use Text::Stencil;

my @users = (
    { name => 'Charlie', score => 85,  active => 1 },
    { name => 'Alice',   score => 92,  active => 1 },
    { name => 'Dave',    score => 60,  active => 0 },
    { name => 'Bob',     score => 78,  active => 1 },
    { name => 'Eve',     score => 45,  active => 0 },
);

# skip inactive users, sort by score descending
my $s = Text::Stencil->new(
    header      => " #  | Name    | Score\n" . ('-' x 30) . "\n",
    row         => '{#:pad:2} | {name:rpad:7} | {score:int}',
    separator   => "\n",
    skip_unless => 'active',
);

say "Active users by score (descending):";
say $s->render_sorted(\@users, 'score', { descending => 1, numeric => 1 });

# multi-column sort
say "\nAll users by name, then score:";
my $s2 = Text::Stencil->new(
    row       => '{name:rpad:8} {score:pad:3}',
    separator => "\n",
);
say $s2->render_sorted(\@users, ['name', 'score']);
