package WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST::PayPal;

use Moo;

our $VERSION = '0.000021';

extends 'WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST';

with 'WebService::PayPal::PaymentsAdvanced::Role::HasPayPal';

1;

=pod

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST::PayPal - Response class for PayPal Silent POST transactions

=head1 VERSION

version 0.000021

=head1 DESCRIPTION

Response class for PayPal Silent POST transactions C<TRXTYPE=I>  You should not
create this response object directly.  This class inherits from
L<WebService::PayPal::PaymentsAdvanced::Response::FromSilentPOST> and includes
the methods provided by
L<WebService::PayPal::PaymentsAdvanced::Role::HasPayPal>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Response class for PayPal Silent POST transactions

