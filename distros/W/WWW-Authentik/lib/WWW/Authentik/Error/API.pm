package WWW::Authentik::Error::API;

# ABSTRACT: Raised when authentik answers with an HTTP error

use Moo;
extends 'WWW::Authentik::Error';

our $VERSION = '0.001';


has http_status => (
  is       => 'ro',
  required => 1
);


has api_message => ( is => 'ro' );


has field_errors => ( is => 'ro', default => sub { {} } );


has oauth_error => ( is => 'ro' );


has request_id => ( is => 'ro' );


has body => ( is => 'ro' );


sub is_bad_request  { $_[0]->http_status == 400 ? 1 : 0 }
sub is_unauthorized { $_[0]->http_status == 401 ? 1 : 0 }
sub is_forbidden    { $_[0]->http_status == 403 ? 1 : 0 }
sub is_not_found    { $_[0]->http_status == 404 ? 1 : 0 }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Authentik::Error::API - Raised when authentik answers with an HTTP error

=head1 VERSION

version 0.001

=head1 DESCRIPTION

authentik reports errors in four shapes, and all of them end up in
L</api_message>:

=over 4

=item C<< {"detail": "..."} >>

Most of the API where no field is at fault: a refused token (403), something
missing (404), a method that is not allowed (405), a body that is not JSON
(400).

=item C<< {"<field>": ["..."], "non_field_errors": ["..."]} >>

Validation, including a duplicate: authentik answers a second create with
B<400> and a field error, not with 409. There is deliberately no
C<is_conflict> here, because a duplicate cannot be told from any other
validation error except by its text. L</field_errors> carries the fields;
nested shapes (C<< {"grant_types": {"0": [...]}} >>) are flattened to
C<grant_types.0>.

=item C<< {"error": "...", "error_description": "...", "request_id": "..."} >>

The token, device and revocation endpoints. L</oauth_error> carries the bare
code, so a device-flow poll can tell C<authorization_pending> from a real
failure.

=item An empty body with a C<WWW-Authenticate> header

The userinfo endpoint. The code and the description are read out of the
header into L</oauth_error> and L</api_message>.

=back

=head2 http_status

The HTTP status code as a number, for example 400.

=head2 api_message

What authentik said, if it said anything: the C<detail>, the field errors
joined to one line, or the OAuth code with its description.

=head2 field_errors

A hash of field name to the list of messages for it, empty when the error had
no field. Nested field errors are flattened with a dot.

    $error->field_errors->{username}      # [ 'This field must be unique.' ]
    $error->field_errors->{'grant_types.0'}

=head2 oauth_error

The OAuth error code (C<invalid_grant>, C<invalid_client>,
C<authorization_pending>, C<invalid_token>, ...) when the error came from an
OAuth endpoint.

=head2 request_id

The C<request_id> authentik puts into an OAuth error, for finding the request
in authentik's log.

=head2 body

What came back, up to 500 characters, when it was not one of the shapes
above: a proxy's HTML, plain text, a JSON array. Undef when the body was
empty. This is where to look when C<base_url> points at something that is not
an authentik.

=head2 is_bad_request

=head2 is_unauthorized

=head2 is_forbidden

=head2 is_not_found

True for status 400, 401, 403 and 404. A refused API token is 403, not 401.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-authentik/issues>.

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
