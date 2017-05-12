package Yahoo::Marketing::Test::RelatedKeywordType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::RelatedKeywordType;

sub test_can_create_related_keyword_type_and_set_all_fields : Test(5) {

    my $related_keyword_type = Yahoo::Marketing::RelatedKeywordType->new
                                                                   ->canonical( 'canonical' )
                                                                   ->common( 'common' )
                                                                   ->rangeValue( 'range value' )
                                                                   ->score( 'score' )
                   ;

    ok( $related_keyword_type );

    is( $related_keyword_type->canonical, 'canonical', 'can get canonical' );
    is( $related_keyword_type->common, 'common', 'can get common' );
    is( $related_keyword_type->rangeValue, 'range value', 'can get range value' );
    is( $related_keyword_type->score, 'score', 'can get score' );

};



1;

