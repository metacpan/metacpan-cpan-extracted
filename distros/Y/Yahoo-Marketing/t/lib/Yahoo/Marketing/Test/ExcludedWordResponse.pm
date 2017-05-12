package Yahoo::Marketing::Test::ExcludedWordResponse;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ExcludedWordResponse;

sub test_can_create_excluded_word_response_and_set_all_fields : Test(5) {

    my $excluded_word_response = Yahoo::Marketing::ExcludedWordResponse->new
                                                                       ->errors( 'errors' )
                                                                       ->excludedWord( 'excluded word' )
                                                                       ->operationSucceeded( 'operation succeeded' )
                                                                       ->warnings( 'warnings' )
                   ;

    ok( $excluded_word_response );

    is( $excluded_word_response->errors, 'errors', 'can get errors' );
    is( $excluded_word_response->excludedWord, 'excluded word', 'can get excluded word' );
    is( $excluded_word_response->operationSucceeded, 'operation succeeded', 'can get operation succeeded' );
    is( $excluded_word_response->warnings, 'warnings', 'can get warnings' );

};



1;

