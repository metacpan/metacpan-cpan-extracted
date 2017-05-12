package Yahoo::Marketing::Test::DownloadFile;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::DownloadFile;

sub test_can_create_download_file_and_set_all_fields : Test(3) {

    my $download_file = Yahoo::Marketing::DownloadFile->new
                                                      ->fileFormat( 'file format' )
                                                      ->outputFile( 'output file' )
                   ;

    ok( $download_file );

    is( $download_file->fileFormat, 'file format', 'can get file format' );
    is( $download_file->outputFile, 'output file', 'can get output file' );

};



1;

