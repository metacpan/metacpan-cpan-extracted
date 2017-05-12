#!perl -T

use Test::More tests => 7;
use Test::Fatal;

use WWW::USF::WebAuth;

# Holds the WebAuth object
my $webauth;

# Make sure the constructor takes the NetID
ok(!exception { $webauth = WWW::USF::WebAuth->new(netid => 'anything'); },
	'Constructor takes netid attribute');

# Check has_*
ok $webauth->has_netid   , 'has_netid works';
ok $webauth->has_username, 'has_username works';

is $webauth->netid   , 'anything', 'NetID set correctly';
is $webauth->username, 'anything', 'Username is the NetID';

# Check clear_netid
$webauth->clear_netid;

ok !$webauth->has_netid   , 'No longer has NetID';
ok !$webauth->has_username, 'No longer has username';

exit 0;
