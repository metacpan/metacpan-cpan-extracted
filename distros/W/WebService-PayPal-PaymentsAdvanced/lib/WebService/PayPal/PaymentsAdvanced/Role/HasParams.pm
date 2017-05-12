package WebService::PayPal::PaymentsAdvanced::Role::HasParams;

use Moo::Role;

our $VERSION = '0.000021';

use Types::Standard qw( HashRef );

has params => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

1;

=pod

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Role::HasParams - Role which provides params attribute to exception and response classes.

=head1 VERSION

version 0.000021

=head1 METHODS

=head2 params

The parameters returned by PayPal

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
#ABSTRACT: Role which provides params attribute to exception and response classes.

