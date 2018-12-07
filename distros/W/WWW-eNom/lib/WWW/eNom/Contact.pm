package WWW::eNom::Contact;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Params::Validate;
use namespace::autoclean;

use WWW::eNom::Types qw( RawContactType EmailAddress HashRef PhoneNumber Str );

use WWW::eNom::PhoneNumber;

use Data::Util qw( is_string );
use Try::Tiny;
use Carp;

our $VERSION = 'v2.7.0'; # VERSION
# ABSTRACT: Representation of eNom Contact

has 'first_name' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has 'last_name' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has 'organization_name' => (
    is        => 'rw',
    isa       => Str,
    predicate => 'has_organization_name',
    clearer   => 'clear_organization_name',
);

has 'job_title' => (
    is        => 'rw',
    isa       => Str,
    predicate => 'has_job_title',
    clearer   => 'clear_job_title',
);

has 'address1' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has 'address2' => (
    is        => 'rw',
    isa       => Str,
    predicate => 'has_address2',
    clearer   => 'clear_address2',
);

has 'city' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has 'state' => (
    is        => 'rw',
    isa       => Str,
    predicate => 'has_state',
    clearer   => 'clear_state',
);

has 'country' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has 'zipcode' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has 'email' => (
    is       => 'rw',
    isa      => EmailAddress,
    required => 1,
);

has 'phone_number' => (
    is       => 'rw',
    isa      => PhoneNumber,
    required => 1,
    coerce   => 1,
);

has 'fax_number' => (
    is        => 'rw',
    isa       => PhoneNumber,
    predicate => 'has_fax_number',
    clearer   => 'clear_fax_number',
    coerce    => 1,
);

sub BUILD {
    my $self = shift;

    if( $self->has_organization_name ) {
        if( !$self->has_job_title || !$self->has_fax_number ) {
            croak 'Contacts with an organization_name require a job_title and fax_number';
        }
    }
}

sub construct_creation_request {
    my $self = shift;
    my ( $contact_type ) = pos_validated_list( \@_, { isa => RawContactType, optional => 1 } );

    my $creation_request = {
        FirstName    => $self->first_name,
        LastName     => $self->last_name,
        $self->has_organization_name ? ( OrganizationName => $self->organization_name ) : ( ),
        $self->has_job_title         ? ( JobTitle         => $self->job_title         ) : ( ),
        Address1     => $self->address1,
        $self->has_address2          ? ( Address2         => $self->address2          ) : ( ),
        City         => $self->city,
        $self->has_state             ? ( StateProvince    => $self->state             ) : ( ),
        Country      => $self->country,
        PostalCode   => $self->zipcode,
        EmailAddress => $self->email,
        Phone        => sprintf('+%s.%s', $self->phone_number->country_code, $self->phone_number->number ),
        $self->has_fax_number ? ( Fax => sprintf('+%s.%s', $self->fax_number->country_code, $self->fax_number->number ) ) : ( ),
    };

    if( $contact_type ) {
        for my $key ( keys %{ $creation_request } ) {
            $creation_request->{ $contact_type . $key } = delete $creation_request->{ $key };
        }
    }

    return $creation_request;
}

