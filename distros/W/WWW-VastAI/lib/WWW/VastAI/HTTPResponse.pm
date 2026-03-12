package WWW::VastAI::HTTPResponse;
our $VERSION = '0.001';
# ABSTRACT: Internal HTTP response value object for pluggable IO backends

use Moo;

has status  => ( is => 'ro', required => 1 );
has content => ( is => 'ro', default  => sub { '' } );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::HTTPResponse - Internal HTTP response value object for pluggable IO backends

=head1 VERSION

version 0.001

=head1 DESCRIPTION

L<WWW::VastAI::HTTPResponse> is the transport-neutral response object returned
by implementations of L<WWW::VastAI::Role::IO>.

=head1 METHODS

=head2 status

Returns the numeric HTTP status code.

=head2 content

Returns the decoded response body content.

=head1 SEE ALSO

L<WWW::VastAI::Role::IO>, L<WWW::VastAI::HTTPRequest>, L<WWW::VastAI::LWPIO>

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
