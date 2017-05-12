package Yahoo::Marketing::APT::Test::AudienceSegmentDescriptor;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AudienceSegmentDescriptor;

sub test_can_create_audience_segment_descriptor_and_set_all_fields : Test(5) {

    my $audience_segment_descriptor = Yahoo::Marketing::APT::AudienceSegmentDescriptor->new
                                                                                 ->ID( 'id' )
                                                                                 ->accountID( 'account id' )
                                                                                 ->description( 'description' )
                                                                                 ->name( 'name' )
                   ;

    ok( $audience_segment_descriptor );

    is( $audience_segment_descriptor->ID, 'id', 'can get id' );
    is( $audience_segment_descriptor->accountID, 'account id', 'can get account id' );
    is( $audience_segment_descriptor->description, 'description', 'can get description' );
    is( $audience_segment_descriptor->name, 'name', 'can get name' );

};



1;

