use strict;
use warnings;
use Test;

BEGIN { plan tests => 24 };

use Unix::Conf;
use Unix::Conf::Bind8;

Unix::Conf->debuglevel (1);


# ensure a blank file.
`rm t/named.conf`;

my ($conf, $server, $ret);

$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0,
);

ok ($conf->isa ("Unix::Conf::Bind8::Conf"));

$ret = $conf->get_server ('10.0.0.1');
ok ($ret, qr/^_get_server: server `10.0.0.1' not defined/);
$ret = $conf->delete_server ('10.0.0.1');
ok ($ret, qr/^_get_server: server `10.0.0.1' not defined/);

$ret = $conf->new_key (
	NAME		=> 'extremix.net-key',
	ALGORITHM	=> 'hmac-md5',
	SECRET		=> 'top secret',
);

# create a new one. should fail.
$server = $conf->new_server (
	NAME				=> '10.0.0.1',
	BOGUS				=> 'no',
	'SUPPORT-IXFR'		=> 'no',
	TRANSFERS			=> 5,
	'TRANSFER-FORMAT'	=> 'one-answer',
	KEYS				=> [ qw (extremix.net-key) ],
);
ok ($server->isa ("Unix::Conf::Bind8::Conf::Server"));
$server->die ("could not create server `10.0.0.1'")	unless ($server);

# get values and check them out.
ok ($server->name (), '10.0.0.1');
ok ($server->bogus (), 'no');
ok ($server->support_ixfr (), 'no');
ok ($server->transfers (), 5);
ok ($server->transfer_format (), 'one-answer');
ok ("@{$server->keys ()}", 'extremix.net-key');

# write it out and read it back in
# and then check values again.
($conf, $server, $ret) = undef;
$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0,
);
ok ($conf->isa ("Unix::Conf::Bind8::Conf"));
$server = $conf->get_server ('10.0.0.1');
ok ($server->isa ("Unix::Conf::Bind8::Conf::Server"));

# get values and check them out.
ok ($server->name (), '10.0.0.1');
ok ($server->bogus (), 'no');
ok ($server->support_ixfr (), 'no');
ok ($server->transfers (), 5);
ok ($server->transfer_format (), 'one-answer');
ok ("@{$server->keys ()}", 'extremix.net-key');

$ret = $server->delete_bogus ();
ok ($ret);
$ret->die ("couldn't delete bogus") unless ($ret);
ok ($server->bogus (), qr/^bogus: `bogus' not defined/);
$ret = $server->delete_keys ();
ok ($ret);
$ret->die ("couldn't delete bogus") unless ($ret);
ok ($server->bogus (), qr/^bogus: `bogus' not defined/);

# now try deleting again.
ok ($server->delete_bogus (), qr/^delete_bogus: `bogus' not defined/);
ok ($server->delete_keys (), qr/^delete_keys: `keys' not defined/);
