use strict;
use warnings;
use Try::Tiny qw(try catch);
use Test::More;

BEGIN { use_ok('WWW::Shorten','TinyURL', ':short') or BAIL_OUT("Can't use module"); }

can_ok('main', qw(short_link long_link));

done_testing();
