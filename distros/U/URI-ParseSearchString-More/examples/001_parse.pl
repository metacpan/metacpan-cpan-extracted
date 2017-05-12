#!/usr/bin/perl

use strict;
use warnings;

use lib '../lib';

use URI::ParseSearchString::More;

my $url    = 'http://www.google.ca/search?hl=en&sa=X&oi=spell&resnum=0&ct=result&cd=1&q=vile+richard&spell=1';
my $more   = URI::ParseSearchString::More->new();
my $terms  = $more->se_term( $url );

print "search terms are: $terms\n";
