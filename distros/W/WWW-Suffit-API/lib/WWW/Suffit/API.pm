package WWW::Suffit::API;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

WWW::Suffit::API - The Suffit API

=head1 VERSION

API Version 1.04

=head1 DESCRIPTION

This library provides server API methods and describe it

=head2 MEDIA TYPES

The API currently supports only JSON as an exchange format. Be sure to set both the C<Content-Type>
and C<Accept> headers for every request as C<application/json>.

All Date objects are returned in L<ISO 8601|https://tools.ietf.org/html/rfc3339> format: C<YYYY-MM-DDTHH:mm:ss.SSSZ>
or in unixtime format (epoch), eg.: C<1682759233>

=head2 CHARACTER SET

API supports a subset of the UTF-8 specification. Specifically, any character that can be encoded in
three bytes or less is supported. BMP characters and supplementary characters that must be encoded
using four bytes aren't supported at this time.

=head2 HTTP METHODS

Where possible, the we strives to use appropriate HTTP methods for each action.

=head3 GET

Used for retrieving objects

=head3 POST

Used for creating objects or performing custom actions (such as user lifecycle operations).
For POST requests with no C<body> param, set the C<Content-Length> header to zero.

=head3 PUT

Used for replacing objects or collections. For PUT requests with no C<body> param, set the C<Content-Length> header to zero.

=head3 PATCH

Used for partially updating objects

=head3 DELETE

Used for deleting objects

=head2 IP ADDRESS

The public IP address of your application is automatically used as the client IP address for your request.
The API supports the standard C<X-Forwarded-For> HTTP header to forward the originating client's IP address
if your application is behind a proxy server or acting as a sign-in portal or gateway.

B<Note:> The public IP address of your trusted web application must be a part of the allowlist in your
org's network security settings as a trusted proxy to forward the user agent's original IP address
with the C<X-Forwarded-For> HTTP header.

=head2 ERRORS

All successful requests return a 200 status if there is content to return or a 204 status
if there is no content to return.

All requests that result in an error return the appropriate 4xx or 5xx error code with a custom JSON
error object:

    {
      "code": "E0001",
      "error": "API validation failed",
      "status": false
    }

or

    {
      "code": "E0001",
      "message": "API validation failed",
      "status": false
    }

=over 4

=item code

A code that is associated with this error type

=item error

A natural language explanation of the error

=item message

A natural language explanation of the error (=error)

=item status

Any errors always return the status false

=back

List of codes see L<WWW::Suffit::API/"ERROR CODES">

=head2 AUTHENTICATION

Suffit APIs support two authentication options: session and tokens.

The Suffit API requires the custom HTTP authentication scheme Token or Bearer for API token authentication.
Requests must have a valid API token specified in the HTTP Authorization header with the Token/Bearer
scheme or HTTP X-Token header.

For example:

    X-Token: 00QCjAl4MlV-WPXM...0HmjFx-vbGua
    Authorization: Token 00QCjAl4MlV-WPXM...0HmjFx-vbGua
    Authorization: Bearer 00QCjAl4MlV-WPXM...0HmjFx-vbGua

=head1 METHODS

This class inherits all methods from L<Mojo::Base> and implements the following new ones

=head2 hint

    my $hint = $api->hint;
    my $hint = $api->hint('E1234');

Get hint by error code

=head2 ERROR CODES

List of common Suffit API error codes

=over 4

=item B<E0xxx> -- General API error codes

B<E01xx>, B<E02xx>, B<E03xx>, B<E04xx> and B<E05xx> are reserved as HTTP errors

    API   | HTTP  | DESCRIPTION
   -------+-------+-------------------------------------------------
    E0000   [ * ]   Ok (general)
    E0100   [100]   Continue
    E0200   [200]   OK (HTTP)
    E0300   [300]   Multiple Choices
    E0400   [400]   Bad Request
    E0500   [500]   Internal Server Error

=item B<E10xx> -- Public API error codes

B<E1000-E1029> - authentication and authorization Suffit API error codes.
See L<WWW::Suffit::Server::Auth/"ERROR CODES"> for details

B<E1030-E1059> - public Suffit API error codes.
See L<WWW::Suffit::Server::API/"ERROR CODES"> for details

=item B<E11xx> -- Private API error codes

B<E1100-E1109> - V1 Suffit API error codes.
See L<WWW::Suffit::Server::API::V1/"ERROR CODES"> for details

B<E1110-E1119> - NoAPI Suffit API error codes.
See L<WWW::Suffit::Server::API::NoAPI/"ERROR CODES"> for details

B<E1120-E1199> - User profile Suffit API error codes.
See L<WWW::Suffit::Server::API::User/"ERROR CODES"> for details

=item B<E12xx> -- Admin API error codes

B<E1200-E1299> - Admin Suffit API error codes.
See L<WWW::Suffit::Server::API::Admin/"ERROR CODES"> for details

=item B<E13xx> -- AuthDB error codes

B<E1300-E1399> - AuthDB error codes.
See L<WWW::Suffit::AuthDB/"ERROR CODES"> for details

=item B<E14xx> -- Error codes are reserved for future use

=item B<E15xx> -- Error codes are reserved for future use

=item B<E16xx> -- Error codes are reserved for future use

=item B<E17xx> -- Error codes are reserved for future use

=item B<E18xx> -- Error codes are reserved for future use

=item B<E19xx> -- Error codes are reserved for future use

=item B<E7xxx> -- Application error code

Error codes for user applications

=back

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.04';

use Mojo::Base -base;

use Mojo::Loader qw/data_section/;
use Mojo::Util qw/trim/;

use WWW::Suffit::Cache;

has cache  => sub { WWW::Suffit::Cache->new };

sub hint {
    my $self = shift;
    my $name = shift || 'E0000';
    my @args = @_;
    my $cache = $self->cache;
    if (my $tpl = $cache->get($name)) {
        return trim($tpl) unless scalar @args;
        return trim(sprintf($tpl, @args));
    }
    my $tpl = data_section(__PACKAGE__, $name) // '';
    $cache->set($name => $tpl);
    return trim($tpl) unless scalar @args;
    return trim(sprintf($tpl, @args));
}

1;

__DATA__

@@ E0000

Ok

@@ Etest

foo with %s

@@ E1307

The authorization database is not initialized, but You can initialize it using `init` subcommand
