package WWW::VastAI::Role::IO;
our $VERSION = '0.001';
# ABSTRACT: Role for pluggable HTTP backends used by WWW::VastAI

use Moo::Role;

requires 'call';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::Role::IO - Role for pluggable HTTP backends used by WWW::VastAI

=head1 VERSION

version 0.001

=head1 DESCRIPTION

L<WWW::VastAI::Role::IO> defines the minimal interface required by
L<WWW::VastAI> transport backends. A backend receives a
L<WWW::VastAI::HTTPRequest> and must return a L<WWW::VastAI::HTTPResponse>.

=head1 REQUIRED METHODS

=head2 call

    my $response = $io->call($request);

Executes the given L<WWW::VastAI::HTTPRequest> and returns a
L<WWW::VastAI::HTTPResponse>.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::HTTPRequest>, L<WWW::VastAI::HTTPResponse>,
L<WWW::VastAI::LWPIO>

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
