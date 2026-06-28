#!/bin/false
# ABSTRACT: Structured exception class for OPNsense API errors
# PODNAME: WebService::OPNsense::Exception
use strictures 2;

package WebService::OPNsense::Exception;
$WebService::OPNsense::Exception::VERSION = '0.002';
use Carp qw( croak );
use Moo;
use namespace::clean;

use overload '""' => sub { shift->message }, fallback => 1;

extends 'Carp::Datum' if $ENV{CARP_DATUM};

has message     => ( is => 'ro', required => 1 );
has http_status => ( is => 'ro' );
has response    => ( is => 'ro' );

sub throw {
    my ( $class, %attrs ) = @_;
    croak $class->new(%attrs);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Exception - Structured exception class for OPNsense API errors

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use WebService::OPNsense::Exception;

    WebService::OPNsense::Exception->throw(
        message     => 'Not Found',
        http_status => 404,
        response    => $res,
    );

=head1 DESCRIPTION

Exception class used by L<WebService::OPNsense> to report API errors.
Stringifies to the error message via C<use overload '""'>.

When the environment variable C<CARP_DATUM> is set, this class extends
L<Carp::Datum> to enable structured exception handling and additional
context in stack traces.

=head1 ATTRIBUTES

=head2 C<message> (required)

Human-readable error description.

=head2 C<http_status>

HTTP status code, if applicable.

=head2 C<response>

Original L<WebService::Client::Response> object.

=head1 METHODS

=head2 throw

    WebService::OPNsense::Exception->throw(%attrs);

Constructs and throws a new exception.

=head1 SEE ALSO

L<WebService::OPNsense>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
