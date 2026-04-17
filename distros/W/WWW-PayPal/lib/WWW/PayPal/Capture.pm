package WWW::PayPal::Capture;

# ABSTRACT: PayPal Payments v2 capture entity

use Moo;
use namespace::clean;

our $VERSION = '0.002';


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has data => ( is => 'rw', required => 1 );


sub id         { $_[0]->data->{id} }
sub status     { $_[0]->data->{status} }
sub amount     { $_[0]->data->{amount}{value} }
sub currency   { $_[0]->data->{amount}{currency_code} }
sub invoice_id { $_[0]->data->{invoice_id} }


sub fee_in_cent {
    my ($self) = @_;
    my $fee = $self->data->{seller_receivable_breakdown}{paypal_fee}{value} or return;
    return int($fee * 100 + 0.5);
}


sub refund {
    my ($self, %args) = @_;
    return $self->_client->payments->refund($self->id, %args);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PayPal::Capture - PayPal Payments v2 capture entity

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $capture = $pp->payments->get_capture($capture_id);

    print $capture->id,          "\n";
    print $capture->status,      "\n";
    print $capture->amount,      "\n";
    print $capture->currency,    "\n";
    print $capture->fee_in_cent, "\n";

    my $refund = $capture->refund(
        amount => { currency_code => 'EUR', value => '5.00' },
    );

=head1 DESCRIPTION

Wrapper around a PayPal capture JSON object. Captures are what you get back
from L<WWW::PayPal::API::Orders/capture> (attached to the order) and from
L<WWW::PayPal::API::Payments/get_capture>.

=head2 data

Raw decoded JSON for the capture.

=head2 id

Capture ID (use this with L<WWW::PayPal::API::Payments/refund>).

=head2 status

Capture status — C<COMPLETED>, C<PENDING>, C<DECLINED>, C<REFUNDED>,
C<PARTIALLY_REFUNDED>, C<FAILED>.

=head2 amount

String amount of the capture, e.g. C<"42.00">.

=head2 currency

Currency code, e.g. C<"EUR">.

=head2 invoice_id

Merchant invoice ID, if one was set when creating the order.

=head2 fee_in_cent

PayPal's fee for this capture, in cents (rounded from the decimal string
PayPal returns).

=head2 refund

    my $refund = $capture->refund(
        amount         => { currency_code => 'EUR', value => '5.00' },
        note_to_payer  => 'Partial refund',
    );

Issues a refund against this capture. Omit C<amount> for a full refund.
Returns a L<WWW::PayPal::Refund>.

=head1 SEE ALSO

=over 4

=item * L<WWW::PayPal::API::Payments>

=item * L<WWW::PayPal::Refund>

=item * L<WWW::PayPal::Order>

=back

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
