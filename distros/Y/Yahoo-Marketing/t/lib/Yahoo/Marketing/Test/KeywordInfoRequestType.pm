package Yahoo::Marketing::Test::KeywordInfoRequestType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::KeywordInfoRequestType;

sub test_can_create_keyword_info_request_type_and_set_all_fields : Test(3) {

    my $keyword_info_request_type = Yahoo::Marketing::KeywordInfoRequestType->new
                                                                            ->keywords( 'keywords' )
                                                                            ->market( 'market' )
                   ;

    ok( $keyword_info_request_type );

    is( $keyword_info_request_type->keywords, 'keywords', 'can get keywords' );
    is( $keyword_info_request_type->market, 'market', 'can get market' );

};



1;

