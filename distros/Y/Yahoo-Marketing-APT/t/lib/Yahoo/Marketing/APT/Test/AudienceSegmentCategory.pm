package Yahoo::Marketing::APT::Test::AudienceSegmentCategory;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AudienceSegmentCategory;

sub test_can_create_audience_segment_category_and_set_all_fields : Test(7) {

    my $audience_segment_category = Yahoo::Marketing::APT::AudienceSegmentCategory->new
                                                                             ->ID( 'id' )
                                                                             ->accountID( 'account id' )
                                                                             ->createTimestamp( '2009-01-06T17:51:55' )
                                                                             ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                                                             ->name( 'name' )
                                                                             ->parentID( 'parent id' )
                   ;

    ok( $audience_segment_category );

    is( $audience_segment_category->ID, 'id', 'can get id' );
    is( $audience_segment_category->accountID, 'account id', 'can get account id' );
    is( $audience_segment_category->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $audience_segment_category->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $audience_segment_category->name, 'name', 'can get name' );
    is( $audience_segment_category->parentID, 'parent id', 'can get parent id' );

};



1;

