#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use WWW::LogicBoxes::Contact::Factory;

subtest 'Construct com contact' => sub {
    my $response = {
        'emailaddr'       => 'testsoigniomiief@hostgator.com',
        'entitytypeid'    => '66',
        'contactstatus'   => 'Active',
        'telnocc'         => '1',
        'jumpConditions'  => [],
        'state'           => 'TX',
        'telno'           => '7135745287',
        'classname'       => 'com.logicboxes.foundation.sfnb.order.domcontact.DomContact',
        'city'            => 'Houston',
        'actioncompleted' => '0',
        'entityid'        => '61418983',
        'company'         => 'Oxford University',
        'country'         => 'US',
        'contactid'       => '61418983',
        'name'            => 'Andrew Wiles',
        'description'     => 'DomainContact',
        'parentkey'       => '999999999_999999998_465229',
        'zip'             => '77027',
        'eaqid'           => '0',
        'currentstatus'   => 'Active',
        'contacttype'     => [],
        'customerid'      => '16118292',
        'address1'        => '123i Oxford University Way',
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
