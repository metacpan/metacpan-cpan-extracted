package WebService::PayPal::PaymentsAdvanced::Response;

use Moo;

use namespace::autoclean;

our $VERSION = '0.000028';

use List::AllUtils qw( any );
use Types::Common::String qw( NonEmptyStr );
use Types::Standard qw( ArrayRef Int Maybe );
use WebService::PayPal::PaymentsAdvanced::Error::Authentication ();
use WebService::PayPal::PaymentsAdvanced::Error::Generic        ();

has _nonfatal_result_codes => (
    init_arg => 'nonfatal_result_codes',
    is       => 'ro',
    isa      => ArrayRef [Int],
    required => 1,
);

has pnref => (
    is      => 'lazy',
    isa     => NonEmptyStr,
    default => sub { shift->params->{PNREF} },
);

# PPREF is only returned if PayPal was the payment processor.
has ppref => (
    is      => 'lazy',
    isa     => Maybe [NonEmptyStr],
    default => sub { shift->params->{PPREF} },
);

with(
    'WebService::PayPal::PaymentsAdvanced::Role::ClassFor',
    'WebService::PayPal::PaymentsAdvanced::Role::HasParams',
    'WebService::PayPal::PaymentsAdvanced::Role::HasMessage',
);

sub BUILD {
    my $self = shift;

    my $result = $self->params->{RESULT};

    return
        if Int()->check($result)
        && ( any { $result == $_ } @{ $self->_nonfatal_result_codes } );

    if ( $result && $result == 1 ) {
        $self->_class_for('Error::Authentication')->throw(
            message => 'Authentication error: ' . $self->message,
            params  => $self->params,
        );
    }

    $self->_class_for('Error::Generic')->throw(
        message => $self->message,
        params  => $self->params,
    );
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Response - Generic response object

=head1 VERSION

version 0.000028

=head1 SYNOPSIS

    use WebService::PayPal::PaymentsAdvanced::Response;
    my $response = WebService::PayPal::PaymentsAdvanced::Response->new(
        params => $params );

=head1 DESCRIPTION

This module provides a consistent interface for getting information from a
PayPal response, regardless of whether it comes from token creation, a redirect
or a silent POST.  It will be used as a parent class for other response
classes.  You should never need to create this object yourself.

=head1 METHODS

=head2 message

The contents of PayPal's RESPMSG parameter.

=head2 params

A C<HashRef> of parameters which have been returned by PayPal.

=head2 pnref

The contents of PayPal's PNREF parameter.

=head2 ppref

The contents of PayPal's PPREF parameter.

=head1 SEE ALSO

L<WebService::PayPal::PaymentsAdvanced::Response::FromHTTP>,
L<WebService::PayPal::PaymentsAdvanced::Response::FromRedirect>,
L<WebService::PayPal::PaymentsAdvanced::Response::FromSilentPost>,

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/webservice-paypal-paymentsadvanced/issues>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
#ABSTRACT: Generic response object

