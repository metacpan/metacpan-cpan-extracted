#!/usr/bin/env perl

use strict;
use warnings;

use File::Slurp;
use JSON::Syck;
use YAML;

my $infile = shift or die "No input .json file specified.\n";
my $json = read_file($infile);
my $data = JSON::Syck::Load($json);
print YAML::Dump($data);


