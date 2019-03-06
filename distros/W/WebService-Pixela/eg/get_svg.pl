#!/usr/bin/env perl
use strict;
use warnings;

use WebService::Pixela;

my $pixela = WebService::Pixela->new(token => $ENV{TOKEN}, username => $ENV{USER_NAME});

print $pixela->graph->id($ENV{GRAPH_ID})->get_svg();

__END__

This module use
    $perl get_svg.pl > graph.svg
