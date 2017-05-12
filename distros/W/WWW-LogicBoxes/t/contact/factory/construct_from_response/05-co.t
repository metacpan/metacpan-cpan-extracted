#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use WWW::LogicBoxes::Contact::Factory;

subtest 'Construct co contact' => sub {
    my $response = {
        'roid'            => '123',
        'emailaddr'       => 'test@emailaddress.com',
        'contactstatus'   => 'Active',
        'entitytypeid'    => '66',
        'jumpConditions'  => [],
        'telnocc'         => '1',
        'classname'       => 'com.logicboxes.foundation.sfnb.order.domcontact.DomContact',
        'telno'           => '8005551212',
        'state'           => 'TX',
        'city'            => 'Houston',
        'actioncompleted' => '0',
        'company'         => 'Test Company',
        'entityid'        => '123',
        'country'         => 'US',
        'contactid'       => '123',
        'name'            => 'Iam Test',
        'description'     => 'DomainContact',
        'parentkey'       => '123',
        'passwd'          => 'Top Secret',
        'eaqid'           => '0',
        'zip'             => '77092',
        'contacttype'     => [ 'thirdleveldotco' ],
        'currentstatus'   => 'Active',
        'customerid'      => '123',
        'type'            => 'CoContact',
        'address1'        => '123 Main Str',
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
