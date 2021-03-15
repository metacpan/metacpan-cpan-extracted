use strict;
use warnings;

use Test::More;
use Try::Tiny qw(try catch);

my $res = try {require WWW::Shorten::Qurl; '' } catch { "inactive service $_" };
like($res, qr/inactive/, "::Qurl is inactive");

done_testing();
