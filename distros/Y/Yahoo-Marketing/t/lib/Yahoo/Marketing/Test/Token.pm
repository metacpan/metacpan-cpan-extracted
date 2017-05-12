package Yahoo::Marketing::Test::Token;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Token;

sub test_can_create_token_and_set_all_fields : Test(3) {

    my $token = Yahoo::Marketing::Token->new
                                       ->jobId( 'job id' )
                                       ->uploadUrl( 'upload url' )
                   ;

    ok( $token );

    is( $token->jobId, 'job id', 'can get job id' );
    is( $token->uploadUrl, 'upload url', 'can get upload url' );

};



1;

