package Yahoo::Marketing::APT::Test::Region;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Region;

sub test_can_create_region_and_set_all_fields : Test(6) {

    my $region = Yahoo::Marketing::APT::Region->new
                                         ->WOEID( 'woeid' )
                                         ->code( 'code' )
                                         ->level( 'level' )
                                         ->name( 'name' )
                                         ->parentWOEID( 'parent woeid' )
                   ;

    ok( $region );

    is( $region->WOEID, 'woeid', 'can get woeid' );
    is( $region->code, 'code', 'can get code' );
    is( $region->level, 'level', 'can get level' );
    is( $region->name, 'name', 'can get name' );
    is( $region->parentWOEID, 'parent woeid', 'can get parent woeid' );

};



1;

