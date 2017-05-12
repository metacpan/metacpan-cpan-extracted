package Yahoo::Marketing::Test::TargetingType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::TargetingType;

sub test_can_create_targeting_type_and_set_all_fields : Test(2) {

    my $targeting_type = Yahoo::Marketing::TargetingType->new
                                                        ->value( 'value' )
                   ;

    ok( $targeting_type );

    is( $targeting_type->value, 'value', 'can get value' );

};



1;

