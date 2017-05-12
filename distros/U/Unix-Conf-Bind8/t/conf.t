# parse the named.conf file provided with bind-8.2.3 source
# to test the parser thouroughly. It should parse without 
# complaints and write it back properly.

use strict;
use warnings;
use Test;

BEGIN { plan tests => 29 };

use Unix::Conf;
ok (1);
use Unix::Conf::Bind8;
ok (1);

# get max debug messages
Unix::Conf->debuglevel (2);


# READ in a comprehensive configuration file and test the parsing.
# copy the orignal conf file at the start of every test
`cp t/named.conf.org t/named.conf`;
`cp t/include.conf.org t/include.conf`;
my ($conf, $obj, $ret, @directives, @warnings);

$conf = Unix::Conf::Bind8->new_conf (
	FILE	=> 't/named.conf',
	SECURE_OPEN	=> 0,
);

ok ($conf->isa ('Unix::Conf::Bind8::Conf'));
# die if we fail as all tests below depend on success of this test.
$conf->die ("\nUnix::Conf::Bind8->new_conf () failed") unless ($conf);

ok (@warnings = $conf->parse_errors (), 0);
$_->warn () for (@warnings);

ok (@directives = $conf->directives (), 28);

# mark all directives as dirty, in the hope we blow up somewhere.
#$_->dirty (1) for (@directives);

# read again to see if we get same number of directives.
# if so rendering should be ok.
undef (@directives);
undef (@warnings);
($obj, $ret, $_) = (undef) x 3;
$conf = undef;

$conf = Unix::Conf::Bind8->new_conf (
	FILE	=> 't/named.conf',
	SECURE_OPEN	=> 0,
);
ok ($conf->isa ('Unix::Conf::Bind8::Conf'));
$conf->die ("\nUnix::Conf::Bind8->new_conf () failed") unless ($conf);
ok (@directives = $conf->directives (), 28);
# now delete some zones say 2 and check back the number of zones.
# this should validate delete_* for all zone type directives.
ok (@directives = $conf->zones (), 5);

$ret = $conf->delete_zone ('stub.demo.zone');
ok ($ret);
$ret->die ("couldn't delete zone `stub.demo.zone'")	unless ($ret);

$ret = $conf->delete_zone ('.');
ok ($ret);
$ret->die ("couldn't delete zone `.'")	unless ($ret);

# try getting zone now. it should fail.
# this is without writing it out and reading it back.
$ret = $conf->get_zone ('stub.demo.zone');
ok ($ret, qr/^_get_zone: zone `stub.demo.zone' not defined/);

ok (@directives = $conf->zones (), 3);

# now delete options, write it out, read it back and then try 
# getting it. also try getting back zone `stub.demo.zone'
$ret = $conf->delete_options ();
ok ($ret);
$ret->die ("couldn't delete options")	unless ($ret);

# try getting options now. it should fail.
# this is without writing it out and reading it back.
$ret = $conf->get_options ();
ok ($ret, qr/^_get_options: `options' not defined/);

undef (@directives);
undef (@warnings);
($obj, $ret, $_) = (undef) x 3;
$conf = undef;

$conf = Unix::Conf::Bind8->new_conf (
	FILE	=> 't/named.conf',
	SECURE_OPEN	=> 0,
);
ok ($conf->isa ('Unix::Conf::Bind8::Conf'));
$conf->die ("\nUnix::Conf::Bind8->new_conf () failed") unless ($conf);
ok (@directives = $conf->directives (), 25);

# make sure the zones and options are really gone from the file.
$ret = $conf->get_zone ('stub.demo.zone');
ok ($ret, qr/^_get_zone: zone `stub.demo.zone' not defined/);
$ret = $conf->get_options ();
ok ($ret, qr/^_get_options: `options' not defined/);

# test handling of a conf object when directives are parsed
# from the include file.
ok ($ret = $conf->get_zone ('include.com'));
ok ($ret->type (), 'master');
ok ($ret = $conf->get_include ('t/include.conf'));
$ret->die ("couldn't get include") unless ($ret);
ok (($ret = $ret->conf ())->isa ("Unix::Conf::Bind8::Conf"));
ok ($ret->new_zone (
	NAME		=> 'master.demo.zone',
	TYPE		=> 'master',
	FILE		=> 'db.demo.zone',
	CLASS		=> 'IN',
), qr/^_add_zone: zone `master.demo.zone' already defined/);
ok ($ret->new_zone (
	NAME		=> 'extremix.com',
	TYPE		=> 'master',
	FILE		=> 'db.extremix.com',
	CLASS		=> 'IN',
));

undef (@directives);
undef (@warnings);
($obj, $ret, $_) = (undef) x 3;
$conf = undef;

$conf = Unix::Conf::Bind8->new_conf (
	FILE	=> 't/named.conf',
	SECURE_OPEN	=> 0,
);
ok ($conf->isa ('Unix::Conf::Bind8::Conf'));
$conf->die ("\nUnix::Conf::Bind8->new_conf () failed") unless ($conf);
ok ($conf->delete_zone ('extremix.com'));
ok ($conf->get_zone ('extremix.com'), qr/^_get_zone: zone `extremix.com' not defined/);

undef (@directives);
undef (@warnings);
($obj, $ret, $_) = (undef) x 3;
$conf = undef;

$conf = Unix::Conf::Bind8->new_conf (
	FILE	=> 't/named.conf',
	SECURE_OPEN	=> 0,
);
ok ($conf->isa ('Unix::Conf::Bind8::Conf'));
$conf->die ("\nUnix::Conf::Bind8->new_conf () failed") unless ($conf);
ok ($conf->get_zone ('extremix.com'), qr/^_get_zone: zone `extremix.com' not defined/);
