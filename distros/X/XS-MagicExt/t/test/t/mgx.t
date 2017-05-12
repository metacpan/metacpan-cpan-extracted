#!perl -w

use strict;
use warnings;

use Test::More tests => 2;

use MGX;

like $INC{'XS/MagicExt.pm'}, qr{/blib/}, 'use XS::MagicExt installed in blib';
is MGX::do_test(), 22;
