package Yahoo::Marketing::Test::SubphraseKeywordRequestType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::SubphraseKeywordRequestType;

sub test_can_create_sub_phrase_keyword_request_type_and_set_all_fields : Test(7) {

    my $sub_phrase_keyword_request_type = Yahoo::Marketing::SubphraseKeywordRequestType->new
                                                                                       ->excludedKeywords( 'excluded keywords' )
                                                                                       ->excludedPhraseFilters( 'excluded phrase filters' )
                                                                                       ->market( 'market' )
                                                                                       ->maxKeywords( 'max keywords' )
                                                                                       ->offset( 'offset' )
                                                                                       ->requiredPhraseFilters( 'required phrase filters' )
                   ;

    ok( $sub_phrase_keyword_request_type );

    is( $sub_phrase_keyword_request_type->excludedKeywords, 'excluded keywords', 'can get excluded keywords' );
    is( $sub_phrase_keyword_request_type->excludedPhraseFilters, 'excluded phrase filters', 'can get excluded phrase filters' );
    is( $sub_phrase_keyword_request_type->market, 'market', 'can get market' );
    is( $sub_phrase_keyword_request_type->maxKeywords, 'max keywords', 'can get max keywords' );
    is( $sub_phrase_keyword_request_type->offset, 'offset', 'can get offset' );
    is( $sub_phrase_keyword_request_type->requiredPhraseFilters, 'required phrase filters', 'can get required phrase filters' );

};



1;

