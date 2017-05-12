package Yahoo::Marketing::APT::Test::Visit;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Visit;

sub test_can_create_visit_and_set_all_fields : Test(7) {

    my $visit = Yahoo::Marketing::APT::Visit->new
                                       ->contentTopicIDs( 'content topic ids' )
                                       ->contentTypeIDs( 'content type ids' )
                                       ->customContentCategoryIDs( 'custom content category ids' )
                                       ->customSectionIDs( 'custom section ids' )
                                       ->publisherAccountIDs( 'publisher account ids' )
                                       ->siteIDs( 'site ids' )
                   ;

    ok( $visit );

    is( $visit->contentTopicIDs, 'content topic ids', 'can get content topic ids' );
    is( $visit->contentTypeIDs, 'content type ids', 'can get content type ids' );
    is( $visit->customContentCategoryIDs, 'custom content category ids', 'can get custom content category ids' );
    is( $visit->customSectionIDs, 'custom section ids', 'can get custom section ids' );
    is( $visit->publisherAccountIDs, 'publisher account ids', 'can get publisher account ids' );
    is( $visit->siteIDs, 'site ids', 'can get site ids' );

};



1;

