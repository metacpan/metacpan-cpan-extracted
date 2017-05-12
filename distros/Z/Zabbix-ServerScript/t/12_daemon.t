use strict;
use warnings;
use Carp;

use Test::More tests => 1;
use Test::Fatal;
use Test::Output;
use File::Temp;
use Data::Dumper;
use Capture::Tiny ':all';

use Zabbix::ServerScript;

sub run_daemon {
	my ($filename) = @_;
	Zabbix::ServerScript::_set_daemon({ daemon => 1 });
	my $res;
	my $tries = 10;
	while ($tries-- and ! $res){
		$res = 1 if -f $filename;
		sleep 1;
	}
	unlink $filename or croak qq(Cannot unline $filename: $!);
	exit;
}

subtest q(check _set_daemon) => sub {
	my $filename = File::Temp::mktemp(q(/tmp/run_daemon.XXXXXX));
	
	my $pid = fork or run_daemon($filename);

	# waiting until child exits
	while (wait() != -1){}

	open my $FH, q(>), $filename or croak qq(Cannot open $filename: $!);
	print $FH q(SUCCESS);
	close $FH or croak qq(Cannot close $filename: $!);
	
	my $res;
	my $tries = 10;
	while ($tries-- && ! $res){
		$res = 1 if ! -f $filename;
		sleep 1;
	}
	ok($res, q(_set_daemon() really _set_daemons process));
};

done_testing;
