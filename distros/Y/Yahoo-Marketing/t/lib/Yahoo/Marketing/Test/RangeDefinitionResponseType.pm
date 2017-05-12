package Yahoo::Marketing::Test::RangeDefinitionResponseType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::RangeDefinitionResponseType;

sub test_can_create_range_definition_response_type_and_set_all_fields : Test(3) {

    my $range_definition_response_type = Yahoo::Marketing::RangeDefinitionResponseType->new
                                                                                      ->rangeDefinition( 'range definition' )
                                                                                      ->responseStatus( 'response status' )
                   ;

    ok( $range_definition_response_type );

    is( $range_definition_response_type->rangeDefinition, 'range definition', 'can get range definition' );
    is( $range_definition_response_type->responseStatus, 'response status', 'can get response status' );

};



1;

