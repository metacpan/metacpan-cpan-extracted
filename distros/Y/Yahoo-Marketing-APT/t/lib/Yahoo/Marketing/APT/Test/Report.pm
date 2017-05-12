package Yahoo::Marketing::APT::Test::Report;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Report;

sub test_can_create_report_and_set_all_fields : Test(5) {

    my $report = Yahoo::Marketing::APT::Report->new
                                         ->columns( 'columns' )
                                         ->context( 'context' )
                                         ->description( 'description' )
                                         ->name( 'name' )
                   ;

    ok( $report );

    is( $report->columns, 'columns', 'can get columns' );
    is( $report->context, 'context', 'can get context' );
    is( $report->description, 'description', 'can get description' );
    is( $report->name, 'name', 'can get name' );

};



1;

