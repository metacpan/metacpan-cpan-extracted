package Yahoo::Marketing::Test::RelatedKeywordRequestType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::RelatedKeywordRequestType;

sub test_can_create_related_keyword_request_type_and_set_all_fields : Test(8) {

    my $related_keyword_request_type = Yahoo::Marketing::RelatedKeywordRequestType->new
                                                                                  ->excludedKeywords( 'excluded keywords' )
                                                                                  ->excludedPhraseFilters( 'excluded phrase filters' )
                                                                                  ->market( 'market' )
                                                                                  ->maxKeywords( 'max keywords' )
                                                                                  ->negativeKeywords( 'negative keywords' )
                                                                                  ->positiveKeywords( 'positive keywords' )
                                                                                  ->requiredPhraseFilters( 'required phrase filters' )
                   ;

    ok( $related_keyword_request_type );

    is( $related_keyword_request_type->excludedKeywords, 'excluded keywords', 'can get excluded keywords' );
    is( $related_keyword_request_type->excludedPhraseFilters, 'excluded phrase filters', 'can get excluded phrase filters' );
    is( $related_keyword_request_type->market, 'market', 'can get market' );
    is( $related_keyword_request_type->maxKeywords, 'max keywords', 'can get max keywords' );
    is( $related_keyword_request_type->negativeKeywords, 'negative keywords', 'can get negative keywords' );
    is( $related_keyword_request_type->positiveKeywords, 'positive keywords', 'can get positive keywords' );
    is( $related_keyword_request_type->requiredPhraseFilters, 'required phrase filters', 'can get required phrase filters' );

};



1;

