#!perl

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('WWW::Shorten', 'Yourls') or BAIL_OUT("Can't use module"); }

can_ok('main', qw(makealongerlink makeashorterlink));
can_ok('WWW::Shorten::Yourls', qw(server signature));
can_ok('WWW::Shorten::Yourls', qw(password username));

done_testing();
