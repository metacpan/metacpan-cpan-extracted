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

use Unicode::ICU;

like( Unicode::ICU::ICU_VERSION, qr<[0-9]>, 'ICU_VERSION' );

done_testing;
