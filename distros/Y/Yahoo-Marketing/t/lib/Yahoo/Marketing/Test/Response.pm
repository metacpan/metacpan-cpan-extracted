package Yahoo::Marketing::Test::Response;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Response;

sub test_can_create_response_and_set_all_fields : Test(4) {

    my $response = Yahoo::Marketing::Response->new
                                             ->downloadFile( 'download file' )
                                             ->downloadUrl( 'download url' )
                                             ->locale( 'locale' )
                   ;

    ok( $response );

    is( $response->downloadFile, 'download file', 'can get download file' );
    is( $response->downloadUrl, 'download url', 'can get download url' );
    is( $response->locale, 'locale', 'can get locale' );

};



1;

