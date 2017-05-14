package WebService::PayPal::PaymentsAdvanced::Role::HasCreditCard;

use Moo::Role;

use namespace::autoclean;

our $VERSION = '0.000022';

use Types::Common::Numeric qw( PositiveInt );
use Types::Common::String qw( NonEmptyStr );

has card_type => (
    is       => 'lazy',
    isa      => NonEmptyStr,
    init_arg => undef,
);

has card_expiration => (
    is       => 'lazy',
    isa      => NonEmptyStr,
    init_arg => undef,
);

has card_last_four_digits => (
    is       => 'lazy',
    isa      => PositiveInt,
    init_arg => undef,
    default  => sub { shift->params->{ACCT} },
);

has reference_transaction_id => (
    is       => 'lazy',
    isa      => NonEmptyStr,
    init_arg => undef,
    default  => sub { shift->pnref },
);

sub _build_card_type {
    my $self = shift;

    my %card_types = (
        0 => 'VISA',
        1 => 'MasterCard',
        2 => 'Discover',
        3 => 'American Express',
        4 => q{Diner's Club},
        5 => 'JCB',
    );
    return $card_types{ $self->params->{CARDTYPE} };
}

sub _build_card_expiration {
    my $self = shift;

    # Will be in MMYY
    my $date = $self->params->{EXPDATE};

    # This breaks in about 75 years.
    return sprintf( '20%s-%s', substr( $date, 2, 2 ), substr( $date, 0, 2 ) );
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Role::HasCreditCard - Role which provides methods specifically for credit card transactions

=head1 VERSION

version 0.000022

=head2 card_type

A human readable credit card type.  One of:

    VISA
    MasterCard
    Discover
    American Express
    Diner's Club
    JCB

=head2 card_expiration

The month and year of the credit card expiration.

=head2 card_last_four_digits

The last four digits of the credit card.

=head2 reference_transaction_id

The id you will use in order to use this as a reference transaction (C<pnref>).

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/webservice-paypal-paymentsadvanced/issues>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
# ABSTRACT: Role which provides methods specifically for credit card transactions

