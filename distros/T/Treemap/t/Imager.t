#!/usr/bin/perl -w

use Test::More 'no_plan';

BEGIN { use_ok( 'Imager' ); }
BEGIN { use_ok( 'Treemap::Output::Imager' ); }

my $imager = Treemap::Output::Imager->new( WIDTH=>10, HEIGHT=>10 );         # create an object
ok( defined $imager,                         "Successfully created object." );
ok( $imager->isa('Treemap::Output::Imager'), "This object is of the correct class." );
is( $imager->rect(0,0,10,10,'#000000'), 1,   "Drawing a box." );
is( $imager->text(0,0,10,10,'Weee'), 1,      "Printing text." );
is( $imager->width(), 10,                    "Width = 10." );
is( $imager->height(), 10,                   "Height = 10." );
