use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 15;
BEGIN { use_ok('WebService::Whistle::Pet::Tracker::API') };

my $ws = WebService::Whistle::Pet::Tracker::API->new(email=>'my_email', password=>'my_password');
isa_ok($ws, 'WebService::Whistle::Pet::Tracker::API');
isa_ok($ws->ua, 'HTTP::Tiny');
diag(Dumper($ws));

can_ok($ws, 'new');
can_ok($ws, 'email');
can_ok($ws, 'password');
can_ok($ws, 'ua');
can_ok($ws, 'api');
can_ok($ws, 'login');
can_ok($ws, 'auth_token');
can_ok($ws, 'pets');

is($ws->email, 'my_email', 'email');
is($ws->email('set_email'), 'set_email', 'email');
is($ws->password, 'my_password', 'password');
is($ws->password('set_password'), 'set_password', 'password');
