use lib '../lib';
use strict;
use Test::More;

use_ok 'WWW::Pusher';

my $pusher = WWW::Pusher->new(auth_key => 'made-up', secret => 'made-up', app_id => 'made-up');

isa_ok $pusher, 'WWW::Pusher';

done_testing();
