#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use WWW::LogicBoxes::Contact::Factory;

subtest 'Construct biz contact' => sub {
    my $response = {
        'roid'            => '123',
        'emailaddr'       => 'test@emailaddress.com',
        'entitytypeid'    => '66',
        'contactstatus'   => 'Active',
        'telnocc'         => '1',
        'jumpConditions'  => [],
        'state'           => 'TX',
        'telno'           => '18005551212',
        'classname'       => 'com.logicboxes.foundation.sfnb.order.domcontact.DomContact',
        'city'            => 'Houston',
        'actioncompleted' => '0',
        'entityid'        => '123',
        'company'         => 'None',
        'country'         => 'US',
        'contactid'       => '123',
        'name'            => 'Iam ATest',
        'description'     => 'DomainContact',
        'parentkey'       => '123',
        'passwd'          => 'Top Secret',
        'zip'             => '77092',
        'eaqid'           => '0',
        'currentstatus'   => 'Active',
        'contacttype'     => [ 'dotclub' ],
        'customerid'      => '123',
        'address1'        => '123 Main St',
        'type'            => 'Contact',
        'classkey'        => 'domcontact'
    };

    my $contact;
    lives_ok {
        $contact =
          WWW::LogicBoxes::Contact::Factory->construct_from_response($response);
    }
    'Lives through construction of contact';

    isa_ok( $contact, 'WWW::LogicBoxes::Contact' );
};

done_testing;
