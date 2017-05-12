package Yahoo::Marketing::Test::Summary;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Summary;

sub test_can_create_summary_and_set_all_fields : Test(9) {

    my $summary = Yahoo::Marketing::Summary->new
                                           ->convertedAdgroups( 'converted adgroups' )
                                           ->convertedCampaigns( 'converted campaigns' )
                                           ->convertedCreatives( 'converted creatives' )
                                           ->convertedKeywords( 'converted keywords' )
                                           ->nonConvertedAdgroups( 'non converted adgroups' )
                                           ->nonConvertedCampaigns( 'non converted campaigns' )
                                           ->nonConvertedCreatives( 'non converted creatives' )
                                           ->nonConvertedKeywords( 'non converted keywords' )
                   ;

    ok( $summary );

    is( $summary->convertedAdgroups, 'converted adgroups', 'can get converted adgroups' );
    is( $summary->convertedCampaigns, 'converted campaigns', 'can get converted campaigns' );
    is( $summary->convertedCreatives, 'converted creatives', 'can get converted creatives' );
    is( $summary->convertedKeywords, 'converted keywords', 'can get converted keywords' );
    is( $summary->nonConvertedAdgroups, 'non converted adgroups', 'can get non converted adgroups' );
    is( $summary->nonConvertedCampaigns, 'non converted campaigns', 'can get non converted campaigns' );
    is( $summary->nonConvertedCreatives, 'non converted creatives', 'can get non converted creatives' );
    is( $summary->nonConvertedKeywords, 'non converted keywords', 'can get non converted keywords' );

};



1;

