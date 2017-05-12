package Yahoo::Marketing::Test::Preferences;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Preferences;

sub test_can_create_preferences_and_set_all_fields : Test(4) {

    my $preferences = Yahoo::Marketing::Preferences->new
                                                   ->includeCampaignBudget( 'include campaign budget' )
                                                   ->includeKeywordUrl( 'include keyword url' )
                                                   ->includeNegativeKeywords( 'include negative keywords' )
                   ;

    ok( $preferences );

    is( $preferences->includeCampaignBudget, 'include campaign budget', 'can get include campaign budget' );
    is( $preferences->includeKeywordUrl, 'include keyword url', 'can get include keyword url' );
    is( $preferences->includeNegativeKeywords, 'include negative keywords', 'can get include negative keywords' );

};



1;

