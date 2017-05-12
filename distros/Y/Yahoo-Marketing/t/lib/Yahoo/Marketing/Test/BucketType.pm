package Yahoo::Marketing::Test::BucketType;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::BucketType;

sub test_can_create_bucket_type_and_set_all_fields : Test(4) {

    my $bucket_type = Yahoo::Marketing::BucketType->new
                                                  ->bucketID( 'bucket id' )
                                                  ->max( 'max' )
                                                  ->min( 'min' )
                   ;

    ok( $bucket_type );

    is( $bucket_type->bucketID, 'bucket id', 'can get bucket id' );
    is( $bucket_type->max, 'max', 'can get max' );
    is( $bucket_type->min, 'min', 'can get min' );

};



1;

