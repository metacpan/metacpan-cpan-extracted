package Yahoo::Marketing::Test::KeywordRejectionReasons;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::KeywordRejectionReasons;

sub test_can_create_keyword_rejection_reasons_and_set_all_fields : Test(7) {

    my $keyword_rejection_reasons = Yahoo::Marketing::KeywordRejectionReasons->new
                                                                             ->alternateTextRejectionReasons( 'alternate text rejection reasons' )
                                                                             ->keywordID( 'keyword id' )
                                                                             ->keywordRejectionReasons( 'keyword rejection reasons' )
                                                                             ->phraseSearchTextRejectionReasons( 'phrase search text rejection reasons' )
                                                                             ->textRejectionReasons( 'text rejection reasons' )
                                                                             ->urlRejectionReasons( 'url rejection reasons' )
                   ;

    ok( $keyword_rejection_reasons );

    is( $keyword_rejection_reasons->alternateTextRejectionReasons, 'alternate text rejection reasons', 'can get alternate text rejection reasons' );
    is( $keyword_rejection_reasons->keywordID, 'keyword id', 'can get keyword id' );
    is( $keyword_rejection_reasons->keywordRejectionReasons, 'keyword rejection reasons', 'can get keyword rejection reasons' );
    is( $keyword_rejection_reasons->phraseSearchTextRejectionReasons, 'phrase search text rejection reasons', 'can get phrase search text rejection reasons' );
    is( $keyword_rejection_reasons->textRejectionReasons, 'text rejection reasons', 'can get text rejection reasons' );
    is( $keyword_rejection_reasons->urlRejectionReasons, 'url rejection reasons', 'can get url rejection reasons' );

};



1;

