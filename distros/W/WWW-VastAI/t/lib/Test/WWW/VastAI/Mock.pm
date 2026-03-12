package Test::WWW::VastAI::MockIO;

use Moo;
use JSON::MaybeXS qw(decode_json encode_json);
use WWW::VastAI::HTTPResponse;

with 'WWW::VastAI::Role::IO';

has routes => ( is => 'ro', default => sub { {} } );
has base_urls => ( is => 'ro', default => sub { [] } );

sub call {
    my ($self, $req) = @_;

    my $path = $req->url;
    for my $base (@{ $self->base_urls }) {
        $path =~ s{^\Q$base\E}{};
    }

    my %opts;
    if ($req->has_content && defined $req->content && length $req->content) {
        $opts{body} = decode_json($req->content);
    }

    my $lookup = $path;
    $lookup =~ s{\?.*$}{};
    my $key = $req->method . ' ' . $lookup;

    if (exists $self->routes->{$key}) {
        return _handle($self->routes->{$key}, $req->method, $lookup, %opts);
    }

    for my $pattern (keys %{ $self->routes }) {
        next unless $lookup =~ /$pattern/;
        return _handle($self->routes->{$pattern}, $req->method, $lookup, %opts);
    }

    die "No mock route for: $key";
}

sub _handle {
    my ($handler, $method, $path, %opts) = @_;

    return $handler if ref $handler eq 'WWW::VastAI::HTTPResponse';

    my $data = ref $handler eq 'CODE'
        ? $handler->($method, $path, %opts)
        : $handler;

    return $data if ref $data eq 'WWW::VastAI::HTTPResponse';

    return WWW::VastAI::HTTPResponse->new(
        status  => 200,
        content => ref $data ? encode_json($data) : ($data // ''),
    );
}

package Test::WWW::VastAI::Mock;

use strict;
use warnings;
use WWW::VastAI;

sub import {
    my $caller = caller;
    no strict 'refs';
    *{"${caller}::mock_vast"} = \&mock_vast;
}

sub mock_vast {
    my (%routes) = @_;

    my $io = Test::WWW::VastAI::MockIO->new(
        routes    => \%routes,
        base_urls => [
            'https://console.vast.ai/api/v0',
            'https://console.vast.ai/api/v1',
            'https://run.vast.ai',
        ],
    );

    return WWW::VastAI->new(
        api_key => 'vast-test-key',
        io      => $io,
    );
}

1;
