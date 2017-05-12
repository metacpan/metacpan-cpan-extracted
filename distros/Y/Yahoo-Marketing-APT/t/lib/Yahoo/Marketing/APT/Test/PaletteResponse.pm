package Yahoo::Marketing::APT::Test::PaletteResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PaletteResponse;

sub test_can_create_palette_response_and_set_all_fields : Test(4) {

    my $palette_response = Yahoo::Marketing::APT::PaletteResponse->new
                                                            ->errors( 'errors' )
                                                            ->operationSucceeded( 'operation succeeded' )
                                                            ->palette( 'palette' )
                   ;

    ok( $palette_response );

    is( $palette_response->errors, 'errors', 'can get errors' );
    is( $palette_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $palette_response->palette, 'palette', 'can get palette' );

};



1;

