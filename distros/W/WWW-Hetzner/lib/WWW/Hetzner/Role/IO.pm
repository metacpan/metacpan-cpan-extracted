package WWW::Hetzner::Role::IO;

# ABSTRACT: Interface role for pluggable HTTP backends

use Moo::Role;

our $VERSION = '0.101';

requires 'call';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Role::IO - Interface role for pluggable HTTP backends

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    package My::AsyncIO;
    use Moo;
    with 'WWW::Hetzner::Role::IO';

    sub call {
        my ($self, $req) = @_;
        # Execute HTTP request, return WWW::Hetzner::HTTPResponse
        ...
    }

=head1 DESCRIPTION

This role defines the interface that HTTP backends must implement.
L<WWW::Hetzner::Role::HTTP> delegates all HTTP communication through this
interface, making it possible to swap out the transport layer.

The default backend is L<WWW::Hetzner::LWPIO> (synchronous, using
L<LWP::UserAgent>). To use an async event loop, implement this role
with e.g. L<Net::Async::HTTP> or L<Mojo::UserAgent>.

=head1 REQUIRED METHODS

=head2 call($req)

Execute an HTTP request. Receives a L<WWW::Hetzner::HTTPRequest> with
C<method>, C<url>, C<headers>, and optionally C<content> already set.

Must return a L<WWW::Hetzner::HTTPResponse> with C<status> and C<content>.

=head1 SEE ALSO

L<WWW::Hetzner::LWPIO>, L<WWW::Hetzner::Role::HTTP>

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
