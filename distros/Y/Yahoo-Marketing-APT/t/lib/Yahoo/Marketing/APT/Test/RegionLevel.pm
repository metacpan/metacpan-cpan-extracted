package Yahoo::Marketing::APT::Test::RegionLevel;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::RegionLevel;

sub test_can_create_region_level_and_set_all_fields : Test(3) {

    my $region_level = Yahoo::Marketing::APT::RegionLevel->new
                                                    ->level( 'level' )
                                                    ->name( 'name' )
                   ;

    ok( $region_level );

    is( $region_level->level, 'level', 'can get level' );
    is( $region_level->name, 'name', 'can get name' );

};



1;

