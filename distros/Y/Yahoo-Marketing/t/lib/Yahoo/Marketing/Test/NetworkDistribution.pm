package Yahoo::Marketing::Test::NetworkDistribution;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::NetworkDistribution;

sub test_can_create_network_distribution_and_set_all_fields : Test(2) {

    my $network_distribution = Yahoo::Marketing::NetworkDistribution->new
                                                                    ->networkTargets( 'network targets' )
                   ;

    ok( $network_distribution );

    is( $network_distribution->networkTargets, 'network targets', 'can get network targets' );

};



1;

