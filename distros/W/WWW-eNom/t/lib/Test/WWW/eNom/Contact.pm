package Test::WWW::eNom::Contact;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockModule;
use String::Random qw( random_string );
use MooseX::Params::Validate;

use Test::WWW::eNom qw( mock_response );

use WWW::eNom::Types qw( EmailAddress PhoneNumber Str );
use WWW::eNom::Contact;

use Readonly;
Readonly our $DEFAULT_CONTACT => WWW::eNom::Contact->new(
    first_name   => 'Ada',
    last_name    => 'Byron',
    address1     => 'University of London',
    city         => 'London',
    country      => 'GB',
    zipcode      => 'WC1E 7HU',
    email        => 'ada-' . random_string('ccnnccnnccnnccnnccnnccnn') . '@testing.com',
    phone_number => '18005551212',
);

Readonly our $RAW_PROTECTED_CONTACT => {
    'ConsentStatus'    => 'PENDING',
    'FirstName'        => 'Data Protected',
    'LastName'         => 'Data Protected',
    'EmailAddress'     => 'noreply@data-protected.net',
    'JobTitle'         => 'Data Protected',
    'OrganizationName' => 'Data Protected',
    'Address1'         => '123 Data Protected',
    'Address2'         => {},
    'City'             => 'Kirkland',
    'StateProvince'    => 'WA',
    'Country'          => 'US',
    'PostalCode'       => '98033',
    'Phone'            => '+1.8005551212',
    'PhoneExt'         => {},
    'Fax'              => '+1.0000000000',
};

use Exporter 'import';
our @EXPORT_OK = qw(
    create_contact
    mock_get_contacts
    $DEFAULT_CONTACT
    $RAW_PROTECTED_CONTACT
);

sub create_contact {
    my ( %args ) = validated_hash(
        \@_,
        first_name        => { isa => Str, optional => 1 },
        last_name         => { isa => Str, optional => 1 },
        organization_name => { isa => Str, optional => 1 },
        job_title         => { isa => Str, optional => 1 },
        address1          => { isa => Str, optional => 1 },
        address2          => { isa => Str, optional => 1 },
        city              => { isa => Str, optional => 1 },
        state             => { isa => Str, optional => 1 },
        country           => { isa => Str, optional => 1 },
        zipcode           => { isa => Str, optional => 1 },
        email             => { isa => EmailAddress, optional => 1 },
        phone_number      => { isa => PhoneNumber,  optional => 1, coerce => 1 },
        fax_number        => { isa => PhoneNumber,  optional => 1, coerce => 1 },
    );

    if( $args{organization_name} ) {
        $args{job_title}  //= 'Countess of Lovelace';
        $args{fax_number} //= '18005551212';
    }

    $args{first_name}   //= 'Ada';
    $args{last_name}    //= 'Byron';
    $args{address1}     //= 'University of London';
    $args{city}         //= 'London';
    $args{country}      //= 'GB';
    $args{zipcode}      //= 'WC1E 7HU';
    $args{email}        //= 'ada-' . random_string('ccnnccnnccnnccnnccnnccnn') . '@testing.com';
    $args{phone_number} //= '18005551212';

    my $contact;
    subtest 'Create Contact' => sub {
        lives_ok {
            $contact = WWW::eNom::Contact->new( %args );
        } 'Lives through contact creation';

        note( 'Contact Email: ' . $contact->email );
    };

    return $contact;
}

sub mock_get_contacts {
    my ( %args ) = validated_hash(
        \@_,
        mocked_api              => { isa => 'Test::MockModule',   optional => 1 },
        is_pending_verification => { isa => 'Bool',               default  => 0 },
        registrant_contact      => { isa => 'WWW::eNom::Contact', optional => 1 },
        admin_contact           => { isa => 'WWW::eNom::Contact', optional => 1 },
        technical_contact       => { isa => 'WWW::eNom::Contact', optional => 1 },
        billing_contact         => { isa => 'WWW::eNom::Contact', optional => 1 },
    );

    my $registrant_contact = $args{registrant_contact} // create_contact();
    my $admin_contact      = $args{admin_contact}      // create_contact();
    my $technical_contact  = $args{technical_contact}  // create_contact();
    my $billing_contact    = $args{billing_contact}    // create_contact();

    return mock_response(
        defined $args{mocked_api} ? ( mocked_api => $args{mocked_api} ) : ( ),
        method   => 'GetContacts',
        response => {
            'ErrCount'    => '0',
            'errors'      => undef,
            'GetContacts' => {
                'PendingVerification' => ( $args{is_pending_verification} ? 'True' : 'False' ),
                'Billing' => {
                    'BillingPartyID' => '{94fa74a9-7a03-e311-8a25-bc305bf0feec}',
                    %{ $billing_contact->construct_creation_request( 'Billing' ) },
                },
                'Tech' => {
                    'TechPartyID' => {},
                    %{ $technical_contact->construct_creation_request( 'Tech' ) },
                },
                'Admin' => {
                    'AdminPartyID' => {},
                    %{ $admin_contact->construct_creation_request( 'Admin' ) },
                },
                'Registrant' => {
                    'RegistrantPartyID' => {},
                    %{ $registrant_contact->construct_creation_request( 'Registrant' ) },
                },
                'AuxBilling' => {
                    'AuxBillingPartyID' => '',
                    %{ $billing_contact->construct_creation_request( 'AuxBilling' ) },
                },
            },
        },
    );
}

1;
