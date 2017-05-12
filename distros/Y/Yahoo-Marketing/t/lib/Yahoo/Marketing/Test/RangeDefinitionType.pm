package Yahoo::Marketing::Test::RangeDefinitionType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::RangeDefinitionType;

sub test_can_create_range_definition_type_and_set_all_fields : Test(4) {

    my $range_definition_type = Yahoo::Marketing::RangeDefinitionType->new
                                                                     ->bucket( 'bucket' )
                                                                     ->market( 'market' )
                                                                     ->rangeName( 'range name' )
                   ;

    ok( $range_definition_type );

    is( $range_definition_type->bucket, 'bucket', 'can get bucket' );
    is( $range_definition_type->market, 'market', 'can get market' );
    is( $range_definition_type->rangeName, 'range name', 'can get range name' );

};



1;

