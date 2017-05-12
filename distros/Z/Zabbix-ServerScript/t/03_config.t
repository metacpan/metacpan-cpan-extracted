use strict;
use warnings;

use Test::More tests => 3;
use Test::Fatal;
use Test::Output;
use File::Temp;
use Data::Dumper;
use Storable;
use Log::Log4perl::Level;

use Zabbix::ServerScript;

subtest q(throws exception if environment variables are not set) => sub {
	ok exception { Zabbix::ServerScript::_set_config() };
};

$ENV{BASENAME} = q(zabbix_server_script_test);
$ENV{ID} = q(zabbix_server_script_test);
Zabbix::ServerScript::_set_logger({
	console => 1,
	debug => 1,
});

my $etalon_hashref = {
	test => {
		a => 1,
		b => [
			2,
			3,
		],
	},
	global => $Zabbix::ServerScript::Config,
};

my $proper_yaml = <<'END_PROPER_YAML';
test:
  a: 1
  b:
    - 2
    - 3
END_PROPER_YAML

my $incorrect_yaml = <<'END_INCORRECT_YAML';
test:
	a: 1
- b: 2
END_INCORRECT_YAML

subtest q(Set default config name) => sub {
	stderr_like(sub {Zabbix::ServerScript::_set_config();}, qr($Zabbix::ServerScript::Config->{config_dir}/$ENV{BASENAME}.yaml), qq(Try to use default config name (BASENAME.yaml)));
};

sub create_config_file {
	my ($config_text) = @_;
	my ($config_fh, $config_filename) = File::Temp::tempfile(qq(/tmp/config_XXXXXX));
	print $config_fh $config_text;
	close($config_fh);
	return $config_filename;
}

subtest q(Return proper structure from config file) => sub {
	$logger->level($OFF);
	my $config_filename = create_config_file($proper_yaml);
	Zabbix::ServerScript::_set_config($config_filename);
	is_deeply($config, $etalon_hashref, q(Retrieve proper structure from YAML config file));
	unlink($config_filename);

	$config = undef;
	Zabbix::ServerScript::_set_config();
	is_deeply($config, { global => $Zabbix::ServerScript::Config }, q(Do not use local config));

	$config = undef;
	$config_filename = create_config_file($incorrect_yaml);
	ok exception { Zabbix::ServerScript::_set_config($config_filename) };
	unlink($config_filename);
};

done_testing;
