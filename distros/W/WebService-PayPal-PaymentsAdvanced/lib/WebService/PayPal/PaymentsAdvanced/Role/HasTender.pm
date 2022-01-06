package WebService::PayPal::PaymentsAdvanced::Role::HasTender;

use Moo::Role;

use namespace::autoclean;

our $VERSION = '0.000028';

use Types::Standard qw( Bool StrictNum );

has amount => (
    is       => 'lazy',
    isa      => StrictNum,
    init_arg => undef,
    default  => sub { shift->params->{AMT} },
);

has is_credit_card_transaction => (
    is       => 'lazy',
    isa      => Bool,
    init_arg => undef,
);

has is_paypal_transaction => (
    is       => 'lazy',
    isa      => Bool,
    lazy     => 1,
    init_arg => undef,
);

sub _build_is_credit_card_transaction {
    my $self = shift;
    return ( exists $self->params->{TENDER}
            && $self->params->{TENDER} eq 'CC' )
        || exists $self->params->{CARDTYPE};
}

sub _build_is_paypal_transaction {
    my $self = shift;
    return ( exists $self->params->{TENDER}
            && $self->params->{TENDER} eq 'P' )
        || exists $self->params->{BAID}
        || !$self->is_credit_card_transaction;
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Role::HasTender - Role which provides some methods describing a transaction

=head1 VERSION

version 0.000028

=head2 amount

The C<AMT> param

=head2 is_credit_card_transaction

C<Boolean>.  Returns true if this is a credit card transaction.

=head2 is_paypal_transaction

C<Boolean>.  Returns true if this is a PayPal transaction.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/webservice-paypal-paymentsadvanced/issues>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Role which provides some methods describing a transaction

