package WWW::LogicBoxes::DomainRequest;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::LogicBoxes::Types qw( Bool DomainName DomainNames Int InvoiceOption );

use Carp;
use Mozilla::PublicSuffix qw( public_suffix );

our $VERSION = '1.11.0'; # VERSION
# ABSTRACT: Abstract Base Class for Domain Registration/Transfer Requests

has name => (
    is       => 'ro',
    isa      => DomainName,
    required => 1,
);

has customer_id => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has ns => (
    is       => 'ro',
    isa      => DomainNames,
    required => 1,
);

has registrant_contact_id => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has admin_contact_id => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has technical_contact_id => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has billing_contact_id => (
    is        => 'ro',
    isa       => Int,
    required  => 0,
    predicate => 'has_billing_contact_id',
);

has is_private => (
    is       => 'ro',
    isa      => Bool,
    default  => 0,
);

has invoice_option => (
    is       => 'ro',
    isa      => InvoiceOption,
    default  => 'NoInvoice',
);

sub BUILD {
    my $self = shift;

    my $tld = public_suffix( $self->name );

    if( $tld eq 'ca' ) {
        if( $self->has_billing_contact_id ) {
            croak 'CA domains do not have a billing contact';
        }
    }
    elsif( !$self->has_billing_contact_id ) {
        croak 'A billing_contact_id is required';
    }

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::DomainRequest - Abstract Base Case for Domain Registration and Transfer Requests

=head1 DESCRIPTION

WWW::LogicBoxes::DomainRequest is an abstract base class that is extended for usage in L<WWW::LogicBoxes::DomainRequest::Registration> and L<WWW::LogicBoxes::DomainRequest::Transfer>.  It should not be instantiated directly.

=head1 ATTRIBUTES

=head2 B<name>

The full domain name.

=head2 B<customer_id>

L<LogicBoxes Customer|WWW::LogicBoxes::Customer> id that is purchasing this domain.

=head2 B<ns>

Array Ref of domain names that should be used as the authoritive nameservers.

=head2 B<registrant_contact_id>

A L<Contact|WWW::LogicBoxes::Contact> id for the Registrant.

=head2 B<admin_contact_id>

A L<Contact|WWW::LogicBoxes::Contact> id for the Admin.

=head2 B<technical_contact_id>

A L<Contact|WWW::LogicBoxes::Contact> id for the Technical.

=head2 B<billing_contact_id>

A L<Contact|WWW::LogicBoxes::Contact> id for the Billing.  Offers a predicate of has_billing_contact_id.

Almost all TLDs require a billing contact, however for .ca domains it B<must not> be provided.

=head2 is_private

Boolean indicating if this domain uses WHOIS Privacy.  Defaults to false.

B<NOTE> Not all tlds support domain privacy.  For example, .us and .ca do not permit domain privacy.

=head2 invoice_option

Indicates to L<LogicBoxes|http://www.logicboxes.com> how invoicing of the L<customer|WWW::LogicBoxes::Customer> for this domain should occur.  It must be one of the following values:

=over 4

=item NoInvoice

Do not generate an invoice, just process the order.

=item PayInvoice

Generate an invoice and check the L<customer's|WWW::LogicBoxes::Customer> account balance.  If there are sufficent funds pay the invoice and process the order.  Otherwise, hold the order in a pending status.

=item KeepInvoice

Generate an invoice for the L<customer|WWW::LogicBoxes::Customer> to pay at some later point but process the order right now.

=back

The default value is 'NoInvoice'.

=cut
