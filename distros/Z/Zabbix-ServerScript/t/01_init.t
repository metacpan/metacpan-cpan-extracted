use strict;
use warnings;

use Test::More tests => 3;
use Test::Fatal;
use Test::Output;
use File::Temp;
use Data::Dumper;
use Capture::Tiny ':all';

use Zabbix::ServerScript;

subtest q(check _get_options) => sub {
	my $opt = 1;

	ok( exception { Zabbix::ServerScript::_get_options($opt) }, q(_get_options throws an exception if $opt is defined and not a hash reference));

	undef $opt;
	$opt = Zabbix::ServerScript::_get_options($opt);
	my $default_opt = {
		daemon => 0,
		verbose => 0,
		debug => 0,
		unique => 0,
		console => 0,
	};
	is_deeply($opt, $default_opt, q(_get_options sets default options when no arguments are given));
	
	undef $opt;
	my $etalon_opt = { %$default_opt };
	$etalon_opt->{daemon} = 1;
	push @ARGV, q(--daemon);
	$opt = Zabbix::ServerScript::_get_options($opt);
	is_deeply($opt, $etalon_opt, q(_get_options sets $opt->{daemon} when --daemon option is passed));

	undef $opt;
	$etalon_opt = { %$default_opt };
	$etalon_opt->{debug} = 1;
	push @ARGV, q(--debug);
	$opt = Zabbix::ServerScript::_get_options($opt);
	is_deeply($opt, $etalon_opt, q(_get_options sets $opt->{debug} when --debug option is passed));

	undef $opt;
	$etalon_opt = { %$default_opt };
	$etalon_opt->{console} = 1;
	push @ARGV, q(--console);
	$opt = Zabbix::ServerScript::_get_options($opt);
	is_deeply($opt, $etalon_opt, q(_get_options sets $opt->{console} when --console option is passed));

	undef $opt;
	$etalon_opt = { %$default_opt };
	$etalon_opt->{verbose} = 1;
	push @ARGV, q(--verbose);
	$opt = Zabbix::ServerScript::_get_options($opt);
	is_deeply($opt, $etalon_opt, q(_get_options sets $opt->{verbose} when --verbose option is passed));

	undef $opt;
	$etalon_opt->{verbose} = 3;
	push @ARGV, q(-vvv);
	$opt = Zabbix::ServerScript::_get_options($opt);
	is_deeply($opt, $etalon_opt, q(_get_options sets $opt->{verbose} according to count of bundled -v given));

	push @ARGV, q(--non-valid-option);
	ok( exception { capture_stderr { $opt = Zabbix::ServerScript::_get_options($opt) } }, q(_get_options throws an exception if non-valid option is given));

	undef $opt;
	$etalon_opt = { %$default_opt };
	my @opt_specs = qw(
		daemon
		console
	);
	$opt = Zabbix::ServerScript::_get_options($opt, @opt_specs);
	is_deeply($opt, $etalon_opt, q(_get_options doesn't fail if duplicate opt_specs are given));

	$opt = {
		id => q(test),
	};
	$etalon_opt = { %$default_opt };
	$etalon_opt->{id} = q(test);
	Zabbix::ServerScript::_get_options($opt);
	is_deeply($opt, $etalon_opt, q(_get_options preserves options provided as its arguments));

	push @ARGV, q(--test-option=test);
	$opt = {};
	$etalon_opt = { q(test-option) => q(test), %$default_opt };
	@opt_specs = qw(
		test-option=s
	);
	Zabbix::ServerScript::_get_options($opt, @opt_specs);
	is_deeply($opt, $etalon_opt, q(_get_options puts specified options to $opt));
};

subtest q(check _set_basename) => sub {
	Zabbix::ServerScript::_set_basename(q(),q(test.pl));
	is($ENV{BASENAME}, q(test), q(Set environment variable BASENAME));
};

subtest q(check _set_id) => sub {
	Zabbix::ServerScript::_set_id(q());
	is($ENV{ID}, q(), q(Empty environment variable ID));
	Zabbix::ServerScript::_set_id();
	is($ENV{ID}, q(test), q(Default environment variable ID is the same as BASENAME));
	Zabbix::ServerScript::_set_id(q(lala));
	is($ENV{ID}, q(lala), q(Custom environment variable ID));
};

done_testing;
