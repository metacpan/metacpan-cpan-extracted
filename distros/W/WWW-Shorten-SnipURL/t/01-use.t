#!perl

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('WWW::Shorten::SnipURL') or BAIL_OUT("Can't use module"); }

can_ok('WWW::Shorten::SnipURL', qw(makeashorterlink makealongerlink));
can_ok('main', qw(makeashorterlink makealongerlink));

done_testing();
