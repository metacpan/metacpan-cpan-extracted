package WWW::VastAI::HTTPRequest;
our $VERSION = '0.001';
# ABSTRACT: Internal HTTP request value object for pluggable IO backends

use Moo;

has method  => ( is => 'ro', required => 1 );
has url     => ( is => 'ro', required => 1 );
has headers => ( is => 'ro', default  => sub { {} } );
has content => ( is => 'ro' );

sub has_content { defined shift->content }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::HTTPRequest - Internal HTTP request value object for pluggable IO backends

=head1 VERSION

version 0.001

=head1 DESCRIPTION

L<WWW::VastAI::HTTPRequest> is the transport-neutral request object passed to
implementations of L<WWW::VastAI::Role::IO>.

=head1 METHODS

=head2 method

Returns the HTTP method verb for the request.

=head2 url

Returns the absolute request URL.

=head2 headers

Returns the header hashref that will be sent to the backend.

=head2 content

Returns the raw request body, if any.

=head2 has_content

    if ($request->has_content) { ... }

Returns true when the request includes a content body.

=head1 SEE ALSO

L<WWW::VastAI::Role::IO>, L<WWW::VastAI::HTTPResponse>, L<WWW::VastAI::LWPIO>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-vastai/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
