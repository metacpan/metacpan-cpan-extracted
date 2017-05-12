#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use Text::Amuse::Compile::Fonts::Import;

use Pod::Usage;
use Getopt::Long;

my %options;
GetOptions (\%options, qw/help/);

if ($options{help}) {
    pod2usage();
}

my $file = shift;
Text::Amuse::Compile::Fonts::Import->new(output => $file)->import_and_save;

=encoding utf8

=head1 NAME

muse-create-font-file.pl - Generate a JSON file with font paths

=head1 SYNOPSIS

  muse-create-font-file.pl [ outputfile.json ]

If the argument is not provided, output the JSON to the STDOUT.

=cut
