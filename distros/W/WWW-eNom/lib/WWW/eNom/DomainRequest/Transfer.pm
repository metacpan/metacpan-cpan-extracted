package WWW::eNom::DomainRequest::Transfer;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::eNom::Types qw( Bool Contact DomainName Str TransferVerificationMethod );

use Carp;

our $VERSION = 'v2.7.0'; # VERSION
# ABSTRACT: Domain Transfer Request

has 'name' => (
    is       => 'ro',
    isa      => DomainName,
    required => 1,
);

has 'verification_method' => (
    is      => 'ro',
    isa     => TransferVerificationMethod,
    default => 'Autoverification',
);

has 'is_private' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has 'is_locked' => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has 'is_auto_renew' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has 'epp_key' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'use_existing_contacts' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has 'registrant_contact' => (
    is        => 'ro',
    isa       => Contact,
    predicate => 'has_registrant_contact',
);

has 'admin_contact' => (
    is        => 'ro',
    isa       => Contact,
    predicate => 'has_admin_contact',
);

has 'technical_contact' => (
    is        => 'ro',
    isa       => Contact,
    predicate => 'has_technical_contact',
);

has 'billing_contact' => (
    is        => 'ro',
    isa       => Contact,
    predicate => 'has_billing_contact',
);

with 'WWW::eNom::Role::ParseDomain';

sub BUILD {
    my $self = shift;

    if( $self->use_existing_contacts ) {
        ( $self->verification_method ne 'Fax' && $self->has_registrant_contact )
            and croak 'When using existing contacts the registrant contact must not be specified';
        $self->has_admin_contact      and croak 'When using existing contacts the admin contact must not be specified';
        $self->has_technical_contact  and croak 'When using existing contacts the technical contact must not be specified';
        $self->has_billing_contact    and croak 'When using existing contacts the billing contact must not be specified';
    }
    else {
        ## no critic ( ValuesAndExpressions::ProhibitMixedBooleanOperators )
        !$self->has_registrant_contact and croak 'If not using existing contacts the registrant contact must be specified';
        !$self->has_admin_contact      and croak 'If not using existing contacts the admin contact must be specified';
        !$self->has_technical_contact  and croak 'If not using existing contacts the technical contact must be specified';
        !$self->has_billing_contact    and croak 'If not using existing contacts the billing contact must be specified';
        ## use critic
    }

    if( $self->verification_method eq 'Fax' ) {
        ## no critic ( ValuesAndExpressions::ProhibitMixedBooleanOperators )
        !$self->has_registrant_contact and croak 'If using Fax verification, a registrant contact must be specified';
        ## use critic
    }

    return $self;
}

