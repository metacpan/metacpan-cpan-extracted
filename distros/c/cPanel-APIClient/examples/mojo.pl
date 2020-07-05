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

my $CP_PASSWORD = shift @ARGV;
die "Provide password!" if !$CP_PASSWORD;

my $remote_cp = cPanel::APIClient->create(
    service => 'cpanel',

    transport => [
        'MojoUserAgent',
        hostname         => 'localhost',
        tls_verification => 'off',
    ],

    credentials => {
        username => $CP_USERNAME,
        password => $CP_PASSWORD,
    },
);

my $req2 = $remote_cp->call_uapi( 'Email', 'list_forwarders' );

my $p2 = $req2->promise()->then(
    sub {
        my ($got) = @_;

        print STDERR YAML::Syck::Dump $got;
    },
    sub { warn "failed: @_" },
);

$p2->wait();
