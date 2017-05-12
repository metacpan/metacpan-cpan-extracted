use strict;
use warnings;

use Test::More;
use Try::Tiny qw(try catch);

my $res = try {require WWW::Shorten::LinkToolbot; '' } catch { "inactive service $_" };
like($res, qr/inactive/, "::LinkToolbot is inactive");

done_testing();
