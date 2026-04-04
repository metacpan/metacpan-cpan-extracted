#!/usr/bin/env perl
use v5.20;
use Text::Stencil;

# render_to_fh: stream large output to a file
my $s = Text::Stencil->new(
    header    => "ID,Value\n",
    row       => '{0:int},{1:raw}',
    separator => "\n",
    footer    => "\n",
);

my @rows = map { [$_, "val_$_"] } 1..100;
$s->render_to_fh(\*STDOUT, \@rows);

# render_cb: stream from a callback (e.g. database cursor)
say "\n--- render_cb ---";
my $i = 0;
my $cb = Text::Stencil->new(row => '{0:int}: {1:raw}', separator => "\n");
my $out = $cb->render_cb(sub {
    return undef if $i >= 5;
    $i++;
    return [$i, "row $i"];
});
say $out;
