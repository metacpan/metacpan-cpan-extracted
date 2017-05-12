package Yahoo::Marketing::Test::ForecastCreative;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ForecastCreative;

sub test_can_create_forecast_creative_and_set_all_fields : Test(5) {

    my $forecast_creative = Yahoo::Marketing::ForecastCreative->new
                                                              ->description( 'description' )
                                                              ->destinationUrl( 'destination url' )
                                                              ->displayUrl( 'display url' )
                                                              ->title( 'title' )
                   ;

    ok( $forecast_creative );

    is( $forecast_creative->description, 'description', 'can get description' );
    is( $forecast_creative->destinationUrl, 'destination url', 'can get destination url' );
    is( $forecast_creative->displayUrl, 'display url', 'can get display url' );
    is( $forecast_creative->title, 'title', 'can get title' );

};



1;

