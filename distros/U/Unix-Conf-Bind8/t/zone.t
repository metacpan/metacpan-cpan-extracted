use strict;
use warnings;
use Test;
BEGIN { plan tests => 73 };

use Unix::Conf;
Unix::Conf->debuglevel (2);
use Unix::Conf::Bind8;

my ($conf, $zone, $ret);

# ensure a blank file
`rm -f t/named.conf`;
$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0
);
ok ($conf->isa ("Unix::Conf::Bind8::Conf"));

ok ($conf->get_zone ('extremix.net'), qr/^_get_zone: zone `extremix.net' not defined/);
ok ($conf->delete_zone ('extremix.net'), qr/^_get_zone: zone `extremix.net' not defined/);

$zone = $conf->new_zone (
	NAME				=> 'extremix.net',
	TYPE				=> 'master',
	CLASS				=> 'IN',
	FILE				=> 'db.extremix.net',
	NOTIFY				=> 'yes',
	DIALUP				=> 'yes',
	FORWARD				=> 'yes',
	'CHECK-NAMES'		=> 'fail',
	'TRANSFER-SOURCE'	=> '192.168.1.1',
	'MAX-TRANSFER-TIME-IN'	=> 5,
	'ALSO-NOTIFY'		=> [ qw (192.168.1.1 192.168.1.2 192.168.1.3) ],
	'FORWARDERS'		=> [ qw (192.168.1.1 192.168.1.2 192.168.1.3) ],
	'MASTERS'			=> { PORT => 55, ADDRESS => [ qw (192.168.1.1 192.168.1.2 192.168.1.3) ] },
	'ALLOW-TRANSFER'	=> [ qw (192.168.1.1 192.168.1.2 192.168.1.3) ],
	'ALLOW-QUERY'		=> [ qw (192.168.1.1 192.168.1.2 192.168.1.3) ],
	'ALLOW-UPDATE'		=> [ qw (192.168.1.1 192.168.1.2 192.168.1.3) ],
	PUBKEY				=> [ 255, 257, 4, 'zone-key', ],
);
ok ($zone->isa ("Unix::Conf::Bind8::Conf::Zone"));
$zone->die ("couldn't create zone `extremix.net'") unless ($zone);

# write it out and read it back in
($conf, $zone, $ret) = (undef) x 3;
$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0
);
ok ($zone = $conf->get_zone ('extremix.net'));
$zone->die ("couldn't get zone `extremix.net'")
	unless ($zone);
$zone->isa ("Unix::Conf::Bind8::Conf::Zone");

ok ($ret = $zone->delete_forward ());
$ret->die ("couldn't delete `forward'")	unless ($ret);
# try deleting again
ok ($ret = $zone->delete_forward (), qr/^delete_forward: zone directive `forward' not defined/);

ok ($ret = $zone->add_to_forwarders (qw (192.168.1.3 10.0.0.2 10.0.0.3)), qr/^add_to_forwarders: address `192.168.1.3' already defined/);
ok ($ret = $zone->add_to_forwarders (qw (10.0.0.1 10.0.0.2 10.0.0.3)));
$ret->die ("couldn't add to forwarders") unless ($ret);
ok (@{$ret = $zone->forwarders ()},6);
ok ($_, qr/^(10\.0\.0\.[123]|192\.168\.1\.[123])$/) for (@$ret);

# write out, read in and test again.
($conf, $zone, $ret) = (undef) x 3;
$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0
);
ok ($zone = $conf->get_zone ('extremix.net'));
$zone->die ("couldn't get zone `extremix.net'")
	unless ($zone);
$zone->isa ("Unix::Conf::Bind8::Conf::Zone");

ok (@{$ret = $zone->forwarders ()},6);
ok ($_, qr/^(10\.0\.0\.[123]|192\.168\.1\.[123])$/) for (@$ret);

ok ($ret = $zone->delete_from_forwarders (qw (5.5.5.5 6.6.6.6)), qr/^delete_from_forwarders: address `5.5.5.5' not defined/);
ok ($ret = $zone->delete_from_forwarders (qw (192.168.1.1 10.0.0.1)));
ok (@{$ret = $zone->forwarders ()},4);
ok ($_, qr/^(10\.0\.0\.[23]|192\.168\.1\.[23])$/) for (@$ret);

# write out, read in and test again.
($conf, $zone, $ret) = (undef) x 3;
$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0
);
ok ($zone = $conf->get_zone ('extremix.net'));
$zone->die ("couldn't get zone `extremix.net'")
	unless ($zone);
$zone->isa ("Unix::Conf::Bind8::Conf::Zone");
ok (@{$ret = $zone->forwarders ()},4);
ok ($_, qr/^(10\.0\.0\.[23]|192\.168\.1\.[23])$/) for (@$ret);


# test acl elements.
ok ($ret = $zone->add_to_allow_query (qw (192.168.1.3 10.0.0.2 10.0.0.3)), qr/^add_elements: element `192.168.1.3' already defined/);
ok ($ret = $zone->add_to_allow_query (qw (10.0.0.1 10.0.0.2 10.0.0.3)));
$ret->die ("couldn't add to allow_query") unless ($ret);
ok (@{$ret = $zone->allow_query_elements ()},6);
ok ($_, qr/^(10\.0\.0\.[123]|192\.168\.1\.[123])$/) for (@$ret);

# write out, read in and test again.
($conf, $zone, $ret) = (undef) x 3;
$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0
);
ok ($zone = $conf->get_zone ('extremix.net'));
$zone->die ("couldn't get zone `extremix.net'")
	unless ($zone);
$zone->isa ("Unix::Conf::Bind8::Conf::Zone");

ok (@{$ret = $zone->allow_query_elements ()},6);
ok ($_, qr/^(10\.0\.0\.[123]|192\.168\.1\.[123])$/) for (@$ret);

ok ($ret = $zone->delete_from_allow_query (qw (5.5.5.5 6.6.6.6)), qr/^delete_elements: element `5.5.5.5' not defined/);
ok ($ret = $zone->delete_from_allow_query (qw (192.168.1.1 10.0.0.1)));
ok (@{$ret = $zone->allow_query_elements ()},4);
ok ($_, qr/^(10\.0\.0\.[23]|192\.168\.1\.[23])$/) for (@$ret);

# write out, read in and test again.
($conf, $zone, $ret) = (undef) x 3;
$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0
);
ok ($zone = $conf->get_zone ('extremix.net'));
$zone->die ("couldn't get zone `extremix.net'")
	unless ($zone);
$zone->isa ("Unix::Conf::Bind8::Conf::Zone");
ok (@{$ret = $zone->allow_query_elements ()},4);
ok ($_, qr/^(10\.0\.0\.[23]|192\.168\.1\.[23])$/) for (@$ret);

ok ($ret = $zone->masters (ADDRESS => [ '10.0.0.1' ]));
$ret->die ("couldn't set masters") unless ($ret);

$ret = $zone->masters ();
# not port.
ok ($ret->[0], undef);
ok ("@{$ret->[1]}", qr/^10\.0\.0\.1$/);
# write out, read in and test again.
($conf, $zone, $ret) = (undef) x 3;
$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0
);
ok ($zone = $conf->get_zone ('extremix.net'));
$zone->die ("couldn't get zone `extremix.net'")
	unless ($zone);
$zone->isa ("Unix::Conf::Bind8::Conf::Zone");
$ret = $zone->masters ();
# not port.
ok ($ret->[0], undef);
ok ("@{$ret->[1]}", qr/^10\.0\.0\.1$/);
