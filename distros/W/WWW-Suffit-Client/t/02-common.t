#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <minus@serzik.com>
#
# Copyright (C) 1998-2023 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Test::More;
use WWW::Suffit::Client;
use WWW::Suffit::Util qw/json_load json_save/;

use constant STATFILE => 'stat.tmp';
use constant USERNAME => 'test';
use constant PASSWORD => 'test';
use constant BASE_URLS => [
        'https://owl.localhost:8695/api',
        'http://localhost/api',
        'https://localhost/api',
    ];
use constant INSTANCE => {
        insecure            => 1, # IO::Socket::SSL::set_defaults(SSL_verify_mode => 0); # Skip verify for test only!
        max_redirects       => 2,
        connect_timeout     => 3,
        inactivity_timeout  => 5,
        request_timeout     => 10,
        #token               => "",
        #proxy               => "",
        #username            => "test", # For HTTP Basic Authorization
        #password            => "test", # For HTTP Basic Authorization
    };

# Base URLs
my @base_urls = @{(BASE_URLS)};
unshift @base_urls, $ENV{SUFFIT_SERVER_URL}
    if $ENV{SUFFIT_SERVER_URL};
#note explain \@base_urls;

plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";

# Create the instance
my $instance_args = {%{(INSTANCE)}};
my ($client, $base_url);
for (@base_urls) {
    $base_url = $_;
    $instance_args->{url} = $base_url;
    $client = WWW::Suffit::Client->new(%$instance_args);
    last if $client->check; # Check is ok
    note("Skipped ", $base_url, ": ", $client->error || 'unknown');
    $instance_args->{url} = $base_url = '';
}

plan skip_all => "Can't initialize the client. No working server found (by URL)" unless $client->status;
#plan skip_all => "Authorization failed" unless $client->res->headers->header('X-Authorized');

# Ok (check)
note $client->tx_string;
ok($client->status, sprintf("Base URL: %s", $base_url));
#note $client->trace;

# API Check
ok($client->api_check, "API Check")
    or diag($client->res->json("/message") || $client->error || $client->res->message);
#note $client->trace;
#note explain $client->res->json;

# Authorize as test user
my $is_authorized = $client->authorize(USERNAME, PASSWORD, { encrypted => \0 });
if ($is_authorized) { # Ok
    ok(1, "Authorize");
} elsif ($client->code == 401 or $client->code == 403) { # Not authorized
    ok(1, sprintf("Skip authorization. The server returned %d status code", $client->code));
    diag($client->res->json("/message") || $client->error || $client->res->message);
} else {
    ok(0, "Authorize");
    diag($client->res->json("/message") || $client->error || $client->res->message);
}

# Get auth data
my ($access_token, $public_key);
if ($is_authorized) {
    # Get access token of test user from authorization response
    $access_token = $client->res->json('/token') // '';
    ok length($access_token), "Has access token"; #note $access_token;
    $client->token($access_token); # Set token to client

    # Get RSA public key of test user from authorization response
    $public_key = $client->res->json('/public_key') // '';
    ok length($public_key), "Has RSA public key"; # note $public_key;
    $client->public_key($public_key); # Set public_key to client
}

# Dump data to temp stat file
ok(json_save(STATFILE, {
    base_url        => $base_url,
    instance_args   => $instance_args,
    is_authorized   => $is_authorized ? \1 : \0,
    access_token    => $access_token,
    public_key      => $public_key,
}), "Dump data to temp stat file");

# Get API token
#ok($client->api_token(), "Get API token") or diag($client->error);
#my $api_token = $client->res->json('/token') // '';
#diag explain $client->res->json;

done_testing;

__END__

SUFFIT_SERVER_URL='https://owl.localhost:8695/api' prove -v t/02-common.t
