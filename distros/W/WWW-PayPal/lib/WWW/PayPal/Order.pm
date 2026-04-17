package WWW::PayPal::Order;

# ABSTRACT: PayPal Orders v2 order entity

use Moo;
use Carp qw(croak);
use namespace::clean;

our $VERSION = '0.002';


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has data => (
    is       => 'rw',
    required => 1,
);


sub id     { $_[0]->data->{id} }
sub status { $_[0]->data->{status} }
sub intent { $_[0]->data->{intent} }


sub _links {
    my ($self) = @_;
    return $self->data->{links} || [];
}

sub link_for {
    my ($self, $rel) = @_;
    for my $l (@{ $self->_links }) {
        return $l->{href} if $l->{rel} && $l->{rel} eq $rel;
    }
    return;
}


sub approve_url {
    my ($self) = @_;
    # Modern flows return 'payer-action'; legacy returned 'approve'.
    return $self->link_for('payer-action') // $self->link_for('approve');
}


sub _capture_node {
    my ($self) = @_;
    my $pu = $self->data->{purchase_units} || [];
    return unless @$pu;
    my $captures = $pu->[0]{payments}{captures} || [];
    return $captures->[0];
}

sub capture_id {
    my ($self) = @_;
    my $c = $self->_capture_node or return;
    return $c->{id};
}


sub fee_in_cent {
    my ($self) = @_;
    my $c = $self->_capture_node or return;
    my $fee = $c->{seller_receivable_breakdown}{paypal_fee}{value} or return;
    # PayPal returns decimal strings like "1.23"
    return int($fee * 100 + 0.5);
}


sub total {
    my ($self) = @_;
    my $pu = $self->data->{purchase_units} || [];
    return unless @$pu;
    return $pu->[0]{amount}{value};
}

sub currency {
    my ($self) = @_;
    my $pu = $self->data->{purchase_units} || [];
    return unless @$pu;
    return $pu->[0]{amount}{currency_code};
}


sub payer_email {
    my ($self) = @_;
    return $self->data->{payer}{email_address};
}

sub payer_name {
    my ($self) = @_;
    my $n = $self->data->{payer}{name} or return;
    return join(' ', grep { defined && length } $n->{given_name}, $n->{surname});
}

sub payer_id {
    my ($self) = @_;
    return $self->data->{payer}{payer_id};
}


sub refresh {
    my ($self) = @_;
    my $fresh = $self->_client->orders->get($self->id);
    $self->data($fresh->data);
    return $self;
}


sub capture {
    my ($self) = @_;
    my $captured = $self->_client->orders->capture($self->id);
    $self->data($captured->data);
    return $self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PayPal::Order - PayPal Orders v2 order entity

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $order = $pp->orders->create(...);

    print $order->id, "\n";
    print $order->status, "\n";           # CREATED / APPROVED / COMPLETED / ...
    print $order->approve_url, "\n";      # redirect the buyer here

    # After return from PayPal + capture:
    print $order->payer_email, "\n";
    print $order->payer_name,  "\n";
    print $order->capture_id,  "\n";
    print $order->fee_in_cent, "\n";

=head1 DESCRIPTION

Lightweight wrapper around the JSON returned by the PayPal Orders v2 API.
Exposes the fields relevant to the common "sell a product" flow and keeps
the raw data accessible via L</data>.

=head2 data

Raw decoded JSON from PayPal. Writable so L</refresh>/L</capture> can update
it in place.

=head2 id

PayPal order ID.

=head2 status

Order status — one of C<CREATED>, C<SAVED>, C<APPROVED>, C<VOIDED>,
C<COMPLETED>, C<PAYER_ACTION_REQUIRED>.

=head2 intent

C<CAPTURE> or C<AUTHORIZE>.

=head2 link_for

    my $url = $order->link_for('approve');

Looks up a HATEOAS link by C<rel>.

=head2 approve_url

The URL the buyer must visit to approve the payment. Returns C<undef> once
the order is captured.

=head2 capture_id

ID of the first capture attached to this order (after
L<WWW::PayPal::API::Orders/capture>). Pass this to
L<WWW::PayPal::API::Payments/refund>.

=head2 fee_in_cent

PayPal's fee for the first capture, in cents (rounded).

=head2 total

String amount from the first purchase unit, e.g. C<"42.00">.

=head2 currency

Currency code from the first purchase unit, e.g. C<"EUR">.

=head2 payer_email

Payer's email address (available once approved).

=head2 payer_name

Payer's full name (C<given_name> + C<surname>).

=head2 payer_id

PayPal-issued Payer ID.

=head2 refresh

    $order->refresh;

Re-fetches the order from PayPal and updates L</data> in place.

=head2 capture

    $order->capture;

Captures the order (buyer must have approved it first) and updates L</data>.

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
