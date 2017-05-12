package Yahoo::Marketing::APT::Test::Contact;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Contact;

sub test_can_create_contact_and_set_all_fields : Test(19) {

    my $contact = Yahoo::Marketing::APT::Contact->new
                                           ->ID( 'id' )
                                           ->createTimestamp( '2009-01-06T17:51:55' )
                                           ->email( 'email' )
                                           ->fax( 'fax' )
                                           ->firstName( 'first name' )
                                           ->firstNameFurigana( 'first name furigana' )
                                           ->homePhone( 'home phone' )
                                           ->isActive( 'is active' )
                                           ->isPrimary( 'is primary' )
                                           ->lastName( 'last name' )
                                           ->lastNameFurigana( 'last name furigana' )
                                           ->lastUpdateTimestamp( '2009-01-07T17:51:55' )
                                           ->locale( 'locale' )
                                           ->middleInitial( 'middle initial' )
                                           ->mobilePhone( 'mobile phone' )
                                           ->title( 'title' )
                                           ->username( 'username' )
                                           ->workPhone( 'work phone' )
                   ;

    ok( $contact );

    is( $contact->ID, 'id', 'can get id' );
    is( $contact->createTimestamp, '2009-01-06T17:51:55', 'can get 2009-01-06T17:51:55' );
    is( $contact->email, 'email', 'can get email' );
    is( $contact->fax, 'fax', 'can get fax' );
    is( $contact->firstName, 'first name', 'can get first name' );
    is( $contact->firstNameFurigana, 'first name furigana', 'can get first name furigana' );
    is( $contact->homePhone, 'home phone', 'can get home phone' );
    is( $contact->isActive, 'is active', 'can get is active' );
    is( $contact->isPrimary, 'is primary', 'can get is primary' );
    is( $contact->lastName, 'last name', 'can get last name' );
    is( $contact->lastNameFurigana, 'last name furigana', 'can get last name furigana' );
    is( $contact->lastUpdateTimestamp, '2009-01-07T17:51:55', 'can get 2009-01-07T17:51:55' );
    is( $contact->locale, 'locale', 'can get locale' );
    is( $contact->middleInitial, 'middle initial', 'can get middle initial' );
    is( $contact->mobilePhone, 'mobile phone', 'can get mobile phone' );
    is( $contact->title, 'title', 'can get title' );
    is( $contact->username, 'username', 'can get username' );
    is( $contact->workPhone, 'work phone', 'can get work phone' );

};



1;

