package Yahoo::Marketing::APT::Test::DeliveryFormat;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::DeliveryFormat;

sub test_can_create_delivery_format_and_set_all_fields : Test(3) {

    my $delivery_format = Yahoo::Marketing::APT::DeliveryFormat->new
                                                          ->fileType( 'file type' )
                                                          ->zipped( 'zipped' )
                   ;

    ok( $delivery_format );

    is( $delivery_format->fileType, 'file type', 'can get file type' );
    is( $delivery_format->zipped, 'zipped', 'can get zipped' );

};



1;

