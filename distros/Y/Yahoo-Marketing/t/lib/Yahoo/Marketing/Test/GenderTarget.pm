package Yahoo::Marketing::Test::GenderTarget;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::GenderTarget;

sub test_can_create_gender_target_and_set_all_fields : Test(3) {

    my $gender_target = Yahoo::Marketing::GenderTarget->new
                                                      ->gender( 'gender' )
                                                      ->premium( 'premium' )
                   ;

    ok( $gender_target );

    is( $gender_target->gender, 'gender', 'can get gender' );
    is( $gender_target->premium, 'premium', 'can get premium' );

};



1;

