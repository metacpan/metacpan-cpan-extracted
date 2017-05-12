use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;
use File::Temp qw(tempdir);
use File::Slurp;

BEGIN { use_ok('Test::TempDatabase'); }

my $td = tempdir("/tmp/tt_setuid_XXXXXX", CLEANUP => 1);

sub do_become {
	my %env = @_;
	my $pid = fork;
	if ($pid) {
		waitpid($pid, 0);
		return;
	}
	while (my ($n, $v) = each %env) {
		$ENV{ $n } = $v;
	}
	open(STDERR, ">$td/stderr");
	Test::TempDatabase->become_postgres_user;
	print STDERR "# $ENV{HOME}\n";
	exit;
}

if ($<) {
	is(Test::TempDatabase->find_postgres_user, $<);
} else {
	isnt(Test::TempDatabase->find_postgres_user, $<);
}

SKIP: {
skip "Should be root to run this test", 4 if $<;
do_become(TEST_TEMP_DB_USER => "nobody");
like(read_file("$td/stderr"), qr/setting nobody/);
like(read_file("$td/stderr"), qr/nonexistent/);
do_become(TEST_TEMP_DB_USER => "", SUDO_USER => "root");
like(read_file("$td/stderr"), qr/setting root/);
do_become(TEST_TEMP_DB_USER => "", SUDO_USER => "");
like(read_file("$td/stderr"), qr/setting postgres/);
};
