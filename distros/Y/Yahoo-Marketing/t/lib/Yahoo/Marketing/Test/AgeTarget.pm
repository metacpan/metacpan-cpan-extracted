package Yahoo::Marketing::Test::AgeTarget;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::AgeTarget;

sub test_can_create_age_target_and_set_all_fields : Test(3) {

    my $age_target = Yahoo::Marketing::AgeTarget->new
                                                ->ageRange( 'age range' )
                                                ->premium( 'premium' )
                   ;

    ok( $age_target );

    is( $age_target->ageRange, 'age range', 'can get age range' );
    is( $age_target->premium, 'premium', 'can get premium' );

};



1;

