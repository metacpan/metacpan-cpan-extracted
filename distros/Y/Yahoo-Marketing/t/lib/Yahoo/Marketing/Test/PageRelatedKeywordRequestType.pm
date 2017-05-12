package Yahoo::Marketing::Test::PageRelatedKeywordRequestType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::PageRelatedKeywordRequestType;

sub test_can_create_page_related_keyword_request_type_and_set_all_fields : Test(9) {

    my $page_related_keyword_request_type = Yahoo::Marketing::PageRelatedKeywordRequestType->new
                                                                                           ->URL( 'url' )
                                                                                           ->excludedKeywords( 'excluded keywords' )
                                                                                           ->excludedPhraseFilters( 'excluded phrase filters' )
                                                                                           ->market( 'market' )
                                                                                           ->maxKeywords( 'max keywords' )
                                                                                           ->negativeKeywords( 'negative keywords' )
                                                                                           ->positiveKeywords( 'positive keywords' )
                                                                                           ->requiredPhraseFilters( 'required phrase filters' )
                   ;

    ok( $page_related_keyword_request_type );

    is( $page_related_keyword_request_type->URL, 'url', 'can get url' );
    is( $page_related_keyword_request_type->excludedKeywords, 'excluded keywords', 'can get excluded keywords' );
    is( $page_related_keyword_request_type->excludedPhraseFilters, 'excluded phrase filters', 'can get excluded phrase filters' );
    is( $page_related_keyword_request_type->market, 'market', 'can get market' );
    is( $page_related_keyword_request_type->maxKeywords, 'max keywords', 'can get max keywords' );
    is( $page_related_keyword_request_type->negativeKeywords, 'negative keywords', 'can get negative keywords' );
    is( $page_related_keyword_request_type->positiveKeywords, 'positive keywords', 'can get positive keywords' );
    is( $page_related_keyword_request_type->requiredPhraseFilters, 'required phrase filters', 'can get required phrase filters' );

};



1;

