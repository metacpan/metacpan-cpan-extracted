#!/usr/bin/env perl -w

# $Id: t1.t 22 2010-09-23 23:04:07Z stro $

use strict;
use warnings;

use Test;
BEGIN { plan tests => 1 }

use Win32::Uptime;

my $x = Win32::Uptime::uptime();

ok(1);

exit;