sub construct_request {
    my $self = shift;

    return {
        DomainCount => 1,
        SLD1        => $self->sld,
        TLD1        => $self->tld,
        AuthInfo1   => $self->epp_key,
        OrderType   => $self->verification_method,
        IncludeIDP  => $self->is_private            ? 1 : 0,
        Lock        => $self->is_locked             ? 1 : 0,
        Renew       => $self->is_auto_renew         ? 1 : 0,
        UseContacts => $self->use_existing_contacts ? 1 : 0,
        $self->has_registrant_contact ? %{ $self->registrant_contact->construct_creation_request('Registrant') } : ( ),
        $self->has_admin_contact      ? %{ $self->admin_contact->construct_creation_request('Admin')           } : ( ),
        $self->has_technical_contact  ? %{ $self->technical_contact->construct_creation_request('Tech')        } : ( ),
        $self->has_billing_contact    ? %{ $self->billing_contact->construct_creation_request('AuxBilling')    } : ( ),
    };
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

WWW::eNom::DomainRequest::Transfer - Domain Transfer Request

=head1 SYNOPSIS

    use WWW::eNom;
    use WWW::eNom::Contact;
    use WWW::eNom::DomainRequest::Transfer;

    my $api     = WWW::eNom->new( ... );
    my $contact = WWW::eNom::Contact->new( ... );

    # Transfer a Domain to eNom
    my $transfer_request = WWW::eNom::DomainRequest::Transfer->new(
        name                  => 'drzigman.com',
        verification_method   => 'Autoverification', # Optional, defaults to Autoverification
        is_private            => 0,                  # Optional, defaults to false
        is_locked             => 1,                  # Optional, defaults to true
        is_auto_renew         => 0,                  # Optional, defaults to false
        epp_key               => '12345',
        use_existing_contacts => 0,                  # Optional, defaults to false (which requires that contacts be specified)
        registrant_contact    => $contact,           # See attribute definition for details about when required
        admin_contact         => $contact,           # See attribute definition for details about when required
        technical_contact     => $contact,           # See attribute definition for details about when required
        billing_contact       => $contact,           # See attribute definition for details about when required
    );

    # Example showing construct_request, contrived!  Use transfer_domain in real life!
    my $response = $api->submit({
        method => 'TP_CreateOrder',
        params => $transfer_request->construct_request
    });

=head1 WITH

=over 4

=item L<WWW::eNom::Role::ParseDomain>

=back

=head1 DESCRIPTION

WWW::eNom::DomainRequest::Transfer is a representation of all the data needed in order to complete a domain transfer.  It is used when requesting a domain transfer to L<eNom|https://www.enom.com>.

=head1 ATTRIBUTES

=head2 B<name>

The FQDN to transfer

=head2 verification_method

The method of verification to use for approval of the domain transfer.  The valid options are:

=over 4

=item Autoverification

This is the default, it uses an email sent to the registrant to request transfer approval.

=item Fax

A manual process that involves sending a fax to the registrant for transfer approval.

B<NOTE> If you use this verification_method you must provide at least a registrant_contact.

=back

=head2 is_locked

Boolean that defaults to true.  Indicates if the domain should be locked, preventing transfers.

=head2 is_private

Boolean that defaults to false.  If true, the L<WPPS Service|https://www.enom.com/api/Value%20Added%20Topics/ID%20Protect.htm> (what eNom calls Privacy Protection) will automatically be purchased and enabled.

=head2 is_auto_renew

Boolean that defaults to false.  If true, this domain will be automatically renewed by eNom before it expires.

=head2 B<epp_key>

The EPP Key (sometimes called Auth Code or another registrar specific name) that allows this domain to be transferred.  This must be provided.

B<NOTE> If the epp_key provided is incorrect, L<eNom|https://www.enom.com> will cancel the transfer order and you'll have to submit a new one.

=head2 use_existing_contacts

Boolean indicating if you wish to specify a new set of contacts or have eNom attempt to import the existing contacts as part of the transfer process.  Defaults to false.

B<NOTE> A false value means you must also provide all of the contacts ( registrant, admin, technical, and billing ).

=head2 registrant_contact

A L<WWW::eNom::Contact> for the Registrant Contact.

This is required if the L<verification_method> is Fax, or if L<use_existing_contacts> is false.

=head2 admin_contact

A L<WWW::eNom::Contact> for the Admin Contact.

This is required if L<use_existing_contacts> is false.

=head2 technical_contact

A L<WWW::eNom::Contact> for the Technical Contact.

This is required if L<use_existing_contacts> is false.

=head2 billing_contact

A L<WWW::eNom::Contact> for the Billing Contact.

This is required if L<use_existing_contacts> is false.

NOTE> L<eNom|https://www.eNom.com> actually calls this the AuxBilling> contact since the primary billing contact is the reseller's information.

=head1 METHODS

=head2 construct_request

    my $transfer_request = WWW::eNom::DomainRequest::Transfer->new( ... );

    my $response = $api->submit({
        method => 'TP_CreateOrder',
        params => $transfer_request->construct_request
    });

Converts $self into a HashRef suitable for the L<TP_CreateOrder|https://www.enom.com/api/API%20Topics/API_TP_CreateOrder.htm> (transfer) of a Domain.

=cut
