use strict;
use warnings;

use Test::More;
use Try::Tiny qw(try catch);

my $res = try {require WWW::Shorten::TinyClick; '' } catch { "inactive service $_" };
like($res, qr/inactive/, "::TinyClick is inactive");

done_testing();
