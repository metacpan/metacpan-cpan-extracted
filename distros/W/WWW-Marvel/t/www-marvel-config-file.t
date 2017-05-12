# -*- perl -*-

use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Spec::Functions 'catfile';
use Test::Exception;
use Test::More tests => 5;

BEGIN { use_ok( 'WWW::Marvel::Config::File' ); }

my $path = abs_path catfile(dirname(__FILE__), 'www-marvel-config-file.conf');

{
	my $cfg = WWW::Marvel::Config::File->new($path);
	is($cfg->get_public_key, '1234', 'get public key');
	is($cfg->get_private_key, 'abcd', 'get private key');
	is($cfg->get_config_filename, $path, 'get config filename');
}

{
	dies_ok { WWW::Marvel::Config::File->new("fake_path") } "Unvalid config file";
}
