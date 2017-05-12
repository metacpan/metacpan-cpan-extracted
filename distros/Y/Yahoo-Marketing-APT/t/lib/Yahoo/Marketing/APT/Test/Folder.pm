package Yahoo::Marketing::APT::Test::Folder;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Folder;

sub test_can_create_folder_and_set_all_fields : Test(8) {

    my $folder = Yahoo::Marketing::APT::Folder->new
                                         ->ID( 'id' )
                                         ->accountID( 'account id' )
                                         ->createTimestamp( '2009-01-06T17:51:55' )
                                         ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                         ->name( 'name' )
                                         ->parentFolderID( 'parent folder id' )
                                         ->type( 'type' )
                   ;

    ok( $folder );

    is( $folder->ID, 'id', 'can get id' );
    is( $folder->accountID, 'account id', 'can get account id' );
    is( $folder->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $folder->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $folder->name, 'name', 'can get name' );
    is( $folder->parentFolderID, 'parent folder id', 'can get parent folder id' );
    is( $folder->type, 'type', 'can get type' );

};



1;

