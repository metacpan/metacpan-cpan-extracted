package Yahoo::Marketing::Test::KeywordResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::KeywordResponse;

sub test_can_create_keyword_response_and_set_all_fields : Test(6) {

    my $keyword_response = Yahoo::Marketing::KeywordResponse->new
                                                            ->editorialReasons( 'editorial reasons' )
                                                            ->errors( 'errors' )
                                                            ->keyword( 'keyword' )
                                                            ->operationSucceeded( 'operation succeeded' )
                                                            ->warnings( 'warnings' )
                   ;

    ok( $keyword_response );

    is( $keyword_response->editorialReasons, 'editorial reasons', 'can get editorial reasons' );
    is( $keyword_response->errors, 'errors', 'can get errors' );
    is( $keyword_response->keyword, 'keyword', 'can get keyword' );
    is( $keyword_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $keyword_response->warnings, 'warnings', 'can get warnings' );

};



1;

