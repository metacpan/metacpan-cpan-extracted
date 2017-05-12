package Yahoo::Marketing::APT::Test::User;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::User;

sub test_can_create_user_and_set_all_fields : Test(18) {

    my $user = Yahoo::Marketing::APT::User->new
                                     ->ID( 'id' )
                                     ->createTimestamp( '2009-01-06T17:51:55' )
                                     ->email( 'email' )
                                     ->fax( 'fax' )
                                     ->firstName( 'first name' )
                                     ->firstNameFurigana( 'first name furigana' )
                                     ->homePhone( 'home phone' )
                                     ->lastName( 'last name' )
                                     ->lastNameFurigana( 'last name furigana' )
                                     ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                     ->locale( 'locale' )
                                     ->middleInitial( 'middle initial' )
                                     ->mobilePhone( 'mobile phone' )
                                     ->status( 'status' )
                                     ->title( 'title' )
                                     ->userName( 'user name' )
                                     ->workPhone( 'work phone' )
                   ;

    ok( $user );

    is( $user->ID, 'id', 'can get id' );
    is( $user->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $user->email, 'email', 'can get email' );
    is( $user->fax, 'fax', 'can get fax' );
    is( $user->firstName, 'first name', 'can get first name' );
    is( $user->firstNameFurigana, 'first name furigana', 'can get first name furigana' );
    is( $user->homePhone, 'home phone', 'can get home phone' );
    is( $user->lastName, 'last name', 'can get last name' );
    is( $user->lastNameFurigana, 'last name furigana', 'can get last name furigana' );
    is( $user->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $user->locale, 'locale', 'can get locale' );
    is( $user->middleInitial, 'middle initial', 'can get middle initial' );
    is( $user->mobilePhone, 'mobile phone', 'can get mobile phone' );
    is( $user->status, 'status', 'can get status' );
    is( $user->title, 'title', 'can get title' );
    is( $user->userName, 'user name', 'can get user name' );
    is( $user->workPhone, 'work phone', 'can get work phone' );

};



1;

