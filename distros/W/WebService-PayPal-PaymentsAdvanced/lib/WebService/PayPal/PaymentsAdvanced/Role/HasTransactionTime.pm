package WebService::PayPal::PaymentsAdvanced::Role::HasTransactionTime;

use Moo::Role;

use namespace::autoclean;

our $VERSION = '0.000027';

use feature qw( state );

use DateTime::TimeZone;
use DateTime::Format::MySQL;
use Types::Standard qw( InstanceOf Maybe );

has transaction_time => (
    is  => 'lazy',
    isa => Maybe [ InstanceOf ['DateTime'] ],
);

sub _build_transaction_time {
    my $self = shift;

    state $time_zone
        = DateTime::TimeZone->new( name => 'America/Los_Angeles' );

    return undef unless my $transtime = $self->params->{TRANSTIME};

    my $dt = DateTime::Format::MySQL->parse_datetime($transtime);
    $dt->set_time_zone($time_zone);
    return $dt;
}
1;

=pod

=encoding UTF-8

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Role::HasTransactionTime - Role which converts TRANSTIME into a DateTime object

=head1 VERSION

version 0.000027

=head2 transaction_time

Returns C<TRANSTIME> in the form of a DateTime object

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/webservice-paypal-paymentsadvanced/issues>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Role which converts TRANSTIME into a DateTime object

