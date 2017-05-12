package Yahoo::Marketing::Test::FileOutputFormat;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::FileOutputFormat;

sub test_can_create_file_output_format_and_set_all_fields : Test(3) {

    my $file_output_format = Yahoo::Marketing::FileOutputFormat->new
                                                               ->fileOutputType( 'file output type' )
                                                               ->zipped( 'zipped' )
                   ;

    ok( $file_output_format );

    is( $file_output_format->fileOutputType, 'file output type', 'can get file output type' );
    is( $file_output_format->zipped, 'zipped', 'can get zipped' );

};



1;

