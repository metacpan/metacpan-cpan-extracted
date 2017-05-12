package WebService::MES;

our $VERSION = '0.01';

use Moo;
use LWP::UserAgent;
use URI;

has 'url' => (
    is      => 'ro',
    default => 'https://cert.merchante-solutions.com/mess-api/tridentApi',
);

has 'profile_id' => ( is => 'rw', );

has 'profile_key' => ( is => 'rw' );

has 'transaction_type' => (
    is      => 'rw',
    default => 'D',
);

has 'card_number' => ( is => 'rw', );

has 'card_exp_date' => ( is => 'rw' );

has 'transaction_amount' => ( is => 'rw' );

has 'cardholder_street_address' => ( is => 'rw' );

has 'cardholder_zip' => ( is => 'rw' );

has 'invoice_number' => ( is => 'rw' );

has 'tax_amount' => ( is => 'rw' );

has 'ua' => (
    is      => 'ro',
    default => sub {
        LWP::UserAgent->new(
            agent      => __PACKAGE__ . '_' . $VERSION,
            keep_alive => 1,
        );
    }
);

sub make_request {
    my $self = shift;

    my $url = URI->new( $self->url );
    $url->query_form(
        profile_id                => $self->profile_id,
        profile_key               => $self->profile_key,
        transaction_type          => $self->transaction_type,
        card_number               => $self->card_number,
        card_exp_date             => $self->card_exp_date,
        transaction_amount        => $self->transaction_amount,
        cardholder_street_address => $self->cardholder_street_address,
        cardholder_zip            => $self->cardholder_zip,
        invoice_number            => $self->invoice_number,
        tax_amount                => $self->tax_amount,
    );

    my $res = $self->ua->get($url);

    return $res;
}

1;

=head1 NAME

WebService::MES - Perl client for the Merchant e-Solutions Payment Gateway

=head1 SYNOPSIS

  use WebService::MES;

=head1 DESCRIPTION



=head1 SEE ALSO

=head1 AUTHOR

Fred Moyer, E<lt>fred@redhotpenguin.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Fred Moyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
