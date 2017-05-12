package Yahoo::Marketing::Test::ForecastKeyword;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ForecastKeyword;

sub test_can_create_forecast_keyword_and_set_all_fields : Test(3) {

    my $forecast_keyword = Yahoo::Marketing::ForecastKeyword->new
                                                            ->customBid( 'custom bid' )
                                                            ->keyword( 'keyword' )
                   ;

    ok( $forecast_keyword );

    is( $forecast_keyword->customBid, 'custom bid', 'can get custom bid' );
    is( $forecast_keyword->keyword, 'keyword', 'can get keyword' );

};



1;

