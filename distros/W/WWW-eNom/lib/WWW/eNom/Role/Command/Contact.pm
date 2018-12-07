package WWW::eNom::Role::Command::Contact;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( Bool Contact DomainName HashRef Str );

use WWW::eNom::Contact;

use Data::Util qw( is_string );
use Try::Tiny;
use Carp;

use Readonly;
Readonly my $ENOM_CONTACT_TYPE_MAPPING => {
    Registrant => 'registrant_contact',
    Admin      => 'admin_contact',
    Tech       => 'technical_contact',
    AuxBilling => 'billing_contact',
};

Readonly my $CONTACT_TYPE_ENOM_MAPPING => { reverse %{ $ENOM_CONTACT_TYPE_MAPPING } };

requires 'submit';

our $VERSION = 'v2.7.0'; # VERSION
# ABSTRACT: Contact Related Operations

sub get_contacts_by_domain_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetContacts',
            params => {
                Domain => $domain_name
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }

            croak 'Unknown error';
        }

        my $billing_party_id = $response->{GetContacts}{Billing}{BillingPartyID};
        my $billing_party_contact = WWW::eNom::Contact->construct_from_response(
            $self->_extract_common_contact_format(
                contact_type         => 'Billing',
                raw_contact_response => $response->{GetContacts}{Billing},
            )
        );

        my $contacts;
        for my $contact_type ( keys %{ $ENOM_CONTACT_TYPE_MAPPING } ) {
            my $common_contact_response = $self->_extract_common_contact_format(
                contact_type         => $contact_type,
                raw_contact_response => $response->{GetContacts}{$contact_type},
            );

            # If no other contact has been provided then MY information (the reseller)
            # is used.  Treat this as no info.
            if( defined $common_contact_response->{PartyID} && $common_contact_response->{PartyID} eq $billing_party_id ) {
                next;
            }

            $contacts->{ $ENOM_CONTACT_TYPE_MAPPING->{ $contact_type} } =
                WWW::eNom::Contact->construct_from_response( $common_contact_response );
        }

        # Check for anyone who used the reseller's contact info for a contact and replace
        # it with the registrant contact data.
        for my $contact_type ( values %{ $ENOM_CONTACT_TYPE_MAPPING } ) {
            if( !exists $contacts->{ $contact_type } ) {
                # Do I have any other contacts that I can use?
                for my $replacement_contact_type ( grep { $_ ne $contact_type } ( values %{ $ENOM_CONTACT_TYPE_MAPPING } ) ) {
                    if( exists $contacts->{$replacement_contact_type} ) {
                        $contacts->{ $contact_type } = $contacts->{ $replacement_contact_type };
                        last;
                    }
                }

                # If I didn't find one, begrugingly use the billing one
                $contacts->{ $contact_type } //= $billing_party_contact;
            }
        }

        $contacts->{is_pending_irtp} = $response->{GetContacts}{PendingVerification} eq 'True';

        return $contacts;
    }
    catch {
        croak $_;
    }
}

sub _extract_common_contact_format {
    my $self     = shift;
    my ( %args ) = validated_hash(
        \@_,
        contact_type         => { isa => Str },
        raw_contact_response => { isa => HashRef },
    );

    my $common_contact_response;
    for my $field ( keys %{ $args{raw_contact_response} } ) {
        if( $field !~ m/${\( $args{contact_type} )}/ ) {
            next;
        }

        # If the value is not a string then consider it undefined
        $common_contact_response->{ substr( $field, length( $args{contact_type} ) ) } =
            is_string( $args{raw_contact_response}->{ $field } ) ? $args{raw_contact_response}->{ $field } : undef;
    }

    # Try harder to create a valid contact for the Billing contact (the Reseller)
    # We do this since if we have no other (valid) contacts we can't build the domain,
    # better to have something rather than nothing
    if( $args{contact_type} eq 'Billing' ) {
        if( $common_contact_response->{OrganizationName} ) {
            $common_contact_response->{JobTitle} //= 'Reseller';
            $common_contact_response->{Fax}      //= $common_contact_response->{Phone};
        }
    }

    return $common_contact_response;
}

sub update_contacts_for_domain_name {
    my $self     = shift;
    my ( %args ) = validated_hash(
        \@_,
        domain_name         => { isa => DomainName },
        registrant_contact  => { isa => Contact, optional => 1 },
        admin_contact       => { isa => Contact, optional => 1 },
        technical_contact   => { isa => Contact, optional => 1 },
        billing_contact     => { isa => Contact, optional => 1 },
        is_transfer_locked  => { isa => Bool,    default  => 1 },
    );

    try {
        # The not for is_transfer_locked is because eNom treats this as opt out
        # while I'm treating the input as just if it should lock or not

        # Replace all contacts at once
        if(    ( scalar grep { exists $args{$_} && defined $args{$_} } values %{ $ENOM_CONTACT_TYPE_MAPPING } )
            == ( scalar values %{ $ENOM_CONTACT_TYPE_MAPPING } ) ) {
            $self->_update_contacts({
                payload => {
                    Domain     => $args{domain_name},
                    IRTPOptOut => ( !$args{is_transfer_locked} ? 'true' : 'false' ),
                    %{ $args{registrant_contact}->construct_creation_request('Registrant') },
                    %{ $args{admin_contact}->construct_creation_request('Admin')           },
                    %{ $args{technical_contact}->construct_creation_request('Tech')        },
                    %{ $args{billing_contact}->construct_creation_request('AuxBilling')    },
                }
            });
        }
        # Replace contacts one at a time
        else {
            for my $contact_type ( values %{ $ENOM_CONTACT_TYPE_MAPPING } ) {
                if( !exists $args{ $contact_type } || !defined $args{ $contact_type } ) {
                    next;
                }

                $self->_update_contacts({
                    payload => {
                        Domain      => $args{domain_name},
                        IRTPOptOut  => ( !$args{is_transfer_locked} ? 'True' : 'False' ),
                        ContactType => uc $CONTACT_TYPE_ENOM_MAPPING->{ $contact_type },
                        %{ $args{ $contact_type }->construct_creation_request( $CONTACT_TYPE_ENOM_MAPPING->{ $contact_type } ) },
                    }
                });
            }
        }
    }
    catch {
        croak $_;
    };

    return $self->get_contacts_by_domain_name( $args{domain_name} );
}

