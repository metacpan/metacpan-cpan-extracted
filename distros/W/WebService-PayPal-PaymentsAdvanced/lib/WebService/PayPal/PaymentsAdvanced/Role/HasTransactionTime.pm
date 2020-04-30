package WebService::PayPal::PaymentsAdvanced::Role::HasTransactionTime;

use Moo::Role;

use namespace::autoclean;

our $VERSION = '0.000026';

use feature qw( state );

use DateTime::TimeZone;
use DateTime::Format::MySQL;
use Types::Standard qw( InstanceOf );

has transaction_time => (
    is  => 'lazy',
    isa => InstanceOf ['DateTime'],
);

sub _build_transaction_time {
    my $self = shift;

    state $time_zone
        = DateTime::TimeZone->new( name => 'America/Los_Angeles' );
    my $dt = DateTime::Format::MySQL->parse_datetime(
        $self->params->{TRANSTIME} );
    $dt->set_time_zone($time_zone);
    return $dt;
}
1;

=pod

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Role::HasTransactionTime - Role which converts TRANSTIME into a DateTime object

=head1 VERSION

version 0.000026

=head2 transaction_time

Returns C<TRANSTIME> in the form of a DateTime object

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Role which converts TRANSTIME into a DateTime object

