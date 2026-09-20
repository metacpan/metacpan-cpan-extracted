package WWW::PayPal::Webhook;

# ABSTRACT: PayPal webhook (endpoint subscription) entity

use Moo;
use namespace::clean;

our $VERSION = '0.003';


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has data => ( is => 'rw', required => 1 );


sub id  { $_[0]->data->{id} }
sub url { $_[0]->data->{url} }


sub event_names {
    my ($self) = @_;
    return map { $_->{name} } @{ $self->data->{event_types} || [] };
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PayPal::Webhook - PayPal webhook (endpoint subscription) entity

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $webhook = $pp->webhooks->create(
        url         => 'https://example.com/paypal/webhook',
        event_types => [ 'PAYMENT.CAPTURE.COMPLETED', 'CHECKOUT.ORDER.APPROVED' ],
    );

    print $webhook->id;
    print $webhook->url;
    my @names = $webhook->event_names;   # ('PAYMENT.CAPTURE.COMPLETED', ...)

=head1 DESCRIPTION

Wrapper around a PayPal webhook JSON object — the endpoint subscription that
tells PayPal where to deliver events and which event types to send. This is the
merchant-side registration, not the individual event payloads that arrive at
your receiver; verify those with
L<< $pp->webhooks->verify|WWW::PayPal::API::Webhooks/verify >>.

=head2 data

Raw decoded JSON for the webhook.

=head2 id

Webhook ID (e.g. C<1JE4291016473214C>). Pass this to
L<< verify|WWW::PayPal::API::Webhooks/verify >> and store it per environment —
sandbox and live webhook IDs are not interchangeable.

=head2 url

The endpoint URL PayPal delivers events to.

=head2 event_names

    my @names = $webhook->event_names;

The subscribed event-type names, flattened out of PayPal's
C<< event_types => [ { name => ... }, ... ] >> shape.

=head1 SEE ALSO

=over 4

=item * L<WWW::PayPal::API::Webhooks>

=item * L<WWW::PayPal::WebhookEvents>

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