sub _update_contacts {
    my $self     = shift;
    my ( %args ) = validated_hash(
        \@_,
        payload => { isa => HashRef },
    );

    my $response = $self->submit({
        method => 'Contacts',
        params =>  $args{payload},
    });

    if( $response->{ErrCount} > 0 ) {
        if( grep { $_ eq 'Domain name ID not found' } @{ $response->{errors} } ) {
            croak 'Domain not found in your account';
        }

        croak 'Unknown error';
    }

    return $response;
}

1;

__END__

=head1 NAME

WWW::eNom::Role::Command::Contact - Contact Related Operations

=head1 SYNOPSIS

    use WWW::eNom;
    use WWW::eNom::Contact;

    my $api = WWW::eNom->new( ... );

    # Get Contacts for a Domain
    my $contacts = $api->get_contacts_by_domain_name( 'drzigman.com' );

    for my $contact_type (qw( registrant_contact admin_contact technical_contact billing_contact )) {
        print "Email Address of $contact_type is: " . $contacts->{$contact_type}->email . "\n";
    }

    # Update Contacts
    my $new_registrant_contact = WWW::eNom::Contact->new( ... );
    my $new_admin_contact      = WWW::eNom::Contact->new( ... );
    my $new_technical_contact  = WWW::eNom::Contact->new( ... );
    my $new_billing_contact    = WWW::eNom::Contact->new( ... );

    my $updated_contacts = $api->update_contacts_for_domain_name(
        domain_name        => 'drzigman.com',
        is_transfer_locked => 1,                         # Optional, Defaults to truthy
        registrant_contact => $new_registrant_contact,   # Optional
        admin_contact      => $new_admin_contact,        # Optional
        technical_contact  => $new_technical_contact,    # Optional
        billing_contact    => $new_billing_contact,      # Optional
    );

=head1 REQUIRES

=over 4

=item submit

=back

=head1 DESCRIPTION

Implements contact related operations with L<eNom|https://www.enom.com>'s API.

=head1 METHODS

=head2 get_contacts_by_domain_name

    my $contacts = $api->get_contacts_by_domain_name( 'drzigman.com' );

    for my $contact_type (qw( registrant_contact admin_contact technical_contact billing_contact )) {
        print "Email Address of $contact_type is: " . $contacts->{$contact_type}->email . "\n";
    }

Abstraction of the L<GetContacts|https://www.enom.com/api/API%20topics/api_GetContacts.htm> eNom API Call.  Given a FQDN, returns a HashRef of contacts for that domain.  The keys for the returned HashRef are:

=over 4

=item registrant_contact

=item admin_contact

=item technical_contact

=item billing_contact

=back

Each of these keys point to a value which is an instance of L<WWW::eNom::Contact>.

=head2 update_contacts_for_domain_name

    my $updated_contacts = $api->update_contacts_for_domain_name(
        domain_name        => 'drzigman.com',
        is_transfer_locked => 1,                         # Optional, Defaults to truthy
        registrant_contact => $new_registrant_contact,   # Optional
        admin_contact      => $new_admin_contact,        # Optional
        technical_contact  => $new_technical_contact,    # Optional
        billing_contact    => $new_billing_contact,      # Optional
    );

Abstraction of the L<Contacts|https://www.enom.com/api/API%20topics/api_Contacts.htm> eNom API Call.  Given a FQDN and new contacts to use, updates the specified contacts to match those provided.  Returned is a HashRef of Contacts (see L<get_contacts_by_domain_name> for response format).

AN interesting thing about this method is that you only need specify the contacts you wish to update.  If you wish to update registrant, admin, technical, and billing great!  Go for it and include all of them in one call.  If you wish to update only a subset of the contacts (1, 2 or 3 of them) you should pass only the contacts to be updated.

Moreover, when making changes to the registrant_contact, per the 2016-12-01 L<ICANN Inter Registrar Transfer Policy|https://www.icann.org/resources/pages/transfer-policy-2016-06-01-en>, a 60 day transfer lock is imposed on the domain unless the requester explicitly states that they B<DO NOT> wish to have this transfer lock imposed.  By default the domain will be locked, however, if you pass a falsey value for is_transfer_locked that lock will not be applied.

=cut
