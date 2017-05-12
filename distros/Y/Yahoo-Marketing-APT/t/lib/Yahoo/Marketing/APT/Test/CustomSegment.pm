package Yahoo::Marketing::APT::Test::CustomSegment;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CustomSegment;

sub test_can_create_custom_segment_and_set_all_fields : Test(13) {

    my $custom_segment = Yahoo::Marketing::APT::CustomSegment->new
                                                        ->ID( 'id' )
                                                        ->accountID( 'account id' )
                                                        ->activationTimestamp( '2009-01-06T17:51:55' )
                                                        ->audienceSegmentCategoryID( 'audience segment category id' )
                                                        ->createTimestamp( '2009-01-07T17:51:55' )
                                                        ->deactivationTimestamp( '2009-01-08T17:51:55' )
                                                        ->description( 'description' )
                                                        ->lastUpdateTimestamp( '2009-01-09T17:51:55' )
                                                        ->name( 'name' )
                                                        ->status( 'status' )
                                                        ->visitDefinition( 'visit definition' )
                                                        ->visitFrequency( 'visit frequency' )
                   ;

    ok( $custom_segment );

    is( $custom_segment->ID, 'id', 'can get id' );
    is( $custom_segment->accountID, 'account id', 'can get account id' );
    is( $custom_segment->activationTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $custom_segment->audienceSegmentCategoryID, 'audience segment category id', 'can get audience segment category id' );
    is( $custom_segment->createTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $custom_segment->deactivationTimestamp, '2009-01-08T17:51:55', 'can get 2009-01-08T17:51:55' );
    is( $custom_segment->description, 'description', 'can get description' );
    is( $custom_segment->lastUpdateTimestamp, '2009-01-09T17:51:55', 'can get 2009-01-09T17:51:55' );
    is( $custom_segment->name, 'name', 'can get name' );
    is( $custom_segment->status, 'status', 'can get status' );
    is( $custom_segment->visitDefinition, 'visit definition', 'can get visit definition' );
    is( $custom_segment->visitFrequency, 'visit frequency', 'can get visit frequency' );

};



1;

