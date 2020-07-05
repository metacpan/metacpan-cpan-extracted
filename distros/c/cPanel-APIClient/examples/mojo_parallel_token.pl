#!/usr/bin/env perl

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use YAML::Syck;

use cPanel::APIClient;

my $CP_USERNAME = shift @ARGV;
die "Provide username!" if !$CP_USERNAME;

my $CP_TOKEN = shift @ARGV;
die "Provide API token!" if !$CP_TOKEN;

my $remote_cp = cPanel::APIClient->create(
    service => 'cpanel',

    transport => [
        'MojoUserAgent',
        hostname         => 'localhost',
        tls_verification => 'off',
    ],

    credentials => {
        username  => $CP_USERNAME,
        api_token => $CP_TOKEN,
    },
);

my $req1 = $remote_cp->call_uapi( 'Email', 'list_pops' );

my $p1 = $req1->promise()->then(
    sub {
        my ($got) = @_;

        print STDERR YAML::Syck::Dump $got;
    },
    sub { warn "failed: @_" },
);

my $req2 = $remote_cp->call_uapi( 'Email', 'list_forwarders' );

my $p2 = $req2->promise()->then(
    sub {
        my ($got) = @_;

        print STDERR YAML::Syck::Dump $got;
    },
    sub { warn "failed: @_" },
);

Mojo::Promise->all( $p1, $p2 )->wait();
