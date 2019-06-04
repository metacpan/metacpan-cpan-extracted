#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Time::Local();
use Time::Zone::Olson();
use POSIX();
use Config;
use English qw( -no_match_vars );
use Time::Local();
use Taint::Util();

$ENV{PATH} = '/bin:/usr/bin:/usr/sbin:/sbin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

TAINTED_TZ: {
	local $ENV{TZ} = 'Australia/Melbourne';
	Taint::Util::taint($ENV{TZ});
	my $timezone = Time::Zone::Olson->new();
	ok(!Taint::Util::tainted($timezone->timezone()), "Local timezone has been untainted as " . $timezone->timezone() );
	ok(Taint::Util::tainted($ENV{TZ}), "TZ environment variable is still tainted");
}

TAINTED_TIMEZONE: {
	my $tz = 'Australia/Brisbane';
	Taint::Util::taint($tz);
	my $timezone = Time::Zone::Olson->new( timezone => $tz );
	ok(!Taint::Util::tainted($timezone->timezone()), "Local timezone has been untainted as " . $timezone->timezone() );
	ok(Taint::Util::tainted($tz), "timezone parameter is still tainted");
}

TAINTED_DEFAULT: {
	delete $ENV{TZ};
	delete $ENV{TZDIR};
	my $timezone = Time::Zone::Olson->new();
	if (defined $timezone->timezone()) {
		ok(!Taint::Util::tainted($timezone->timezone()), "Default timezone has been untainted as " . $timezone->timezone() );
	}
}

Test::More::done_testing();
