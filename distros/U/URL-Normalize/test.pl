#!/usr/bin/env perl
#
use strict;
use warnings;
use Data::Dumper;
use feature 'say';

use URL::Normalize;

my $normalizer = URL::Normalize->new( 'http://www.example.com/path/page/#anchor1#anchor2/#anchor3' );

$normalizer->remove_dot_segments;

say $normalizer->url;
