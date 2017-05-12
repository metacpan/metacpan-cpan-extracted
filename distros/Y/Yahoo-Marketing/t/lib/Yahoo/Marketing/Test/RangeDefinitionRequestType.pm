package Yahoo::Marketing::Test::RangeDefinitionRequestType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::RangeDefinitionRequestType;

sub test_can_create_range_definition_request_type_and_set_all_fields : Test(3) {

    my $range_definition_request_type = Yahoo::Marketing::RangeDefinitionRequestType->new
                                                                                    ->market( 'market' )
                                                                                    ->rangeName( 'range name' )
                   ;

    ok( $range_definition_request_type );

    is( $range_definition_request_type->market, 'market', 'can get market' );
    is( $range_definition_request_type->rangeName, 'range name', 'can get range name' );

};



1;

