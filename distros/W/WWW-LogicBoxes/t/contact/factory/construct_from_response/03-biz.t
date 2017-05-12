#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use WWW::LogicBoxes::Contact::Factory;

subtest 'Construct biz contact' => sub {
    my $response = {
        'roid'            => 'Some ID',
        'emailaddr'       => 'test@emailaddress.com',
        'entitytypeid'    => '66',
        'contactstatus'   => 'Active',
        'jumpConditions'  => [],
        'telnocc'         => '1',
        'classname'       => 'com.logicboxes.foundation.sfnb.order.domcontact.DomContact',
        'telno'           => '8005551212',
        'state'           => 'TX',
        'city'            => 'Houston',
        'actioncompleted' => '0',
        'entityid'        => '123',
        'company'         => 'Testing',
        'country'         => 'US',
        'contactid'       => '123',
        'name'            => 'Ima Test',
        'description'     => 'DomainContact',
        'parentkey'       => '999999999_99999',
        'address2'        => 'Suite 123',
        'passwd'          => 'Top Secret',
        'eaqid'           => '0',
        'zip'             => '12345',
        'contacttype'     => [ 'dombiz' ],
        'currentstatus'   => 'Active',
        'customerid'      => '123',
        'type'            => 'Contact',
        'address1'        => '123 Main Str',
        'classkey'        => 'domcontact'
    };

    my $contact;
    lives_ok {
        $contact = WWW::LogicBoxes::Contact::Factory->construct_from_response( $response );
    } 'Lives through construction of contact';

    isa_ok( $contact, 'WWW::LogicBoxes::Contact' );
};

done_testing;
