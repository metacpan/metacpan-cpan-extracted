use strict;
use warnings;
use Test::More;

BEGIN { use_ok('WWW::Shorten::0rz') or BAIL_OUT("Can't use module"); }

can_ok('WWW::Shorten::0rz', qw(makeashorterlink makealongerlink));
can_ok('main', qw(makeashorterlink makealongerlink));

done_testing();
