package Yahoo::Marketing::APT::Test::LinkingSettings;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LinkingSettings;

sub test_can_create_linking_settings_and_set_all_fields : Test(2) {

    my $linking_settings = Yahoo::Marketing::APT::LinkingSettings->new
                                                            ->allowLinkProposal( 'allow link proposal' )
                   ;

    ok( $linking_settings );

    is( $linking_settings->allowLinkProposal, 'allow link proposal', 'can get allow link proposal' );

};



1;

