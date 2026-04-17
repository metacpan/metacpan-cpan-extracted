package WWW::PayPal::API::Payments;

# ABSTRACT: PayPal Payments v2 API (captures, refunds, authorizations)

use Moo;
use Carp qw(croak);
use WWW::PayPal::Capture;
use WWW::PayPal::Refund;
use namespace::clean;

our $VERSION = '0.002';


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

has openapi_operations => (
    is      => 'lazy',
    builder => sub {
        # Pre-computed from paypal-rest-api-specifications
        # (openapi/payments_payment_v2.json).
        return {
            'captures.get'         => { method => 'GET',  path => '/v2/payments/captures/{capture_id}' },
            'captures.refund'      => { method => 'POST', path => '/v2/payments/captures/{capture_id}/refund' },
            'refunds.get'          => { method => 'GET',  path => '/v2/payments/refunds/{refund_id}' },
            'authorizations.get'   => { method => 'GET',  path => '/v2/payments/authorizations/{authorization_id}' },
            'authorizations.capture' => { method => 'POST', path => '/v2/payments/authorizations/{authorization_id}/capture' },
            'authorizations.void'  => { method => 'POST', path => '/v2/payments/authorizations/{authorization_id}/void' },
        };
    },
);

with 'WWW::PayPal::Role::OpenAPI';

sub get_capture {
    my ($self, $id) = @_;
    croak 'capture_id required' unless $id;
    my $data = $self->call_operation('captures.get', path => { capture_id => $id });
    return WWW::PayPal::Capture->new(client => $self->client, data => $data);
}


sub refund {
    my ($self, $capture_id, %args) = @_;
    croak 'capture_id required' unless $capture_id;

    my $body = {};
    $body->{amount}         = $args{amount}         if $args{amount};
    $body->{invoice_id}     = $args{invoice_id}     if $args{invoice_id};
    $body->{note_to_payer}  = $args{note_to_payer}  if $args{note_to_payer};

    my $data = $self->call_operation('captures.refund',
        path => { capture_id => $capture_id },
        body => $body,
    );
    return WWW::PayPal::Refund->new(client => $self->client, data => $data);
}


sub get_refund {
    my ($self, $id) = @_;
    croak 'refund_id required' unless $id;
    my $data = $self->call_operation('refunds.get', path => { refund_id => $id });
    return WWW::PayPal::Refund->new(client => $self->client, data => $data);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PayPal::API::Payments - PayPal Payments v2 API (captures, refunds, authorizations)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $capture = $pp->payments->get_capture($capture_id);

    my $refund = $pp->payments->refund($capture_id,
        amount => { currency_code => 'EUR', value => '10.00' },
        note_to_payer => 'Partial refund',
    );

=head1 DESCRIPTION

Controller for PayPal's Payments v2 API — used here to fetch captures and
issue refunds against them.

=head2 get_capture

    my $capture = $pp->payments->get_capture($capture_id);

Fetches a capture by ID.

=head2 refund

    my $refund = $pp->payments->refund($capture_id,
        amount         => { currency_code => 'EUR', value => '5.00' },  # optional
        invoice_id     => 'INV-123',                                     # optional
        note_to_payer  => 'Sorry!',                                      # optional
    );

Refunds a capture. Omit C<amount> to refund in full.

=head2 get_refund

    my $refund = $pp->payments->get_refund($refund_id);

Fetches a refund by ID.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-paypal/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
