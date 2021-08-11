package WWW::LogicBoxes::DomainRequest::Registration;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::LogicBoxes::Types qw( Int );

extends 'WWW::LogicBoxes::DomainRequest';

our $VERSION = '1.11.0'; # VERSION
# ABSTRACT: Domain Registration Request

has years => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

sub construct_request {
    my $self = shift;

    return {
        'domain-name'        => $self->name,
        years                => $self->years,
        ns                   => $self->ns,
        'customer-id'        => $self->customer_id,
        'reg-contact-id'     => $self->registrant_contact_id,
        'admin-contact-id'   => $self->admin_contact_id,
        'tech-contact-id'    => $self->technical_contact_id,
        'billing-contact-id' => $self->has_billing_contact_id ? $self->billing_contact_id : -1,
        'invoice-option'     => $self->invoice_option,
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

WWW::LogicBoxes::DomainRequest::Registration - Representation of Domain Registration Request

=head1 SYNOPSIS

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Customer;
    use WWW::LogicBoxes::Contact;
    use WWW::LogicBoxes::Domain;
    use WWW::LogicBoxes::DomainRequest::Registration;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    my $customer    = WWW:::LogicBoxes::Customer->new( ... ); # Valid LogicBoxes Customer

    my $registrant_contact = WWW::LogicBoxes::Contact->new( ... ); # Valid LogicBoxes Contact
    my $admin_contact      = WWW::LogicBoxes::Contact->new( ... ); # Valid LogicBoxes Contact
    my $technical_contact  = WWW::LogicBoxes::Contact->new( ... ); # Valid LogicBoxes Contact
    my $billing_contact    = WWW::LogicBoxes::Contact->new( ... ); # Valid LogicBoxes Contact

    my $registration_request = WWW::LogicBoxes::DomainRequest::Registration->new(
        name        => 'test-domain.com',
        years       => 1,
        customer_id => $customer->id,
        ns          => [ 'ns1.logicboxes.com', 'ns2.logicboxes.com' ],
        registrant_contact_id => $registrant_contact->id,
        admin_contact_id      => $admin_contact->id,
        technical_contact_id  => $technical_contact->id,
        billing_contact_id    => $billing_contact->id,
        invoice_option        => 'NoInvoice',
    );

    my $registered_domain = $logic_boxes->register_domain( request => $registration_request );

=head1 EXTENDS

L<WWW::LogicBoxes::DomainRequest>

=head1 DESCRIPTION

WWW::LogicBoxes::DomainRequest::Registration is a representation of all the data needed in order to complete a domain registration.  It is used when requesting a new registration from L<LogicBoxes|http://www.logicboxes.com>.

=head1 ATTRIBUTES

All of the existing L<WWW::LogicBoxes::DomainRequest> attributes remain unchanged with one addition attribute.

=head2 B<years>

The number of years to register this L<domain|WWW::LogicBoxes::Domain> for.

=head1 METHODS

This method is used internally, it's fairly unlikely that consumers will ever call it directly.

=head2 construct_request

    my $logic_boxes          = WWW::LogicBoxes->new( ... );
    my $registration_request = WWW::LogicBoxes::DomainRequest::Registration->new( ... );

    my $response = $logic_boxes->submit({
        method => 'domains__register',
        params => $registration_request->consturct_request(),
    });

Converts $self into a HashRef suitable for requesting a domain registration with L<LogicBoxes|http://www.logicboxes.com>.

=cut
