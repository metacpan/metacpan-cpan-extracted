#!/usr/bin/perl

use strict;
use warnings;

use lib '../lib';
use Text::PRN::Slurp;
use Data::Dumper;

my $file = '../t/data/sample.prn';

my $slurp = Text::PRN::Slurp->new->load(
    'file' => $file,
    'file_headers' => [ q{Name}, q{Address}, q{Postcode}, q{Phone}, q{Credit Limit}, q{Birthday} ]
);

print Dumper $slurp;

my $file2 = '../t/data/sample_2.prn';

my $slurp = Text::PRN::Slurp->new->load(
    'file' => $file2,
    'file_headers' => [ q{ID}, q{Type}, q{Description} ]
);

print Dumper $slurp;