#!/usr/bin/env perl

# $Id$

use 5.10.0;
use warnings;
use integer;

BEGIN {
    our ($VERSION) = '$Revision$' =~ m{\$Revision: \s+ (\S+)}x; ## no critic
}

use Test::More tests => 1;
use Text::Bidi qw(fribidi_version unicode_version);

diag("libfribidi version: " . fribidi_version);
diag("Unicode version: " . unicode_version);
pass;

