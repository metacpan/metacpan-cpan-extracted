package Yahoo::Marketing::APT::Test::PlacementEditEndDate;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::PlacementEditEndDate;

sub test_can_create_placement_edit_end_date_and_set_all_fields : Test(3) {

    my $placement_edit_end_date = Yahoo::Marketing::APT::PlacementEditEndDate->new
                                                                        ->endDate( '2009-01-06T17:51:55' )
                                                                        ->endDateChangeType( 'end date change type' )
                   ;

    ok( $placement_edit_end_date );

    is( $placement_edit_end_date->endDate, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $placement_edit_end_date->endDateChangeType, 'end date change type', 'can get end date change type' );

};



1;

