#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Deep;
use MooseX::Params::Validate;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Customer qw( create_customer );
use Test::WWW::LogicBoxes::Contact qw( create_contact create_ca_contact );
use Test::WWW::LogicBoxes::DomainRegistration qw( test_domain_registration );

use WWW::LogicBoxes::Types qw( DomainRegistration );

use WWW::LogicBoxes::Domain;
use WWW::LogicBoxes::DomainRequest::Registration;

use DateTime;

my $customer           = create_customer();
my $registrant_contact = create_ca_contact( customer_id => $customer->id );
my $admin_contact      = create_ca_contact( customer_id => $customer->id );
my $technical_contact  = create_ca_contact( customer_id => $customer->id );

subtest 'Register Available Domain' => sub {
    my $request;
    lives_ok {
        $request = WWW::LogicBoxes::DomainRequest::Registration->new(
            name        => 'test-' . random_string('nnccnnccnnccnnccnnccnncc') . '.ca',
            years       => 1,
            customer_id => $customer->id,
            ns          => [ 'ns1.logicboxes.com', 'ns2.logicboxes.com' ],
            is_private  => 0,
            registrant_contact_id => $registrant_contact->id,
            admin_contact_id      => $admin_contact->id,
            technical_contact_id  => $technical_contact->id,
        );
    } 'Lives through creating request object';

    test_domain_registration( $request );
};

done_testing;
