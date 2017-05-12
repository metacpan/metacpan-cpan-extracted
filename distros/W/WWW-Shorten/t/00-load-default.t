use strict;
use warnings;
use Try::Tiny qw(try catch);
use Test::More;

BEGIN { use_ok('WWW::Shorten','TinyURL', ':default') or BAIL_OUT("Can't use module"); }

can_ok('main', qw(makeashorterlink makealongerlink));

done_testing();
