package WWW::Authentik::Error::Validation;

# ABSTRACT: Raised for wrong arguments, missing credentials and rejected tokens

use Moo;
extends 'WWW::Authentik::Error';

our $VERSION = '0.001';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Authentik::Error::Validation - Raised for wrong arguments, missing credentials and rejected tokens

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Nothing was sent to authentik: the arguments did not make sense, a required
credential was missing, or a token did not pass L<WWW::Authentik::OIDC/verify_token>.

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
