#!/usr/bin/env perl -w

use strict;
use Test::Simple tests => 2;
use XML::XMLWriter;

my $doc = new XML::XMLWriter;         # create an object
ok( defined $doc, 'new() returned something' );                # check that we got something
ok( $doc->isa('XML::XMLWriter'), 'it\'s the right class' );     # and it's the right class


