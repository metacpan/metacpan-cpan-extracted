package WWW::LogicBoxes::DomainRequest::Transfer;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::LogicBoxes::Types qw( Str );

extends 'WWW::LogicBoxes::DomainRequest';

our $VERSION = '1.9.0'; # VERSION
# ABSTRACT: Domain Transfer Request

has epp_key => (
    is        => 'ro',
    isa       => Str,
    required  => 0,
    predicate => 'has_epp_key',
);

sub construct_request {
    my $self = shift;

    return {
        'domain-name'        => $self->name,
        ns                   => $self->ns,
        'customer-id'        => $self->customer_id,
        'reg-contact-id'     => $self->registrant_contact_id,
        'admin-contact-id'   => $self->admin_contact_id,
        'tech-contact-id'    => $self->technical_contact_id,
        'billing-contact-id' => $self->billing_contact_id,
        'invoice-option'     => $self->invoice_option,
        $self->has_epp_key ? ( 'auth-code' => $self->epp_key ) : ( ),
        $self->is_private ? (
            'protect-privacy'  => 'true',
            'purchase-privacy' => 'true',
        ) : ( ),
    };
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::DomainRequest::Transfer - Representation of Domain Transfer Request

=head1 SYNOPSIS

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Customer;
    use WWW::LogicBoxes::Contact;
    use WWW::LogicBoxes::DomainTransfer;
    use WWW::LogicBoxes::DomainRequest::Transfer;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    my $customer    = WWW:::LogicBoxes::Customer->new( ... ); # Valid LogicBoxes Customer

    my $registrant_contact = WWW::LogicBoxes::Contact->new( ... ); # Valid LogicBoxes Contact
    my $admin_contact      = WWW::LogicBoxes::Contact->new( ... ); # Valid LogicBoxes Contact
    my $technical_contact  = WWW::LogicBoxes::Contact->new( ... ); # Valid LogicBoxes Contact
    my $billing_contact    = WWW::LogicBoxes::Contact->new( ... ); # Valid LogicBoxes Contact

    my $transfer_request = WWW::LogicBoxes::DomainRequest::Transfer->new(
        name        => 'test-domain.com',
        customer_id => $customer->id,
        ns          => [ 'ns1.logicboxes.com', 'ns2.logicboxes.com' ],
        registrant_contact_id => $registrant_contact->id,
        admin_contact_id      => $admin_contact->id,
        technical_contact_id  => $technical_contact->id,
        billing_contact_id    => $billing_contact->id,
        invoice_option        => 'NoInvoice',
    );

    my $transfer_domain = $logic_boxes->transfer_domain( request => $transfer_request );

=head1 EXTENDS

L<WWW::LogicBoxes::DomainRequest>

=head1 DESCRIPTION

WWW::LogicBoxes::DomainRequest::Transfer is a representation of all the data needed in order to complete a domain transfer.  It is used when requesting a new domain transfer from L<LogicBoxes|http://www.logicboxes.com>.

=head1 ATTRIBUTES

All of the existing L<WWW::LogicBoxes::DomainRequest> attributes remain unchanged with one addition attribute.

=head2 B<epp_key>

The epp_key (what L<LogicBoxes|http://www.logicboxes.com> calls the auth code) to register this L<domain transfer|WWW::LogicBoxes::DomainTransfer> for.  This need not be specified at this point, and a predicate of has_epp_key is provied.

=head1 METHODS

This method is used internally, it's fairly unlikely that consumers will ever call it directly.

=head2 construct_request

    my $logic_boxes      = WWW::LogicBoxes->new( ... );
    my $transfer_request = WWW::LogicBoxes::DomainRequest::Transfer->new( ... );

    my $response = $logic_boxes->submit({
        method => 'domains__transfer',
        params => $transfer_request->consturct_request(),
    });

Converts $self into a HashRef suitable for requesting a domain transfer with L<LogicBoxes|http://www.logicboxes.com>.

=cut
