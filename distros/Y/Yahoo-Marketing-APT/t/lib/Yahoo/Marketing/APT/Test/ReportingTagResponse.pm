package Yahoo::Marketing::APT::Test::ReportingTagResponse;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ReportingTagResponse;

sub test_can_create_reporting_tag_response_and_set_all_fields : Test(4) {

    my $reporting_tag_response = Yahoo::Marketing::APT::ReportingTagResponse->new
                                                                       ->errors( 'errors' )
                                                                       ->operationSucceeded( 'operation succeeded' )
                                                                       ->reportingTag( 'reporting tag' )
                   ;

    ok( $reporting_tag_response );

    is( $reporting_tag_response->errors, 'errors', 'can get errors' );
    is( $reporting_tag_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $reporting_tag_response->reportingTag, 'reporting tag', 'can get reporting tag' );

};



1;

