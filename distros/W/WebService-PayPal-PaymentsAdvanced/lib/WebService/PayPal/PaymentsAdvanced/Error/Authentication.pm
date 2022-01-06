package WebService::PayPal::PaymentsAdvanced::Error::Authentication;

use Moo;

use namespace::autoclean;

our $VERSION = '0.000028';

extends 'Throwable::Error';

with 'WebService::PayPal::PaymentsAdvanced::Role::HasParams';

1;

# ABSTRACT: A Payments Advanced authentication error

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Error::Authentication - A Payments Advanced authentication error

=head1 VERSION

version 0.000028

=head1 SYNOPSIS

    use Try::Tiny;
    use WebService::PayPal::PaymentsAdvanced;
    my $payments = WebService::PayPal::PaymentsAdvanced->new(...);

    try {
        $payments->create_secure_token(...);
    }
    catch {
        die $_ unless blessed $_;
        if (
            $_->isa(
                'WebService::PayPal::PaymentsAdvanced::Error::Authentication')
            ) {
            log_auth_error(
                message => $_->message,
                params  => $_->params,
            );
        }

        # handle other exceptions
    };

=head1 DESCRIPTION

This class represents an authentication error returned by PayPal. It extends
L<Throwable::Error> and adds one attribute of its own.

=head1 METHODS

The C<$error->message()>, and C<$error->stack_trace()> methods are
inherited from L<Throwable::Error>.

=head2 params

Returns a C<HashRef> of params which was received from to PayPal.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/webservice-paypal-paymentsadvanced/issues>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
