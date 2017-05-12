use strict;

use Test::More tests => 6;
use WWW::Jawbone::Up::Mock;

my $up = WWW::Jawbone::Up::Mock->connect('alan@eatabrick.org', 's3kr3t');

my $user = $up->user;

is($user->first,      'Alan',        'first name');
is($user->last,       'Berndt',      'last name');
is($user->name,       'Alan Berndt', 'full name');
is($user->short_name, 'Alan',        'short name');

ok($user->friend, 'friend');

like($user->image, qr{^http.*user/image}, 'image');
