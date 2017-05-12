package Yahoo::Marketing::Test::KeywordInfoResponseType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::KeywordInfoResponseType;

sub test_can_create_keyword_info_response_type_and_set_all_fields : Test(4) {

    my $keyword_info_response_type = Yahoo::Marketing::KeywordInfoResponseType->new
                                                                              ->keywords( 'keywords' )
                                                                              ->notes( 'notes' )
                                                                              ->responseStatus( 'response status' )
                   ;

    ok( $keyword_info_response_type );

    is( $keyword_info_response_type->keywords, 'keywords', 'can get keywords' );
    is( $keyword_info_response_type->notes, 'notes', 'can get notes' );
    is( $keyword_info_response_type->responseStatus, 'response status', 'can get response status' );

};



1;

