# -*- perl -*-

use Test::More tests => 5;
use Test::Exception;

BEGIN { use_ok( 'WWW::Marvel::Config' ); }

{
	my $cfg = WWW::Marvel::Config->new({ public_key => 1234, private_key => 'abcd' });
	is($cfg->get_public_key, '1234', 'get public key');
	is($cfg->get_private_key, 'abcd', 'get private key');
}

{
	my $cfg = WWW::Marvel::Config->new();
	dies_ok { $cfg->get_public_key  } "No 'public_key' key set";
	dies_ok { $cfg->get_private_key } "No 'private_key' key set";
}
