use strict;
use warnings;
use Test::More;

use_ok 'WWW::Shorten::iiipe';
my $u = makeashorterlink('www.google.com');
ok $u;
like $u, qr{iii\.pe/[a-zA-Z0-9]+};

done_testing;
