package WWW::eNom::DomainTransfer;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Params::Validate;
use namespace::autoclean;

use WWW::eNom::Types qw( Bool Contact DomainName HashRef PositiveInt Str );

our $VERSION = 'v2.6.0'; # VERSION
# ABSTRACT: Representation of In Progress Domain Transfer

has 'order_id' => (
    is       => 'ro',
    isa      => PositiveInt,
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => DomainName,
    required => 1,
);

has 'status' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'status_id' => (
    is       => 'ro',
    isa      => PositiveInt,
    required => 1,
);

has 'is_locked' => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

has 'is_auto_renew' => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

has 'use_existing_contacts' => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
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

sub construct_from_response {
    my $self     = shift;
    my ( %args ) = validated_hash(
        \@_,
        transfer_detail => { isa => HashRef },
    );

    return $self->new(
        order_id              => $args{transfer_detail}{transferorderdetailid},
        name                  => sprintf('%s.%s', $args{transfer_detail}{sld}, $args{transfer_detail}{tld} ),
        status                => $args{transfer_detail}{statusdesc},
        status_id             => $args{transfer_detail}{statusid},
        is_locked             => ( $args{transfer_detail}{lock}        eq 'True' ),
        is_auto_renew         => ( $args{transfer_detail}{renew}       eq 'True' ),
        use_existing_contacts => ( $args{transfer_detail}{usecontacts} == 1      ),
        $args{transfer_detail}{contacts}{Registrant} ne 'None'
            ? ( registrant_contact => WWW::eNom::Contact->construct_from_response( $args{transfer_detail}{contacts}{Registrant} ) )
            : ( ),
        $args{transfer_detail}{contacts}{Admin} ne 'None'
            ? ( admin_contact => WWW::eNom::Contact->construct_from_response( $args{transfer_detail}{contacts}{Admin} ) )
            : ( ),
        $args{transfer_detail}{contacts}{Tech} ne 'None'
            ? ( technical_contact => WWW::eNom::Contact->construct_from_response( $args{transfer_detail}{contacts}{Tech} ) )
            : ( ),
        $args{transfer_detail}{contacts}{AuxBilling} ne 'None'
            ? ( billing_contact => WWW::eNom::Contact->construct_from_response( $args{transfer_detail}{contacts}{AuxBilling} ) )
            : ( ),
    );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

WWW::eNom::DomainTransfer - Representation of In Progress Domain Transfer

=head1 SYNOPSIS

    use WWW::eNom;
    use WWW::eNom::Contact;
    use WWW::eNom::DomainTransfer;

    my $api     = WWW::eNom->new( ... );
    my $contact = WWW::eNom::Contact->new( ... );

    # You shouldn't be calling new on this, you probably want to call $api->get_transfer_by_order_id instead
    my $domain_transfer = WWW::eNom::DomainTransfer->new(
        order_id              => 12345,
        name                  => 'drzigman.com',
        status                => 'Awaiting auto verification of transfer request',
        status_id             => 9
        is_locked             => 1,
        is_auto_renew         => 1,
        use_existing_contacts => 0,

        # These contacts may or may not be populated depending on the transfer options
        # and the stage of the transfer.
        registrant_contact    => $contact,
        admin_contact         => $contact,
        technical_contact     => $contact,
        billing_contact       => $contact,
    );

    # Construct from eNom TP_GetOrderDetail Response
    my $response = $self->submit({
        method => 'TP_GetOrderDetail',
        params => {
            TransferOrderDetailID => 12345
        }
    });

    my $transfer = WWW::eNom::DomainTransfer->construct_from_response(
        transfer_detail => $response->{transferorderdetail}
    );

=head1 WITH

=over 4

=item L<WWW::eNom::Role::ParseDomain>

=back

=head1 DESCRIPTION

Represents L<eNom|https://www.enom.com> domain transfer that is in progress.

=head1 ATTRIBUTES

=head2 B<order_id>

The order id for this specific domain transfer attempt with L<eNom|https://www.enom.com>.

eNom is a bit odd with how it handles order_id.  The purchase of a transfer will have a parent_order_id (for the entire order) as well as an order id for this specific domain transfer attempt (what this module calls the order_id).  If a domain transfer attempt fails for any reason (such as a bad EPP Key) then when you resubmit the domain transfer a new order_id will be created to describe the new domain transfer attempt.

=head2 B<name>

The FQDN to transfer

=head2 B<status>

A Str in English that describes the current status of this domain transfer.  Please see L<https://www.enom.com/api/API%20Topics/api_TP_GetDetailsByDomain.htm#notes> for a full list of possible statuses.

=head2 B<status_id>

PositiveInt indicating the status_id assoicated with the status.  Please see L<https://www.enom.com/api/API%20Topics/api_TP_GetDetailsByDomain.htm#notes> for a full list of possible statuses.

=head2 B<is_locked>

Indicates if the domain will be locked, preventing transfers.

=head2 B<is_auto_renew>

Boolean that indicates if the domain will auto renew.  If true, this domain will be automatically renewed by eNom before it expires.

=head2 B<use_existing_contacts>

Boolean indicating if eNom will attempt to import the existing whois contacts.

=head2 registrant_contact

A L<WWW::eNom::Contact> for the Registrant Contact, predicate of has_registrant_contact.

This will not be populated if L<use_existing_contacts> is true unless the L<WWW::eNom::DomainRequest::Transfer/verification_method> used when the transfer was originally requested was Fax.

B<NOTE> based on the stage of the transfer, L<eNom|https://www.enom.com> may or may not have contact information for this domain transfer.  Just because nothing was returned does not mean there is not any data, it just might not be available.

=head2 admin_contact

A L<WWW::eNom::Contact> for the Admin Contact, predicate of has_admin_contact.

B<NOTE> based on the stage of the transfer, L<eNom|https://www.enom.com> may or may not have contact information for this domain transfer.  Just because nothing was returned does not mean there is not any data, it just might not be available.

=head2 technical_contact

A L<WWW::eNom::Contact> for the Technical Contact, predicate of has_technical_contact.

B<NOTE> based on the stage of the transfer, L<eNom|https://www.enom.com> may or may not have contact information for this domain transfer.  Just because nothing was returned does not mean there is not any data, it just might not be available.

=head2 billing_contact

A L<WWW::eNom::Contact> for the Billing Contact, predicate of has_billing_contact.

NOTE> L<eNom|https://www.eNom.com> actually calls this the AuxBilling> contact since the primary billing contact is the reseller's information.

<NOTE> based on the stage of the transfer, L<eNom|https://www.enom.com> may or may not have contact information for this domain transfer.  Just because nothing was returned does not mean there is not any data, it just might not be available.

=head1 METHODS

=head2 construct_from_response

    my $response = $self->submit({
        method => 'TP_GetOrderDetail',
        params => {
            TransferOrderDetailID => 12345
        }
    });

    my $transfer = WWW::eNom::DomainTransfer->construct_from_response(
        transfer_detail => $response->{transferorderdetail}
    );

Creates an instance of $self from eNom's response to L<TP_GetOrderDetail|https://www.enom.com/api/API%20topics/api_TP_GetOrderDetail.htm>.
