#!/usr/bin/perl -w
# Copyright (c) 2019, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test::More tests => 3;

use_ok("XString");

can_ok "XString", 'cstring';
can_ok "XString", 'perlstring';