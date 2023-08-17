#!/usr/bin/perl

# Dumps PSGI environment

use strict;
use warnings;

use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

sub {
    my $dump = Dumper @_;

    return [200, ["Content-Type" => "text/plain", "Content-Length" => length($dump)], [$dump]];
};
