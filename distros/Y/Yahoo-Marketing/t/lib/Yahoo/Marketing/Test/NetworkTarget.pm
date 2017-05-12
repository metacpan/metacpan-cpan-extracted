package Yahoo::Marketing::Test::NetworkTarget;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::NetworkTarget;

sub test_can_create_network_target_and_set_all_fields : Test(3) {

    my $network_target = Yahoo::Marketing::NetworkTarget->new
                                                        ->network( 'network' )
                                                        ->premium( 'premium' )
                   ;

    ok( $network_target );

    is( $network_target->network, 'network', 'can get network' );
    is( $network_target->premium, 'premium', 'can get premium' );

};



1;

