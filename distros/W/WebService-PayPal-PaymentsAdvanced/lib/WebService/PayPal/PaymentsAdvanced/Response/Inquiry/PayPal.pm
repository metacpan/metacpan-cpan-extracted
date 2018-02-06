package WebService::PayPal::PaymentsAdvanced::Response::Inquiry::PayPal;

use Moo;

use namespace::autoclean;

our $VERSION = '0.000025';

extends 'WebService::PayPal::PaymentsAdvanced::Response::Inquiry';

with 'WebService::PayPal::PaymentsAdvanced::Role::HasPayPal';

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Response::Inquiry::PayPal - Response class for PayPal Inquiry transactions

=head1 VERSION

version 0.000025

=head1 DESCRIPTION

Response class for PayPal Inquiry transactions C<TRXTYPE=I>  You should not
create this response object directly. This class inherits from
L<WebService::PayPal::PaymentsAdvanced::Response::Inquiry> and includes the
methods provided by L<WebService::PayPal::PaymentsAdvanced::Role::HasPayPal>.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/webservice-paypal-paymentsadvanced/issues>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Response class for PayPal Inquiry transactions

