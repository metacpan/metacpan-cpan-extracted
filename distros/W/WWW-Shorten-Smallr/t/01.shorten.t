#!/usr/bin/perl

use Test::More tests => 1;
use WWW::Shorten 'Smallr';

my $short = makeashorterlink(
 'http://cpan.m.flirble.org/authors/id/D/DW/DWILSON/'
);

is($short, 'http://smallr.com/1nz');
