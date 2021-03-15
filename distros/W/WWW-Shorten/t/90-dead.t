use strict;
use warnings;

use Test::More;
use Try::Tiny qw(try catch);

my $res = try {require WWW::Shorten::_dead; '' } catch { "inactive service $_" };
like($res, qr/inactive/, "::_dead is inactive");

done_testing();
