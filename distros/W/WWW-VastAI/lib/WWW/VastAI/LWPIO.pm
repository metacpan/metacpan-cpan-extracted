package WWW::VastAI::LWPIO;
our $VERSION = '0.001';
# ABSTRACT: Default LWP::UserAgent-backed IO backend for WWW::VastAI

use Moo;
use HTTP::Request;
use LWP::UserAgent;
use WWW::VastAI::HTTPResponse;

with 'WWW::VastAI::Role::IO';

has user_agent => (
    is      => 'lazy',
    builder => sub {
        LWP::UserAgent->new(
            agent   => 'WWW-VastAI',
            timeout => 30,
        );
    },
);

sub call {
    my ($self, $req) = @_;

    my $http = HTTP::Request->new($req->method => $req->url);
    for my $name (keys %{ $req->headers }) {
        $http->header($name => $req->headers->{$name});
    }
    $http->content($req->content) if $req->has_content;

    my $response = $self->user_agent->request($http);

    return WWW::VastAI::HTTPResponse->new(
        status  => $response->code,
        content => $response->decoded_content,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::LWPIO - Default LWP::UserAgent-backed IO backend for WWW::VastAI

=head1 VERSION

version 0.001

=head1 DESCRIPTION

L<WWW::VastAI::LWPIO> is the default synchronous transport backend for
L<WWW::VastAI>. It adapts internal L<WWW::VastAI::HTTPRequest> objects to
L<HTTP::Request> and wraps L<LWP::UserAgent> responses as
L<WWW::VastAI::HTTPResponse>.

=head1 METHODS

=head2 user_agent

Returns the underlying L<LWP::UserAgent> instance used for requests.

=head2 call

    my $response = $io->call($request);

Executes a L<WWW::VastAI::HTTPRequest> and returns a
L<WWW::VastAI::HTTPResponse>.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::Role::IO>, L<LWP::UserAgent>

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
