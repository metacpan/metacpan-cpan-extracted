package Web::API::Mock;
use 5.008005;
use strict;
use warnings;

use Plack::Request;
use Web::API::Mock::Parser;
use Web::API::Mock::Resource;
use Class::Accessor::Lite (
    new => 1,
    rw  => [ qw/config files not_implemented_urls map/ ],
);

our $VERSION = "0.11";

sub setup {
    my ($self, $files, $not_implemented_url_file) = @_;
    my $markdown;
    for my $file (@{$files}) {
        open my $fh, "<:encoding(utf8)", $file or die "cannot open file. $file:$!";
        while ( my $line = <$fh> ) {
            $markdown .= $line;
        }
        close($fh);
    }
    my $parser = Web::API::Mock::Parser->new();
    $parser->md($markdown);
    $self->map($parser->create_map());

    $self->not_implemented_urls([]);
    if ($not_implemented_url_file) {
        open my $fh, "<:encoding(utf8)", $not_implemented_url_file or die "cannot open file. $not_implemented_url_file:$!";
        while ( my $line = <$fh> ) {
            chomp $line;
            $line =~ s/\ //g;
            push @{$self->not_implemented_urls}, $line;
        }
        close($fh);
    }
}

sub psgi {
    my $self = shift;
    sub {
        my $env = shift;

        my $req = Plack::Request->new($env);
        my $plack_response = $req->new_response(404);
        my $response  = Web::API::Mock::Resource->status_404;

        if ($self->check_implemented_url($req->method, $req->path_info)) {
            $response  = Web::API::Mock::Resource->status_501;
        }
        else {
            $response = $self->map->request($req->method, $req->path_info);
            if (!$response || !$response->{status}) {
                $response  = Web::API::Mock::Resource->status_404;
            }
        }

        $plack_response->headers($response->{header});
        $plack_response->content_type($response->{content_type});
        $plack_response->status($response->{status});
        $plack_response->body($response->{body});
        $plack_response->finalize;
    };
}

sub check_implemented_url {
    my ($self, $method, $path) = @_;

    return if ( ref $self->not_implemented_urls ne 'ARRAY');

    my $target = join(',', $method,$path);
    my ($url) = grep { m!^$target$! } @{$self->not_implemented_urls};
    # TODO 再帰
    unless ($url) {
        $target =~ s!^(.+\/).+?$!$1\{.+?\}!;
        ($url) = grep { m!^$target$! } @{$self->not_implemented_urls};
    }
    return $url;
}

1;
__END__

=encoding utf-8

=head1 NAME

Web::API::Mock - It's new $module

=head1 SYNOPSIS

    $ git clone  git@github.com:takihito/Web-API-Mock.git
    $ cpanm ./Web-API-Mock

    or

    $ cpanm Web::API::Mock

    :
    $ run-api-mock --help
    Usage:
            $ run-api-mock --files api.md --not-implemented-urls url.txt --port 8080

=head1 DESCRIPTION

## Install

<pre>
$ git clone  git@github.com:takihito/Web-API-Mock.git
$ cpanm ./Web-API-Mock

or

$ cpanm Web::API::Mock

:
$ run-api-mock --help
Usage:
        $ run-api-mock --files api.md --not-implemented-urls url.txt --port 8080
</pre>


## Create API Documentation

* http://apiblueprint.org

<pre>
# api.md

## GET /hello

+ Response 200 (text/plain)

        Hello World
</pre>

## Start Mock Server

<pre>
$ run-api-mock --files api.md
HTTP::Server::PSGI: Accepting connections at http://0:5000
</pre>

## Options

* files
 * API Document Files.

<pre>
$ run-api-mock --files api1.md --files api2.md
</pre>

* not-implemented-urls
 * Add "501 Not Implemented" info (Method and URL).

<pre>
GET,/hello/hoge
POST,/hello/foo
</pre>

* port
 * server port

* Other...
 * plackup options

## Switch to the Production API

By using nginx

see not-implemented-urls option.

<pre>
$ run-api-mock --files api.md --not-implemented-urls url.txt --port 5001
</pre>

<pre>
upstream mock_backend {
   server 127.0.0.1:5001;
}

upstream prod_backend {
   server 127.0.0.1:5002;
}

server {

:
:

    location ~ ^/ {
         proxy_intercept_errors on;
         proxy_pass http://mock_backend;
         proxy_set_header Host $host;
    }

    error_page 501 =200 @prod;
    location @prod {
        proxy_pass http://prod_backend;
        proxy_set_header Host $host;
    }
</pre>

=head1 LICENSE

Copyright (C) akihito.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

akihito E<lt>takeda.akihito@gmail.comE<gt>

=cut

