#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 1;

BEGIN {
    use_ok('Wx::WidgetMaker');
}
