package WWW::Hetzner::HTTPResponse;

# ABSTRACT: HTTP response object for Hetzner API

use Moo;

our $VERSION = '0.101';


has status => (is => 'ro', required => 1);


has content => (is => 'ro', default => '');



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::HTTPResponse - HTTP response object for Hetzner API

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    use WWW::Hetzner::HTTPResponse;

    my $res = WWW::Hetzner::HTTPResponse->new(
        status  => 200,
        content => '{"servers":[]}',
    );

=head1 DESCRIPTION

Transport-independent HTTP response object. Returned by L<WWW::Hetzner::Role::IO>
backends and processed by L<WWW::Hetzner::Role::HTTP>.

=head2 status

The HTTP status code (e.g., 200, 404, 500).

=head2 content

The response body content.

=head1 SEE ALSO

L<WWW::Hetzner::HTTPRequest>, L<WWW::Hetzner::Role::IO>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-hetzner/issues>.

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
