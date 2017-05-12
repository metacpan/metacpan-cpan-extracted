#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use lib '../lib';
use Test::Subroutines qw(load_subs get_subref);

my $i = 5;

load_subs('./src.pl', 'Bar', {system => sub { print "system! @_\n" }});

#my $sub = get_subref('doit');
#$sub->();
&Bar::doit;

