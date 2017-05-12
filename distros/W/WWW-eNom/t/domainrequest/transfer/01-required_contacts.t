#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../lib";
use Test::WWW::eNom::Contact qw( $DEFAULT_CONTACT );

use WWW::eNom::DomainRequest::Transfer;

subtest 'Autoverification - New Contacts - No Contacts' => sub {
    throws_ok {
        WWW::eNom::DomainRequest::Transfer->new(
            name                  => 'test.com',
            epp_key               => '12345',
            verification_method   => 'Autoverification',
            use_existing_contacts => 0,
        );
    } qr/If not using existing contacts the registrant contact must be specified/, 'Throws on Invalid Transfer';
};

subtest 'Autoverification - Existing Contacts - With Contacts' => sub {
    throws_ok {
        WWW::eNom::DomainRequest::Transfer->new(
            name                  => 'test.com',
            epp_key               => '12345',
            verification_method   => 'Autoverification',
            use_existing_contacts => 1,
            registrant_contact    => $DEFAULT_CONTACT,
            admin_contact         => $DEFAULT_CONTACT,
            technical_contact     => $DEFAULT_CONTACT,
            billing_contact       => $DEFAULT_CONTACT,
        );
    } qr/When using existing contacts the registrant contact must not be specified/, 'Throws on Invalid Transfer';
};

subtest 'Autoverification - New Contacts - With Contacts' => sub {
    lives_ok {
        WWW::eNom::DomainRequest::Transfer->new(
            name                  => 'test.com',
            epp_key               => '12345',
            verification_method   => 'Autoverification',
            use_existing_contacts => 0,
            registrant_contact    => $DEFAULT_CONTACT,
            admin_contact         => $DEFAULT_CONTACT,
            technical_contact     => $DEFAULT_CONTACT,
            billing_contact       => $DEFAULT_CONTACT,
        );
    } 'Lives through creation of Valid Transfer';
};

subtest 'Autoverification - Existing Contacts - No Contacts' => sub {
    lives_ok {
        WWW::eNom::DomainRequest::Transfer->new(
            name                  => 'test.com',
            epp_key               => '12345',
            verification_method   => 'Autoverification',
            use_existing_contacts => 1,
        );
    } 'Lives through creation of Valid Transfer';
};

subtest 'Fax - Existing Contacts - No Registrant' => sub {
    throws_ok {
        WWW::eNom::DomainRequest::Transfer->new(
            name                  => 'test.com',
            epp_key               => '12345',
            verification_method   => 'Fax',
            use_existing_contacts => 1,
        );
    } qr/If using Fax verification, a registrant contact must be specified/, 'Throws on Invalid Transfer';
};

subtest 'Fax - Existing Contacts - With Registrant' => sub {
    lives_ok {
        WWW::eNom::DomainRequest::Transfer->new(
            name                  => 'test.com',
            epp_key               => '12345',
            verification_method   => 'Fax',
            use_existing_contacts => 1,
            registrant_contact    => $DEFAULT_CONTACT,
        );
    } 'Lives through creation of Valid Transfer';
};

subtest 'Fax - New Contacts - With Contacts' => sub {
    lives_ok {
        WWW::eNom::DomainRequest::Transfer->new(
            name                  => 'test.com',
            epp_key               => '12345',
            verification_method   => 'Fax',
            use_existing_contacts => 0,
            registrant_contact    => $DEFAULT_CONTACT,
            admin_contact         => $DEFAULT_CONTACT,
            technical_contact     => $DEFAULT_CONTACT,
            billing_contact       => $DEFAULT_CONTACT,
        );
    } 'Lives through creation of Valid Transfer';
};

done_testing;
