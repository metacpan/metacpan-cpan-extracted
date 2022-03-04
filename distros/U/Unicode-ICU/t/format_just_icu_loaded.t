#!/usr/bin/env perl

# Copyright 2022 cPanel, LLC. (copyright@cpanel.net)
# Author: Felipe Gasper
#
# Copyright (c) 2022, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Explain;

use Unicode::ICU;

my $can_take_named = Unicode::ICU::MessageFormat::CAN_TAKE_NAMED_ARGUMENTS;

plan skip_all => 'Need named args; this ICU is too old.' if !$can_take_named;

ok(
    Unicode::ICU::MessageFormat->new()->format("{mynum, spellout}", {mynum => 1}),
    'MessageFormat named args are usable even if only Unicode::ICU is loaded.',
);

done_testing;
