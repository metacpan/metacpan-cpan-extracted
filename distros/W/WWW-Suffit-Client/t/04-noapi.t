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
use WWW::Suffit::Client::NoAPI;
use WWW::Suffit::Util qw/json_load json_save/;
use Mojo::JSON::Pointer;

use constant STATFILE => 'stat.tmp';

plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";

# Load stat data
plan skip_all => "No API server found" unless -e STATFILE;
my $status_data = json_load(STATFILE);
plan skip_all => "No API server configured" unless $status_data && ref $status_data eq 'HASH';
my $st = Mojo::JSON::Pointer->new($status_data);

# Check authorized status
plan skip_all => "Authorization failed" unless $st->get('/is_authorized');

# Base URL
ok($st->get('/base_url'), sprintf("Base URL: %s", $st->get('/base_url') // '???'));

# Create the instance
my $instance_args = $st->get('/instance_args') || {};
my $client = WWW::Suffit::Client::NoAPI->new( %$instance_args );
ok($client->status, "Can't initialize the client") or diag $client->error;
#note explain $st->get('/instance_args');

# Set token and public_key to client
ok($client->token($st->get('/access_token')), "Set token to client");
#ok($client->public_key($st->get('/public_key')), 'Set public_key to client');

# Upload file to server
{
    my $status = $client->upload("README.md" => "/foo/test/test.txt");
    ok($status, "Upload file /foo/test/test.txt") or diag($client->error);
    note $client->trace unless $status;
}

# Download file from server
{
    my $status = $client->download("/foo/test/test.txt" => "test.txt.tmp");
    ok($status, "Download file /foo/test/test.txt") or diag($client->error);
    note $client->trace unless $status;
}

# Get file list (manifest)
{
    my $status = $client->manifest;
    ok($status, "Get manifest") or diag($client->error);
    note $client->trace unless $status;
    #note explain $client->res->json;
}

# Remove file from server
{
    my $status = $client->remove("/foo/test/test.txt");
    ok($status, "Remove file /foo/test/test.txt") or diag($client->error);
    note $client->trace unless $status;
}

done_testing;

__END__

prove -v t/04-noapi.t
