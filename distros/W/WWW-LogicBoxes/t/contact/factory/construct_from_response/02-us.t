#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use WWW::LogicBoxes::Contact::Factory;

subtest 'Construct us contact - With Nexus Data' => sub {
    my $response = {
        'roid'               => 'DI_61423218',
        'emailaddr'          => 'test-za55uu57bx51rj71ze36cx47@testing.com',
        'entitytypeid'       => '66',
        'contactstatus'      => 'Active',
        'telnocc'            => '1',
        'jumpConditions'     => [],
        'state'              => 'Texas',
        'telno'              => '5124757575',
        'classname'          => 'com.logicboxes.foundation.sfnb.order.domcontact.DomContact',
        'city'               => 'Austin',
        'actioncompleted'    => '0',
        'entityid'           => '61423218',
        'company'            => 'University of Texas at Austin',
        'country'            => 'US',
        'contactid'          => '61423218',
        'name'               => 'Edsger Dijkstra',
        'description'        => 'DomainContact',
        'parentkey'          => '999999999_999999998_465229',
        'passwd'             => 'bfvpQ3LHmT',
        'zip'                => '78713',
        'eaqid'              => '0',
        'currentstatus'      => 'Active',
        'contacttype'        => [ 'domus' ],
        'customerid'         => '16119376',
        'address1'           => 'University of Texas',
        'type'               => 'Contact',
        'classkey'           => 'domcontact',
        'ApplicationPurpose' => 'P1',
        'NexusCategory'      => 'C11',
    };

    my $contact;
    lives_ok {
        $contact =
          WWW::LogicBoxes::Contact::Factory->construct_from_response($response);
    }
    'Lives through construction of contact';

    isa_ok( $contact, 'WWW::LogicBoxes::Contact::US' );
};

subtest 'Construct us contact - Missing Nexus Data' => sub {
    my $response = {
        'roid'               => 'DI_61423218',
        'emailaddr'          => 'test-za55uu57bx51rj71ze36cx47@testing.com',
        'entitytypeid'       => '66',
        'contactstatus'      => 'Active',
        'telnocc'            => '1',
        'jumpConditions'     => [],
        'state'              => 'Texas',
        'telno'              => '5124757575',
        'classname'          => 'com.logicboxes.foundation.sfnb.order.domcontact.DomContact',
        'city'               => 'Austin',
        'actioncompleted'    => '0',
        'entityid'           => '61423218',
        'company'            => 'University of Texas at Austin',
        'country'            => 'US',
        'contactid'          => '61423218',
        'name'               => 'Edsger Dijkstra',
        'description'        => 'DomainContact',
        'parentkey'          => '999999999_999999998_465229',
        'passwd'             => 'bfvpQ3LHmT',
        'zip'                => '78713',
        'eaqid'              => '0',
        'currentstatus'      => 'Active',
        'contacttype'        => [ 'domus' ],
        'customerid'         => '16119376',
        'address1'           => 'University of Texas',
        'type'               => 'Contact',
        'classkey'           => 'domcontact',
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
