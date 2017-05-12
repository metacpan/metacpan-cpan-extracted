use strict;
use warnings;
use Test;
BEGIN { plan tests => 13 };

use Unix::Conf;
use Unix::Conf::Bind8;

Unix::Conf->debuglevel (1);

# ensure a blank file
`rm -f t/named.conf`;
`rm -f t/include.conf`;

my ($conf, $include, $ret);

$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0
);
ok ($conf->isa ("Unix::Conf::Bind8::Conf"));

ok ($conf->get_include ('include.conf'), qr/^_get_include: include `include.conf' not defined/);
ok ($conf->delete_include ('include.conf'), qr/^_get_include: include `include.conf' not defined/);

$include = $conf->new_include (
	FILE		=> 't/include.conf',
	SECURE_OPEN	=> 0,
);
ok ($include->isa ("Unix::Conf::Bind8::Conf::Include"));

ok ($include->name (), 't/include.conf');
$ret = $include->conf ();
ok ($ret->isa ("Unix::Conf::Bind8::Conf"));
ok ($ret->fh (), "t/include.conf");

# write it out and read it back in
($conf, $include, $ret) = (undef) x 3;

$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0
);
ok ($conf->isa ("Unix::Conf::Bind8::Conf"));
ok ($include = $conf->get_include ('t/include.conf'));
ok ($include->isa ("Unix::Conf::Bind8::Conf::Include"));
$include->die ("couldn't get `t/include.conf'") unless ($include);
ok ($include->name (), 't/include.conf');
$ret = $include->conf ();
ok ($ret->isa ("Unix::Conf::Bind8::Conf"));
ok ($ret->fh (), "t/include.conf");
