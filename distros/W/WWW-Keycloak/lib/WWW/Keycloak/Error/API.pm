package WWW::Keycloak::Error::API;

# ABSTRACT: Raised when Keycloak answers with an HTTP error

use Moo;
extends 'WWW::Keycloak::Error';

our $VERSION = '0.001';


has http_status => (
  is       => 'ro',
  required => 1
);


has api_message => ( is => 'ro' );


has oauth_error => ( is => 'ro' );


sub is_not_found    { $_[0]->http_status == 404 ? 1 : 0 }
sub is_conflict     { $_[0]->http_status == 409 ? 1 : 0 }
sub is_unauthorized { $_[0]->http_status == 401 ? 1 : 0 }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Keycloak::Error::API - Raised when Keycloak answers with an HTTP error

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Keycloak reports errors in three shapes, and all of them end up in
L</api_message>: C<{"errorMessage": "..."}> from most of the Admin API,
C<{"error": "..."}> from some of it, and the OAuth form
C<{"error": "...", "error_description": "..."}> from the token endpoint, where
L</oauth_error> also carries the bare code.

=head2 http_status

The HTTP status code as a number, for example 409.

=head2 api_message

What Keycloak said, if it said anything.

=head2 oauth_error

The OAuth error code (C<invalid_grant>, C<authorization_pending>, ...) when
the error came from an OAuth endpoint.

=head2 is_not_found

=head2 is_conflict

=head2 is_unauthorized

True for status 404, 409 and 401.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-keycloak/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
