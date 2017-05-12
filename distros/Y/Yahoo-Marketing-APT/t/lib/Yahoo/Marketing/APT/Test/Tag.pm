package Yahoo::Marketing::APT::Test::Tag;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Tag;

sub test_can_create_tag_and_set_all_fields : Test(8) {

    my $tag = Yahoo::Marketing::APT::Tag->new
                                   ->ID( 'id' )
                                   ->accountID( 'account id' )
                                   ->componentID( 'component id' )
                                   ->createTimestamp( '2009-01-06T17:51:55' )
                                   ->tagName( 'tag name' )
                                   ->tagStatus( 'tag status' )
                                   ->tagType( 'tag type' )
                   ;

    ok( $tag );

    is( $tag->ID, 'id', 'can get id' );
    is( $tag->accountID, 'account id', 'can get account id' );
    is( $tag->componentID, 'component id', 'can get component id' );
    is( $tag->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $tag->tagName, 'tag name', 'can get tag name' );
    is( $tag->tagStatus, 'tag status', 'can get tag status' );
    is( $tag->tagType, 'tag type', 'can get tag type' );

};



1;

