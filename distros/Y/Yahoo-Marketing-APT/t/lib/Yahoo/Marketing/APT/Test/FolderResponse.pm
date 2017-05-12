package Yahoo::Marketing::APT::Test::FolderResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::FolderResponse;

sub test_can_create_folder_response_and_set_all_fields : Test(4) {

    my $folder_response = Yahoo::Marketing::APT::FolderResponse->new
                                                          ->errors( 'errors' )
                                                          ->folder( 'folder' )
                                                          ->operationResult( 'operation result' )
                   ;

    ok( $folder_response );

    is( $folder_response->errors, 'errors', 'can get errors' );
    is( $folder_response->folder, 'folder', 'can get folder' );
    is( $folder_response->operationResult, 'operation result', 'can get operation result' );

};



1;

