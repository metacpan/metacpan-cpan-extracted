package Yahoo::Marketing::APT::Test::PixelFrequency;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PixelFrequency;

sub test_can_create_pixel_frequency_and_set_all_fields : Test(3) {

    my $pixel_frequency = Yahoo::Marketing::APT::PixelFrequency->new
                                                          ->blackoutTimePeriod( 'blackout time period' )
                                                          ->type( 'type' )
                   ;

    ok( $pixel_frequency );

    is( $pixel_frequency->blackoutTimePeriod, 'blackout time period', 'can get blackout time period' );
    is( $pixel_frequency->type, 'type', 'can get type' );

};



1;

