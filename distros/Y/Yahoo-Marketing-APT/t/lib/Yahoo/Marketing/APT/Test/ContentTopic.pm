package Yahoo::Marketing::APT::Test::ContentTopic;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ContentTopic;

sub test_can_create_content_topic_and_set_all_fields : Test(6) {

    my $content_topic = Yahoo::Marketing::APT::ContentTopic->new
                                                      ->ID( 'id' )
                                                      ->description( 'description' )
                                                      ->name( 'name' )
                                                      ->parentID( 'parent id' )
                                                      ->targetingAttributeType( 'targeting attribute type' )
                   ;

    ok( $content_topic );

    is( $content_topic->ID, 'id', 'can get id' );
    is( $content_topic->description, 'description', 'can get description' );
    is( $content_topic->name, 'name', 'can get name' );
    is( $content_topic->parentID, 'parent id', 'can get parent id' );
    is( $content_topic->targetingAttributeType, 'targeting attribute type', 'can get targeting attribute type' );

};



1;

