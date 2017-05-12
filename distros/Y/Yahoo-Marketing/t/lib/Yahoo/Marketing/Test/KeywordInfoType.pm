package Yahoo::Marketing::Test::KeywordInfoType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::KeywordInfoType;

sub test_can_create_keyword_info_type_and_set_all_fields : Test(4) {

    my $keyword_info_type = Yahoo::Marketing::KeywordInfoType->new
                                                             ->canonical( 'canonical' )
                                                             ->common( 'common' )
                                                             ->raw( 'raw' )
                   ;

    ok( $keyword_info_type );

    is( $keyword_info_type->canonical, 'canonical', 'can get canonical' );
    is( $keyword_info_type->common, 'common', 'can get common' );
    is( $keyword_info_type->raw, 'raw', 'can get raw' );

};



1;

