use strict;
use warnings;

use Test::More tests => 3;
use Test::Fatal;
use Test::Output;
use File::Temp;
use Data::Dumper;
use Storable;

use Zabbix::ServerScript;

$ENV{BASENAME} = q(zabbix_server_script_test);
$ENV{ID} = q(zabbix_server_script_test);
Zabbix::ServerScript::_set_logger({ log_filename => q(/tmp/zabbix_server_script_test.log) });

sub set_file_logger {
	my ($opt) = @_;
	$opt = {} unless defined $opt;
	my ($log_fh, $log_filename) = File::Temp::tempfile(q(/tmp/test_log.XXXXXX), UNLINK => 1);
	$opt->{log_filename} = $log_filename;
	Zabbix::ServerScript::_set_logger($opt);
	return $log_fh;
}

subtest q(Check permissions) => sub {
	ok(-d $Zabbix::ServerScript::Config->{pid_dir}, qq(Pid directory '$Zabbix::ServerScript::Config->{pid_dir}' exists));
	ok(-w $Zabbix::ServerScript::Config->{pid_dir}, qq(Pid directory '$Zabbix::ServerScript::Config->{pid_dir}' is writable for current user));
};

subtest q(Return pid) => sub {
	my $pid;
	my $etalon_pid = {
		dir => $Zabbix::ServerScript::Config->{pid_dir},
		name => $ENV{BASENAME},
	};

	$pid = Zabbix::ServerScript::_get_pid();
	is_deeply($pid, $etalon_pid, q(Create default pid structure));

	my $id = q(test_id);
	$etalon_pid->{name} .= qq(_$id);
	$pid = Zabbix::ServerScript::_get_pid($id);
	is_deeply($pid, $etalon_pid, q(Create pid with ID defined));
};

sub read_file_contents {
	my ($fh) = @_;
	return do { local $/; <$fh> };
}

subtest q(Ensure process uniqueness) => sub {
	my $log_fh = set_file_logger();
	my $i = 0;
	my $child1_pid = fork and $i++;
	my $child2_pid = fork if $child1_pid;
	if (not ($child1_pid and $child2_pid)){
		Zabbix::ServerScript::_set_unique(1);
		$logger->fatal(qq(Result message: $i));
		sleep 5;
		exit;
	}
	while (wait() != -1) {}
	my $content = read_file_contents($log_fh);
	like($content, qr(already (?:running|locked)), q(Second fork found out that the first one was running));
	my @matches = $content =~ m/Result message: [01]/g;
	is(scalar @matches, 1, qq(Only one fork has done it's job));
};

unlink(q(/tmp/zabbix_server_script_test.log));
done_testing;
