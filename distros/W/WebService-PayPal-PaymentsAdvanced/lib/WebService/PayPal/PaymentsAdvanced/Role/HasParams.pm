package WebService::PayPal::PaymentsAdvanced::Role::HasParams;

use Moo::Role;

use namespace::autoclean;

our $VERSION = '0.000023';

use Types::Standard qw( HashRef );

has params => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Role::HasParams - Role which provides params attribute to exception and response classes.

=head1 VERSION

version 0.000023

=head1 METHODS

=head2 params

The parameters returned by PayPal

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/webservice-paypal-paymentsadvanced/issues>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
#ABSTRACT: Role which provides params attribute to exception and response classes.

