package Yahoo::Marketing::APT::Test::ReportColumn;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ReportColumn;

sub test_can_create_report_column_and_set_all_fields : Test(5) {

    my $report_column = Yahoo::Marketing::APT::ReportColumn->new
                                                      ->ID( 'id' )
                                                      ->description( 'description' )
                                                      ->format( 'format' )
                                                      ->name( 'name' )
                   ;

    ok( $report_column );

    is( $report_column->ID, 'id', 'can get id' );
    is( $report_column->description, 'description', 'can get description' );
    is( $report_column->format, 'format', 'can get format' );
    is( $report_column->name, 'name', 'can get name' );

};



1;

