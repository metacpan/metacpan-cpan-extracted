package Yahoo::Marketing::APT::Test::CompositeURL;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CompositeURL;

sub test_can_create_composite_url_and_set_all_fields : Test(4) {

    my $composite_url = Yahoo::Marketing::APT::CompositeURL->new
                                                      ->clickThroughURL( 'click through url' )
                                                      ->clickTrackingURL( 'click tracking url' )
                                                      ->urlIndex( 'url index' )
                   ;

    ok( $composite_url );

    is( $composite_url->clickThroughURL, 'click through url', 'can get click through url' );
    is( $composite_url->clickTrackingURL, 'click tracking url', 'can get click tracking url' );
    is( $composite_url->urlIndex, 'url index', 'can get url index' );

};



1;

