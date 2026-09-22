package WWW::Hetzner::LWPIO;

# ABSTRACT: Synchronous HTTP backend using LWP::UserAgent

use Moo;
use LWP::UserAgent;
use HTTP::Request;
use WWW::Hetzner::HTTPResponse;

with 'WWW::Hetzner::Role::IO';

our $VERSION = '0.101';


has timeout => (is => 'ro', default => 30);


has ua => (
    is      => 'lazy',
    builder => sub {
        my $self = shift;
        LWP::UserAgent->new(
            agent   => 'WWW-Hetzner/' . $VERSION,
            timeout => $self->timeout,
        );
    },
);


sub call {
    my ($self, $req) = @_;

    my $http_req = HTTP::Request->new($req->method => $req->url);

    my $headers = $req->headers;
    for my $header (keys %$headers) {
        $http_req->header($header => $headers->{$header});
    }

    $http_req->content($req->content) if $req->has_content;

    my $response = $self->ua->request($http_req);

    return WWW::Hetzner::HTTPResponse->new(
        status  => $response->code,
        content => $response->decoded_content // '',
    );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::LWPIO - Synchronous HTTP backend using LWP::UserAgent

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    use WWW::Hetzner::LWPIO;

    my $io = WWW::Hetzner::LWPIO->new(timeout => 60);

=head1 DESCRIPTION

Default synchronous HTTP backend using L<LWP::UserAgent>. Implements
L<WWW::Hetzner::Role::IO>.

=head2 timeout

Timeout in seconds for HTTP requests. Defaults to 30.

=head2 ua

L<LWP::UserAgent> instance. Built lazily.

=head2 call($req)

Execute an L<WWW::Hetzner::HTTPRequest> via LWP and return a
L<WWW::Hetzner::HTTPResponse>.

=head1 HTTP DEBUGGING

Load L<LWP::ConsoleLogger::Everywhere> to see full HTTP traffic (headers,
bodies, status codes) without changing your code:

    perl -MLWP::ConsoleLogger::Everywhere your_script.pl

=head1 SEE ALSO

L<WWW::Hetzner::Role::IO>, L<WWW::Hetzner::Role::HTTP>,
L<LWP::ConsoleLogger::Everywhere>

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
