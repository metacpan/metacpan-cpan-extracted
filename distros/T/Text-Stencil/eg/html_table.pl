#!/usr/bin/env perl
use v5.20;
use Text::Stencil;

my $s = Text::Stencil->new(
    header    => '<table><tr><th>ID</th><th>Name</th><th>Score</th></tr>',
    row       => '<tr><td>{0:int}</td><td>{1:html}</td><td>{2:float:1}</td></tr>',
    footer    => '</table>',
    separator => "\n",
);

my @rows = (
    [1, 'Alice & Bob',    95.5],
    [2, '<script>Eve</script>', 87.3],
    [3, 'Charlie "C"',    92.1],
);

say $s->render(\@rows);
