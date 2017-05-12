package Yahoo::Marketing::Test::ForecastImpressionData;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ForecastImpressionData;

sub test_can_create_forecast_impression_data_and_set_all_fields : Test(4) {

    my $forecast_impression_data = Yahoo::Marketing::ForecastImpressionData->new
                                                                           ->impressions( 'impressions' )
                                                                           ->maxImpressions( 'max impressions' )
                                                                           ->minImpressions( 'min impressions' )
                   ;

    ok( $forecast_impression_data );

    is( $forecast_impression_data->impressions, 'impressions', 'can get impressions' );
    is( $forecast_impression_data->maxImpressions, 'max impressions', 'can get max impressions' );
    is( $forecast_impression_data->minImpressions, 'min impressions', 'can get min impressions' );

};



1;

