#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;

use Webservice::Overleaf::API;

my $ol = Webservice::Overleaf::API->new(
    experimental => 1,
    session      => $ENV{OVERLEAF_SESSION},
);

for my $project ($ol->projects->all) {
    say join "\t", $project->id, $project->name;
}
