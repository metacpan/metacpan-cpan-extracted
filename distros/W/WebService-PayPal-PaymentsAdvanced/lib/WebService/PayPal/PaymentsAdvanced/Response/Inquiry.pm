package WebService::PayPal::PaymentsAdvanced::Response::Inquiry;

use Moo;

use namespace::autoclean;

our $VERSION = '0.000026';

extends 'WebService::PayPal::PaymentsAdvanced::Response';

with 'WebService::PayPal::PaymentsAdvanced::Role::HasTransactionTime',
    'WebService::PayPal::PaymentsAdvanced::Role::HasTender';

1;

=pod

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Response::Inquiry - Response class for Inquiry transactions

=head1 VERSION

version 0.000026

=head1 DESCRIPTION

Response class for Inquiry transactions C<TRXTYPE=I>  You should not create
this response object directly. This class inherits from
L<WebService::PayPal::PaymentsAdvanced::Response> and includes the methods
provided by L<WebService::PayPal::PaymentsAdvanced::Role::HasTransactionTime>
and L<WebService::PayPal::PaymentsAdvanced::Role::HasTender>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Response class for Inquiry transactions

