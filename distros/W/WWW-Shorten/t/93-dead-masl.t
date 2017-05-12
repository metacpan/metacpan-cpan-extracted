use strict;
use warnings;

use Test::More;
use Try::Tiny qw(try catch);

my $res = try {require WWW::Shorten::MakeAShorterLink; '' } catch { "inactive service $_" };
like($res, qr/inactive/, "::MakeAShorterLink is inactive");

done_testing();
