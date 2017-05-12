#!/usr/bin/perl -w

use Test::More 'no_plan';

BEGIN { use_ok( 'XML::Simple' ); }
BEGIN { use_ok( 'Treemap::Input::XML' ); }

my $xml = Treemap::Input::XML->new;         # create an object
ok( defined $xml,                      "Successfully created object." );
ok( $xml->isa('Treemap::Input::XML'),  "This object is of the correct class." );

is( $xml->load("t/data/XML.xml"), 1,           "Successfully loaded an XML file." );


