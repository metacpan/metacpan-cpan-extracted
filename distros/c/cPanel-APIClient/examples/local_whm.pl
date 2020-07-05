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

my $whm = cPanel::APIClient->create(
    service => 'whm',
    transport => ['CLISync'],
);

my $resp_whm = $whm->call_api1('list_hooks');

print YAML::Syck::Dump $resp_whm->get_data();
