use strict;
use warnings;

use Test::More tests => 5;

use_ok('WWW::Live::Auth');
my $auth = WWW::Live::Auth->new();
can_ok($auth, 'consent_url');
can_ok($auth, 'refresh_url');
can_ok($auth, 'receive_consent');
can_ok($auth, 'refresh_consent');
