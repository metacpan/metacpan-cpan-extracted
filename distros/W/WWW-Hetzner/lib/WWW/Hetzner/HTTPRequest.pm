package WWW::Hetzner::HTTPRequest;

# ABSTRACT: HTTP request object for Hetzner API

use Moo;

our $VERSION = '0.101';


has method => (is => 'ro', required => 1);


has url => (is => 'ro', required => 1);


has headers => (is => 'ro', default => sub { {} });


has content => (is => 'ro', predicate => 1);



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::HTTPRequest - HTTP request object for Hetzner API

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    use WWW::Hetzner::HTTPRequest;

    my $req = WWW::Hetzner::HTTPRequest->new(
        method  => 'GET',
        url     => 'https://api.hetzner.cloud/v1/servers',
        headers => { Authorization => 'Bearer token' },
    );

=head1 DESCRIPTION

Transport-independent HTTP request object. Used by L<WWW::Hetzner::Role::HTTP>
to build requests that are then executed by an L<WWW::Hetzner::Role::IO>
backend.

=head2 method

The HTTP method (GET, POST, PUT, DELETE).

=head2 url

The complete request URL.

=head2 headers

Hashref of HTTP headers.

=head2 content

The request body content (JSON string). Use C<has_content> to check presence.

=head1 SEE ALSO

L<WWW::Hetzner::HTTPResponse>, L<WWW::Hetzner::Role::IO>

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
