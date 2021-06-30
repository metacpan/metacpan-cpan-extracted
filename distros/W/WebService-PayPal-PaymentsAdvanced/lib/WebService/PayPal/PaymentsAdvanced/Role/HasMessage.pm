package WebService::PayPal::PaymentsAdvanced::Role::HasMessage;

use Moo::Role;

use namespace::autoclean;

our $VERSION = '0.000027';

use Types::Common::String qw( NonEmptyStr );

has message => (
    is       => 'lazy',
    isa      => NonEmptyStr,
    init_arg => undef,
);

sub _build_message {
    my $self = shift;
    return $self->params->{RESPMSG};
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Role::HasMessage - Role which provides message attribute to exception and response classes.

=head1 VERSION

version 0.000027

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
#ABSTRACT: Role which provides message attribute to exception and response classes.
