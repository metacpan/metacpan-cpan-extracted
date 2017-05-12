package WebService::PayPal::PaymentsAdvanced::Response::Credit;

use Moo;

our $VERSION = '0.000021';

extends 'WebService::PayPal::PaymentsAdvanced::Response';

with 'WebService::PayPal::PaymentsAdvanced::Role::HasTransactionTime';

1;

=pod

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Response::Credit - Response class to refund (credit) transactions

=head1 VERSION

version 0.000021

=head1 DESCRIPTION

Response class for transaction refunding C<TRXTYPE=C>  You should not
create this response object directly.  This class inherits from
L<WebService::PayPal::PaymentsAdvanced::Response> and includes the methods
provided by L<WebService::PayPal::PaymentsAdvanced::Role::HasTransactionTime>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Response class to refund (credit) transactions

