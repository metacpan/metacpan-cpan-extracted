use strict;
use warnings;
use WebService::APIKeys::AutoChanger;
use Test::More tests => 5; 

my $changer = WebService::APIKeys::AutoChanger->new;

can_ok($changer, 'new');
can_ok($changer, 'set');
can_ok($changer, 'set_api_keys');
can_ok($changer, 'set_throttle');
can_ok($changer, 'get_available');