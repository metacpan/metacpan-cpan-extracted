use strict;
use warnings;
use Test;
BEGIN { plan tests => 20 };

use Unix::Conf;
ok (1);
Unix::Conf->debuglevel (1);
use Unix::Conf::Bind8;
ok (1);

my ($conf, $controls, $ret);

# ensure a blank file
`rm -f t/named.conf`;

$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0,
);
ok ($conf->isa ("Unix::Conf::Bind8::Conf"));

$ret = $conf->get_controls ();
ok ($ret, qr/^_get_controls: `controls' not defined/);
$ret = $conf->delete_controls ();
ok ($ret, qr/^_get_controls: `controls' not defined/);

$controls = $conf->new_controls (
	UNIX	=> [ "/var/run/ndc", '0600', 0, 0 ],
	INET	=> [ '*', 53, [ qw (192.168.1.1 10.0.0.1) ]],
);
ok ($controls->isa ("Unix::Conf::Bind8::Conf::Controls"));

# write it out and read it back in
$conf = undef;
$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0,
);
ok ($conf->isa ("Unix::Conf::Bind8::Conf"));
$controls = $conf->get_controls ();
ok ($controls->isa ("Unix::Conf::Bind8::Conf::Controls"));

# test values by getting them
$ret = $controls->unix ();
ok ($ret->[0], '"/var/run/ndc"');
ok ($ret->[1], '0600');
ok ($ret->[2], 0);
ok ($ret->[3], 0);

$ret = $controls->inet ();
ok ($ret->[0], '*');
ok ($ret->[1], 53);
ok ($ret->[2]->isa ("Unix::Conf::Bind8::Conf::Acl"));
ok (@{$ret->[2]->elements ()}, 2);

ok ($ret = $controls->delete_inet ());
$ret->die ("couldn't delete inet channel")	unless ($ret);
ok ($ret = $controls->delete_unix ());
$ret->die ("couldn't delete unix channel")	unless ($ret);

$ret = $controls->inet ();
ok ($ret, qr/^inet: inet control channel not defined/);
$ret = $controls->unix ();
ok ($ret, qr/^unix: unix control channel not defined/);
