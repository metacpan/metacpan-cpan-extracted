package WWW::PayPal::Refund;

# ABSTRACT: PayPal Payments v2 refund entity

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


sub id       { $_[0]->data->{id} }
sub status   { $_[0]->data->{status} }
sub amount   { $_[0]->data->{amount}{value} }
sub currency { $_[0]->data->{amount}{currency_code} }
sub note     { $_[0]->data->{note_to_payer} }



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::PayPal::Refund - PayPal Payments v2 refund entity

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $refund = $pp->payments->refund($capture_id,
        amount => { currency_code => 'EUR', value => '5.00' },
    );

    print $refund->id,       "\n";
    print $refund->status,   "\n";
    print $refund->amount,   "\n";
    print $refund->currency, "\n";

=head1 DESCRIPTION

Wrapper around a PayPal refund JSON object, as returned by
L<WWW::PayPal::API::Payments/refund> and L<WWW::PayPal::API::Payments/get_refund>.

=head2 data

Raw decoded JSON for the refund.

=head2 id

Refund ID.

=head2 status

Refund status — C<CANCELLED>, C<PENDING>, C<FAILED>, C<COMPLETED>.

=head2 amount

String amount, e.g. C<"5.00">.

=head2 currency

Currency code, e.g. C<"EUR">.

=head2 note

The C<note_to_payer> that was included with the refund, if any.

=head1 SEE ALSO

=over 4

=item * L<WWW::PayPal::API::Payments>

=item * L<WWW::PayPal::Capture>

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
