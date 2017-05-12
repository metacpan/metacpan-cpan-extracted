#!/usr/bin/perl

use Test::More tests => 1;

use strict;
use warnings;
use Text::Graph;

my $graph = Text::Graph->new( 'Bar' );
my $got = $graph->to_string(
                [1,2,4,5,10,3,5],
                labels => [ qw/aaaa bb ccc dddddd ee f ghi/ ],
        );
my $expect = <<'EOF';
aaaa   :
bb     :*
ccc    :***
dddddd :****
ee     :*********
f      :**
ghi    :****
EOF

is( $got, $expect, 'to_string on array ref' );
