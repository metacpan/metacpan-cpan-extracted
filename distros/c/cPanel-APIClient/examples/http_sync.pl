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
        'HTTPSync',
        hostname         => 'localhost',
        tls_verification => 'off',
    ],

    credentials => {
        username => $CP_USERNAME,
        password => $CP_PASSWORD,
    },
);

my $got = $remote_cp->call_uapi( 'Email', 'list_forwarders' );

print STDERR YAML::Syck::Dump $got->get_data();
