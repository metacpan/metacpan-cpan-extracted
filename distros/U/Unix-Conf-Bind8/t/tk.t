use strict;
use warnings;
use Test;

BEGIN { plan tests => 34 };

use Unix::Conf;
ok (1);
Unix::Conf->debuglevel (1);
use Unix::Conf::Bind8;
ok (1);

my ($conf, $tk, $ret);

# ensure a blank file
`rm -f t/named.conf`;

$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0,
);
ok ($conf->isa ("Unix::Conf::Bind8::Conf"));

$ret = $conf->get_trustedkeys ();
ok ($ret, qr/^_get_trustedkeys: `trustedkeys' not defined/);
$ret = $conf->delete_trustedkeys ();
ok ($ret, qr/^_get_trustedkeys: `trustedkeys' not defined/);

# test constructor, as well as key () set.
$tk = $conf->new_trustedkeys (
	KEYS	=> [
		[ 'extremix.net', 257, 255, 1, '"extremix.net-key-1"' ],
		[ 'extremix.net', 257, 255, 2, '"extremix.net-key-2"' ],
		[ 'extremix.net', 257, 255, 3, '"extremix.net-key-3"' ],
		[ 'extremix.net', 257, 255, 4, '"extremix.net-key-4"' ],
		[ '.', 257, 255, 1, '".-key-1"' ],
		[ '.', 257, 255, 2, '".-key-2"' ],
		[ '.', 257, 255, 3, '".-key-3"' ],
		[ '.', 257, 255, 4, '".-key-4"' ],
	],
);
ok ($tk->isa ("Unix::Conf::Bind8::Conf::Trustedkeys"));

# write it out and read it back in
$conf = undef;
$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0,
);
ok ($conf->isa ("Unix::Conf::Bind8::Conf"));
$tk = $conf->get_trustedkeys ();

# test domains (), algorithms (), and key () get.
for my $dom ($tk->domains ()) {
	for my $alg ($tk->algorithms ($dom)) {
		$ret = $tk->key ($dom, $alg);
		ok ($ret);
		$ret->die ("couldn't get trusted key for `$dom', `$alg'") 
			unless ($ret);
		ok ($ret->[4], qq["$dom-key-$alg"]);
	}
}

# test add_key error handling.
$ret = $tk->add_key ('extremix.net', 257, 255, 1, '"extremix.net-key-1"');
ok ($ret, qr/^add_key: key for domain `extremix.net' and algorithm `1' already defined/);

$ret = $tk->add_key ('extremix.com', 257, 255, 1, '"extremix.com-key-1"');
ok ($ret); $ret = undef;
ok (@$ret = $tk->domains (), 3);

# delete one algorithm
for (1..4) {
	$ret = $tk->delete_key ('extremix.net', $_);
	ok ($ret);
	$ret->die ("could not delete key for `extremix.net', `$_'")
		unless ($ret);
}

# now domain `extremix.net' ought to have been deleted.
$ret = undef;
ok (@$ret = $tk->domains (), 2);

$ret = $tk->delete_key ('.');
ok ($ret);
$ret->die ("couldn't delete `.'") unless ($ret);
$ret = undef;

# only one domain should now remain
ok (@$ret = $tk->domains (), 1);
# and it should be `extremix.com'
ok ($_, qr/^extremix\.com$/) for (@$ret);
