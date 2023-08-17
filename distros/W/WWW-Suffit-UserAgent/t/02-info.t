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
use WWW::Suffit::UserAgent;

use constant USERNAME => 'test';
use constant PASSWORD => 'test';
use constant BASE_URLS => [
        'https://owl.localhost:8695/api',
        'http://localhost/api',
        'https://localhost/api',
    ];
my @base_urls = @{(BASE_URLS)};
unshift @base_urls, $ENV{SUFFIT_SERVER_URL}
    if $ENV{SUFFIT_SERVER_URL};
#note explain \@base_urls;

plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";

# Create the instance
my ($client, $base_url);
for (@base_urls) {
    $base_url = $_;
    $client = WWW::Suffit::UserAgent->new(
        url                 => $base_url,
        insecure            => 1, # IO::Socket::SSL::set_defaults(SSL_verify_mode => 0); # Skip verify for test only!
        max_redirects       => 2,
        connect_timeout     => 30,
        inactivity_timeout  => 30,
        request_timeout     => 30,
        #token               => "",
        #proxy               => "",
        #username            => "test", # For HTTP Basic Authorization
        #password            => "test", # For HTTP Basic Authorization
        #ask_credentials     => 1,
        #auth_scheme         => 'Basic',
        #proxy => 'http://47.88.62.42:80', #'socks://socks:socks@192.168.201.129:1080',
    );
    last if $client->check; # Check is ok
    note("Skipped ", $base_url, ": ", $client->error || 'unknown');
}

plan skip_all => "Can't initialize the client. No working server found (by URL)" unless $client->status;
#plan skip_all => "Authorization failed" unless $client->res->headers->header('X-Authorized');

# Ok (check)
note $client->tx_string;
ok($client->status, sprintf("Base URL: %s", $base_url));
#note $client->trace;

# HTTP Basic authorization
#$client->{ask_credentials} = 1;
#$client->{auth_scheme} = 'Basic';
#my $status = $client->request(GET => $client->str2url('test'));
#ok($status, "HTTP Basic authorization") or diag $client->error;
#note $client->trace;

## Proxy
#my $status = $client
#    #->proxy('http://47.88.62.42:80')
#    ->proxy('socks://socks:socks@192.168.201.129:1080')
#    ->request(GET => $client->str2url('http://ifconfig.io/all.json'));
#ok($status, "Proxy") or diag $client->error;
#note $client->trace;
#note explain $client->res->json;

done_testing;

__END__

SUFFIT_SERVER_URL='https://owl.localhost:8695/api' prove -lv t/02-info.t
