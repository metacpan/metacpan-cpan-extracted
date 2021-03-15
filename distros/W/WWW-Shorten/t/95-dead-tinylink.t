use strict;
use warnings;

use Test::More;
use Try::Tiny qw(try catch);

my $res = try {require WWW::Shorten::Tinylink; '' } catch { "inactive service $_" };
like($res, qr/inactive/, "::Tinylink is inactive");

done_testing();
