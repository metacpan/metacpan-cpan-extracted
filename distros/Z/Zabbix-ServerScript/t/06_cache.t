use strict;
use warnings;

use Test::More tests => 4;
use File::Temp;
use File::Basename;
use Data::Dumper;
use Storable;

use Zabbix::ServerScript;

Zabbix::ServerScript::init({ log_filename => q(/tmp/zabbix_server_script_test.log) });

subtest q(Return false) => sub {
	my $filename;
	my $fh;
	my $cache;
	my $dirname;

	$filename = mktemp(q(/tmp/test_cache.XXXXXX));
	$cache = Zabbix::ServerScript::retrieve_cache($filename);
	is($cache, undef, qq(Return false if cache file does not exist));

	($fh, $filename) = File::Temp::tempfile(qq(/tmp/test_cache.XXXXXX), UNLINK => 1);
	print $fh q(TEST);
	$cache = Zabbix::ServerScript::retrieve_cache($filename);
	is($cache, undef, qq(Return false if cache file contains invalid data));

	# trying to store cache to non-existent directory
	$dirname = File::Temp::tempdir(q(test_dir.XXXXXX));
	$filename = mktemp(qq($dirname/test_cache.XXXXXX));
	rmdir($dirname);
	my $res = Zabbix::ServerScript::store_cache($cache, $filename);
	is($res, undef, qq(Return false if cannot store cache));
};

subtest q(retrieve proper structure from cache) => sub {
	my $filename = mktemp(q(/tmp/test_cache.XXXXXX));
	my $hash = { test => 1 };
	store $hash, $filename;
	my $cache = Zabbix::ServerScript::retrieve_cache($filename);
	is_deeply($cache, $hash, q(Retrieve proper structure from cache));
	unlink($filename);
};

subtest q(store proper structure to cache) => sub {
	my $filename = mktemp(q(/tmp/test_cache.XXXXXX));
	my $cache = { test => 1 };
	Zabbix::ServerScript::store_cache($cache, $filename);
	my $hash = retrieve $filename;
	is_deeply($cache, $hash, q(Retrieve proper structure to cache));
	unlink($filename);
};

subtest q(store/retrieve to default filename) => sub {
	$ENV{BASENAME} = basename(mktemp(qq($config->{global}->{cache_dir}/test_cache.XXXXXX)));
	my $hash = { test => 2 };
	ok(Zabbix::ServerScript::store_cache($hash), q(Store cache to default filename));
	my $cache = Zabbix::ServerScript::retrieve_cache();
	is_deeply($cache, $hash, q(Retrieve proper structure from default filename));
};

unlink(q(/tmp/zabbix_server_script_test.log));
done_testing;
