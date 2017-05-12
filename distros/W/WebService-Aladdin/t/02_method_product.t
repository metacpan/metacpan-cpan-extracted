use strict;
use warnings;
use Test::More skip_all => 'default api key is blocked';

use WebService::Aladdin;

my $aladdin = WebService::Aladdin->new();
ok $aladdin;

my $data = $aladdin->product('9238043167');
ok $data;
