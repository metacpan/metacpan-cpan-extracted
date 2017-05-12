#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Storable qw( dclone );

use WWW::eNom::Contact;

my $DEFAULT_CONTACT = {
    first_name   => 'Ada',
    last_name    => 'Byron',
    address1     => 'University of London',
    city         => 'London',
    country      => 'GB',
    zipcode      => 'WC1E 7HU',
    email        => 'ada@testing.com',
    phone_number => '18005551212',
};

subtest 'No Organization Name' => sub {
    subtest 'Missing job_title and fax_number' => sub {
        my $contact_data = dclone $DEFAULT_CONTACT;

        lives_ok {
            WWW::eNom::Contact->new( $contact_data );
        } 'Lives through creation of Contact';
    };

    subtest 'With job_title and fax_number' => sub {
        my $contact_data = dclone $DEFAULT_CONTACT;
        $contact_data->{fax_number} = '18005551212';
        $contact_data->{job_title} = 'Countess of Lovelace';

        lives_ok {
            WWW::eNom::Contact->new( $contact_data );
        } 'Lives through creation of Contact with organization data';
    };
};

subtest 'With Organization Name' => sub {
    subtest 'Missing job_title' => sub {
        my $contact_data                   = dclone $DEFAULT_CONTACT;
        $contact_data->{organization_name} = 'Lovelace';
        $contact_data->{fax_number}        = '18005551212';

        ## no critic ( RegularExpressions::ProhibitComplexRegexes )
        throws_ok {
            WWW::eNom::Contact->new( $contact_data );
        } qr/Contacts with an organization_name require a job_title and fax_number/,
        'Throws on incomplete object';
        ## use critic
    };

    subtest 'Missing fax_number' => sub {
        my $contact_data                   = dclone $DEFAULT_CONTACT;
        $contact_data->{organization_name} = 'Lovelace';
        $contact_data->{job_title}         = 'Countess of Lovelace';

        ## no critic ( RegularExpressions::ProhibitComplexRegexes )
        throws_ok {
            WWW::eNom::Contact->new( $contact_data );
        } qr/Contacts with an organization_name require a job_title and fax_number/,
        'Throws on incomplete object';
        ## use critic
    };

    subtest 'Contains Required Fields' => sub {
        my $contact_data                   = dclone $DEFAULT_CONTACT;
        $contact_data->{organization_name} = 'Lovelace';
        $contact_data->{fax_number}        = '18005551212';
        $contact_data->{job_title}         = 'Countess of Lovelace';

        lives_ok {
            WWW::eNom::Contact->new( $contact_data );
        } 'Lives through creation of Contact with organization data';
    };
};

done_testing;
