package Yahoo::Marketing::Test::User;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::User;

sub test_can_create_user_and_set_all_fields : Test(13) {

    my $user = Yahoo::Marketing::User->new
                                     ->email( 'email' )
                                     ->fax( 'fax' )
                                     ->firstName( 'first name' )
                                     ->firstNameFurigana( 'first name furigana' )
                                     ->lastName( 'last name' )
                                     ->lastNameFurigana( 'last name furigana' )
                                     ->locale( 'locale' )
                                     ->middleInitial( 'middle initial' )
                                     ->mobilePhone( 'mobile phone' )
                                     ->timezone( 'timezone' )
                                     ->title( 'title' )
                                     ->workPhone( 'work phone' )
                   ;

    ok( $user );

    is( $user->email, 'email', 'can get email' );
    is( $user->fax, 'fax', 'can get fax' );
    is( $user->firstName, 'first name', 'can get first name' );
    is( $user->firstNameFurigana, 'first name furigana', 'can get first name furigana' );
    is( $user->lastName, 'last name', 'can get last name' );
    is( $user->lastNameFurigana, 'last name furigana', 'can get last name furigana' );
    is( $user->locale, 'locale', 'can get locale' );
    is( $user->middleInitial, 'middle initial', 'can get middle initial' );
    is( $user->mobilePhone, 'mobile phone', 'can get mobile phone' );
    is( $user->timezone, 'timezone', 'can get timezone' );
    is( $user->title, 'title', 'can get title' );
    is( $user->workPhone, 'work phone', 'can get work phone' );

};



1;

