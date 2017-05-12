use strict;
use warnings;

use Test::More;
use Try::Tiny qw(try catch);

my $res = try {require WWW::Shorten::Linkz; '' } catch { "inactive service $_" };
like($res, qr/inactive/, "::Linkz is inactive");

done_testing();
