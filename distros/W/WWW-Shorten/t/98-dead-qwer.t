use strict;
use warnings;

use Test::More;
use Try::Tiny qw(try catch);

my $res = try {require WWW::Shorten::Qwer; '' } catch { "inactive service $_" };
like($res, qr/inactive/, "::Qwer is inactive");

done_testing();
