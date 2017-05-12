package Yahoo::Marketing::APT::Test::PublisherSelector;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PublisherSelector;

sub test_can_create_publisher_selector_and_set_all_fields : Test(4) {

    my $publisher_selector = Yahoo::Marketing::APT::PublisherSelector->new
                                                                ->publisherAccountIDs( 'publisher account ids' )
                                                                ->siteIDs( 'site ids' )
                                                                ->type( 'type' )
                   ;

    ok( $publisher_selector );

    is( $publisher_selector->publisherAccountIDs, 'publisher account ids', 'can get publisher account ids' );
    is( $publisher_selector->siteIDs, 'site ids', 'can get site ids' );
    is( $publisher_selector->type, 'type', 'can get type' );

};



1;

