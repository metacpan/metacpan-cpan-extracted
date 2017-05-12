package Yahoo::Marketing::APT::Test::Palette;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Palette;

sub test_can_create_palette_and_set_all_fields : Test(11) {

    my $palette = Yahoo::Marketing::APT::Palette->new
                                           ->ID( 'id' )
                                           ->accountID( 'account id' )
                                           ->backgroundColor( 'background color' )
                                           ->borderColor( 'border color' )
                                           ->createTimestamp( '2009-01-06T17:51:55' )
                                           ->descriptionColor( 'description color' )
                                           ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                           ->name( 'name' )
                                           ->titleColor( 'title color' )
                                           ->urlColor( 'url color' )
                   ;

    ok( $palette );

    is( $palette->ID, 'id', 'can get id' );
    is( $palette->accountID, 'account id', 'can get account id' );
    is( $palette->backgroundColor, 'background color', 'can get background color' );
    is( $palette->borderColor, 'border color', 'can get border color' );
    is( $palette->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $palette->descriptionColor, 'description color', 'can get description color' );
    is( $palette->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $palette->name, 'name', 'can get name' );
    is( $palette->titleColor, 'title color', 'can get title color' );
    is( $palette->urlColor, 'url color', 'can get url color' );

};



1;

