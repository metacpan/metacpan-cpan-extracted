package WWW::Zitadel::Error;

# ABSTRACT: Structured exception classes for WWW::Zitadel

use Moo;

# namespace::clean must NOT be used here: it would strip the overload
# operator stub that is installed by 'use overload' below.
use overload '""' => sub { $_[0]->message }, fallback => 1;

our $VERSION = '0.001';


has message => (
    is       => 'ro',
    required => 1,
);

package WWW::Zitadel::Error::Validation;

# ABSTRACT: Raised when a required argument is missing or invalid

use Moo;
extends 'WWW::Zitadel::Error';
use namespace::clean;

package WWW::Zitadel::Error::Network;

# ABSTRACT: Raised when an HTTP request fails at the transport level

use Moo;
extends 'WWW::Zitadel::Error';
use namespace::clean;

package WWW::Zitadel::Error::API;

# ABSTRACT: Raised when the ZITADEL API returns a non-successful HTTP response

use Moo;
extends 'WWW::Zitadel::Error';
use namespace::clean;


has http_status => ( is => 'ro' );
has api_message => ( is => 'ro' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Zitadel::Error - Structured exception classes for WWW::Zitadel

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use WWW::Zitadel::Management;
    use WWW::Zitadel::Error;

    eval { $mgmt->get_user($id) };
    if (my $err = $@) {
        if (ref $err && $err->isa('WWW::Zitadel::Error::API')) {
            warn "API error (HTTP " . $err->http_status . "): " . $err->message;
        }
        elsif (ref $err && $err->isa('WWW::Zitadel::Error::Validation')) {
            warn "Bad call: " . $err->message;
        }
        else {
            die $err;
        }
    }

=head1 DESCRIPTION

Three exception classes, all inheriting from C<WWW::Zitadel::Error>:

=over 4

=item C<WWW::Zitadel::Error::Validation>

Thrown when a required argument is missing or invalid (empty issuer, missing
user_id, etc.).

=item C<WWW::Zitadel::Error::Network>

Thrown when a discovery, JWKS, or other HTTP fetch fails at the transport level
(connection refused, timeout, non-success response on OIDC endpoints).

=item C<WWW::Zitadel::Error::API>

Thrown when the Management API returns a non-2xx response. Carries
C<http_status> (the status line string) and C<api_message> (the C<message>
field from the JSON error body, if any).

=back

All classes overload stringification to return C<message>, so existing code
that inspects C<$@> as a plain string continues to work without modification.

=head2 message

Human-readable error description. The object stringifies to this value,
so existing C<eval>/C<$@> patterns that match on the error string continue
to work unchanged.

=head2 http_status

The HTTP status line returned by the server, e.g. C<"400 Bad Request">.

=head2 api_message

The C<message> field from the JSON error body returned by the API, if present.

=head1 SEE ALSO

L<WWW::Zitadel>, L<WWW::Zitadel::OIDC>, L<WWW::Zitadel::Management>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-zitadel/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
