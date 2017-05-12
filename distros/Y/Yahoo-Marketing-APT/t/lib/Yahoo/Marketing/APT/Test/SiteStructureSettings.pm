package Yahoo::Marketing::APT::Test::SiteStructureSettings;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::SiteStructureSettings;

sub test_can_create_site_structure_settings_and_set_all_fields : Test(3) {

    my $site_structure_settings = Yahoo::Marketing::APT::SiteStructureSettings->new
                                                                         ->deliveryLevel( 'delivery level' )
                                                                         ->siteStructureID( 'site structure id' )
                   ;

    ok( $site_structure_settings );

    is( $site_structure_settings->deliveryLevel, 'delivery level', 'can get delivery level' );
    is( $site_structure_settings->siteStructureID, 'site structure id', 'can get site structure id' );

};



1;

