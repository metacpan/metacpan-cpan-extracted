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
use WWW::Suffit::Client::V1;
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
my $client = WWW::Suffit::Client::V1->new( %$instance_args );
ok($client->status, "Can't initialize the client") or diag $client->error;
#note explain $st->get('/instance_args');

# Set token and public_key to client
ok($client->token($st->get('/access_token')), "Set token to client");
ok($client->public_key($st->get('/public_key')), 'Set public_key to client');

# Authenticate bob user
ok($client->authn("bob", "bob"), "Authenticate bob user") or diag($client->error);
#diag explain $client->res->json;

# Authorization bob user
ok($client->authz(GET => $st->get('/base_url'), {verbose => 1, address => "1.2.3.4", username => "bob"}), "Authorization bob user")
    or diag($client->error);
#diag explain $client->res->json;

done_testing;

__END__

prove -v t/03-v1.t
