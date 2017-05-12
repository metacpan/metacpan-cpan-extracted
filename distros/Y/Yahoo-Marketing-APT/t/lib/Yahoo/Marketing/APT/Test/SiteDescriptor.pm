package Yahoo::Marketing::APT::Test::SiteDescriptor;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::SiteDescriptor;

sub test_can_create_site_descriptor_and_set_all_fields : Test(4) {

    my $site_descriptor = Yahoo::Marketing::APT::SiteDescriptor->new
                                                          ->ID( 'id' )
                                                          ->accountID( 'account id' )
                                                          ->name( 'name' )
                   ;

    ok( $site_descriptor );

    is( $site_descriptor->ID, 'id', 'can get id' );
    is( $site_descriptor->accountID, 'account id', 'can get account id' );
    is( $site_descriptor->name, 'name', 'can get name' );

};



1;

