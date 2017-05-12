#!/usr/bin/env perl -w

use strict;
use Test::Simple tests => 2;
use XML::ParseDTD;

my $dtd = new XML::ParseDTD('http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd');         # create an object
ok( defined $dtd, 'new() returned something' );                # check that we got something
ok( $dtd->isa('XML::ParseDTD'), 'it\'s the right class' );     # and it's the right class


