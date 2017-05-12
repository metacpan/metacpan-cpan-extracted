use strict;
use warnings;

use Test::More;
use Try::Tiny qw(try catch);

my $res = try {require WWW::Shorten::Metamark; '' } catch { "inactive service $_" };
like($res, qr/inactive/, "::Metamark is inactive");

done_testing();
