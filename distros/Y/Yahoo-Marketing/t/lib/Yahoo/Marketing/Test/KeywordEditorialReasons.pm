package Yahoo::Marketing::Test::KeywordEditorialReasons;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::KeywordEditorialReasons;

sub test_can_create_keyword_editorial_reasons_and_set_all_fields : Test(9) {

    my $keyword_editorial_reasons = Yahoo::Marketing::KeywordEditorialReasons->new
                                                                             ->alternateTextEditorialReasons( 'alternate text editorial reasons' )
                                                                             ->keywordEditorialReasons( 'keyword editorial reasons' )
                                                                             ->keywordID( 'keyword id' )
                                                                             ->phraseSearchTextEditorialReasons( 'phrase search text editorial reasons' )
                                                                             ->textEditorialReasons( 'text editorial reasons' )
                                                                             ->urlContentEditorialReasons( 'url content editorial reasons' )
                                                                             ->urlEditorialReasons( 'url editorial reasons' )
                                                                             ->urlStringEditorialReasons( 'url string editorial reasons' )
                   ;

    ok( $keyword_editorial_reasons );

    is( $keyword_editorial_reasons->alternateTextEditorialReasons, 'alternate text editorial reasons', 'can get alternate text editorial reasons' );
    is( $keyword_editorial_reasons->keywordEditorialReasons, 'keyword editorial reasons', 'can get keyword editorial reasons' );
    is( $keyword_editorial_reasons->keywordID, 'keyword id', 'can get keyword id' );
    is( $keyword_editorial_reasons->phraseSearchTextEditorialReasons, 'phrase search text editorial reasons', 'can get phrase search text editorial reasons' );
    is( $keyword_editorial_reasons->textEditorialReasons, 'text editorial reasons', 'can get text editorial reasons' );
    is( $keyword_editorial_reasons->urlContentEditorialReasons, 'url content editorial reasons', 'can get url content editorial reasons' );
    is( $keyword_editorial_reasons->urlEditorialReasons, 'url editorial reasons', 'can get url editorial reasons' );
    is( $keyword_editorial_reasons->urlStringEditorialReasons, 'url string editorial reasons', 'can get url string editorial reasons' );

};



1;

