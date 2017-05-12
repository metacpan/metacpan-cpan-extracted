package Yahoo::Marketing::APT::Test::SiteStructure;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::SiteStructure;

sub test_can_create_site_structure_and_set_all_fields : Test(6) {

    my $site_structure = Yahoo::Marketing::APT::SiteStructure->new
                                                        ->ID( 'id' )
                                                        ->externalCode( 'external code' )
                                                        ->name( 'name' )
                                                        ->parentID( 'parent id' )
                                                        ->targetingAttributeType( 'targeting attribute type' )
                   ;

    ok( $site_structure );

    is( $site_structure->ID, 'id', 'can get id' );
    is( $site_structure->externalCode, 'external code', 'can get external code' );
    is( $site_structure->name, 'name', 'can get name' );
    is( $site_structure->parentID, 'parent id', 'can get parent id' );
    is( $site_structure->targetingAttributeType, 'targeting attribute type', 'can get targeting attribute type' );

};



1;

