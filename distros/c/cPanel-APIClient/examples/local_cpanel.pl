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

my $cpanel = cPanel::APIClient->create(
    service => 'cpanel',

    transport => ['CLISync'],

    credentials => { username => $CP_USERNAME },
);

my $result = $cpanel->call_uapi( 'Email', 'list_pops' );

print YAML::Syck::Dump $result->get_data();