sub construct_from_response {
    my $self         = shift;
    my ( $raw_response ) = pos_validated_list( \@_, { isa => HashRef } );

    # Some routes return 'FirstName' some 'RegistrantFirstName'
    # This logic is meant to normalize that structure
    my $response;
    for my $prefix (qw( Admin Administrative Registrant Tech Technical AuxBilling )) {
        if( exists $raw_response->{ $prefix . 'FirstName' } ) {
            for my $key ( keys %{ $raw_response } ) {
                $response->{ substr( $key, length $prefix ) } = $raw_response->{ $key };
            }

            last;
        }
    }

    $response //= $raw_response;

    return try {
        return $self->new({
            first_name        => $response->{'FirstName'},
            last_name         => $response->{'LastName'},
            is_string( $response->{'OrganizationName'} ) ? ( organization_name => $response->{'OrganizationName'} ) : ( ),
            is_string( $response->{'JobTitle'}         ) ? ( job_title         => $response->{'JobTitle'}         ) : ( ),
            address1          => $response->{'Address1'},
            is_string( $response->{'Address2'}         ) ? ( address2          => $response->{'Address2'}         ) : ( ),
            city              => $response->{'City'},
            is_string( $response->{'StateProvince'}    ) ? ( state             => $response->{'StateProvince'}    ) : ( ),
            country           => $response->{'Country'},
            zipcode           => $response->{'PostalCode'},
            email             => $response->{'EmailAddress'},
            phone_number      => $response->{'Phone'},
            is_string( $response->{'Fax'}             ) ? ( fax_number        => $response->{'Fax'}              ) : ( ),
        });
    }
    catch {
        croak "Error constructing contact from response: $_";
    };
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

WWW::eNom::Contact - Representation of eNom Contact

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::eNom;
    use WWW::eNom::Contact;

    my $api     = WWW::eNom->new( ... );
    my $contact = WWW::eNom::Contact->new( ... );

    # New Contact Object
    my $contact = WWW::eNom::Contact->new(
        first_name        => 'Ada',
        last_name         => 'Byron',
        organization_name => 'Lovelace',                # Optional
        job_title         => 'Countess',                # Optional if no organization_name, otherwise required
        address1          => 'University of London',
        address2          => 'Analytical Engine Dept',  # Optional
        city              => 'London',
        #state            => 'Texas',                   # Optional, primarily used for US Contacts
        country           => 'GB',
        zipcode           => 'WC1E 7HU',
        email             => 'ada.byron@lovelace.com',
        phone_number      => '18005551212',
        fax_number        => '18005551212',             # Optional if no organization_name, otherwise required
    );

    # Contact Creation
    my $registrant_contact_creation_payload = $contact->construct_creation_request('Registrant');
    my $admin_contact_creation_payload      = $contact->construct_creation_request('Admin');
    my $technical_contact_creation_payload  = $contact->construct_creation_request('Tech');
    my $billing_contact_creation_payload    = $contact->construct_creation_request('AuxBilling');

    my $response = $api->submit({
        method => 'Purchase',
        params => {
            ...,
            %{ $registrant_contact_creation_payload },
            %{ $admin_contact_creation_payload },
            %{ $technical_contact_creation_payload },
            %{ $billing_contact_creation_payload },
        }
    });

    # Contact Retrieval
    my $response = $self->submit({
        method => 'GetContacts',
        params => {
            Domain => $domain_name
        }
    });

    my $contacts;
    for my $contact_type (qw( Registrant Admin Tech AuxBilling )) {
        my $raw_contact_response = $response->{GetContacts}{$contact_type};

        my $common_contact_response;
        for my $field ( keys %{ $raw_contact_response } ) {
            if( $field !~ m/$contact_type/ ) {
                next;
            }

            $common_contact_response->{ substr( $field, length( $contact_type ) ) } =
                $raw_contact_response->{ $field } // { };
        }

        $contacts->{ $contact_type } = WWW::eNom::Contact->construct_from_response( $common_contact_response );
    }


=head1 DESCRIPTION

Representation of an L<eNom|http://www.enom.com> Contact.

=head1 ATTRIBUTES

=head2 B<first_name>

=head2 B<last_name>

=head2 organization_name

Predicate of has_organization_name and clearer of clear_organization_name.

B<NOTE> If the organization_name is specified then the previously optional L<job_title|WWW::eNom::Contact/job_title> and L<fax_number|WWW::eNom::Contact/fax_number> attributes become B<required>.

=head2 job_title

Predicate of has_job_title and clearer of clear_job_title.

B<NOTE> this field is B<required> if an L<organization_name|WWW::eNom::Contact/organization_name> was provided.

=head2 B<address1>

=head2 address2

Predicate of has_address2 and clearer of clear_address2

=head2 B<city>

=head2 state

Required for Contacts with a US Address, the full name of the state so Texas rather than TX should be used.

Predicate of has_state and clearer of clear_state.

=head2 B<country>

The L<ISO-3166-1 alpha-2 (two character country code)|https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2> is preferred.  You can use a full country name, just keep in mind your response from eNom will be the country code.

=head2 B<zipcode>

=head2 B<email>

=head2 B<phone_number>

An instance of L<WWW::eNom::PhoneNumber>, but this will coerce from a L<Number::Phone> object or a string based representation of the phone number.  This will also stringify to a human readable phone number.

=head2 fax_number

An instance of L<WWW::eNom::PhoneNumber>, but this will coerce from a L<Number::Phone> object or a string based representation of the phone number.  This will also stringify to a human readable phone number.

Predicate of has_fax_number and clearer of clear_fax_number.

B<NOTE> this field is B<required> if an L<organization_name|WWW::eNom::Contact/organization_name> was provided.

=head1 METHODS

=head2 construct_creation_request

    my $api     = WWW::eNom->new( ... );
    my $contact = WWW::eNom::Contact->new( ... );

    my $registrant_contact_creation_payload = $contact->construct_creation_request('Registrant');
    my $admin_contact_creation_payload      = $contact->construct_creation_request('Admin');
    my $technical_contact_creation_payload  = $contact->construct_creation_request('Tech');
    my $billing_contact_creation_payload    = $contact->construct_creation_request('AuxBilling');

    my $response = $api->submit({
        method => 'Purchase',
        params => {
            ...,
            %{ $registrant_contact_creation_payload },
            %{ $admin_contact_creation_payload },
            %{ $technical_contact_creation_payload },
            %{ $billing_contact_creation_payload },
        }
    });

Converts $self into a HashRef suitable for creation of a contact with L<eNom|https://www.enom.com>.  Accepts a string that must be one of the following:

=over 4

=item Registrant

=item Admin

=item Tech

=item AuxBilling

AuxBilling is what eNom calls the "Billing" contact for WHOIS data since the Billing contact is actually the reseller.

=back

=head2 construct_from_response

    my $response = $api->submit({
        method => 'GetContacts',
        params => {
            Domain => $domain_name
        }
    });

    my $contacts;
    for my $contact_type (qw( Registrant Admin Tech AuxBilling )) {
        my $raw_contact_response = $response->{GetContacts}{$contact_type};

        my $common_contact_response;
        for my $field ( keys %{ $raw_contact_response } ) {
            if( $field !~ m/$contact_type/ ) {
                next;
            }

            $common_contact_response->{ substr( $field, length( $contact_type ) ) } =
                $raw_contact_response->{ $field } // { };
        }

        $contacts->{ $contact_type } = WWW::eNom::Contact->construct_from_response( $common_contact_response );
    }

Getting a contact from a response is a bit more involved then other data marshallers.  This is because the fields are all prefixed with the contact type.  Rather than having just FirstName the response will contain a field like TechFirstName.  This must be processed off before feeding in the HashRef of the response into the construct_from_response method.  Returned is an instance of self.

=cut
