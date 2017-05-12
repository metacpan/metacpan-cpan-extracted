#
# TESTS
# o	Create new Acl from Unix::Conf::Bind8::Conf::new_acl (), with all arguments passed from
#	there. Name it extremix.net-slaves.
# o Test elements ().
# 	Test passing keys, negated elements. etc.
# o	Test add_elements with duplicate elements.
# 	Test passing keys, negated elements. etc.
# o	Test delete_elements with elements that don't exist
# o	Test delete_elements successfully.
# o	Test that delete_elements deletes embedded acls, when all their elements are deleted
#	in deeply nested Acl, but does not delete named acl.
# o Test __valid_elements with illegal ip_prefixes, ipaddresses etc.
# o	Create a new acl named extremix.net-office and put it before extremix.net-slaves.
# o	Add new acl name, to the previous one.
# o	Create keys (with Unix::conf::Bind8::Conf::new_key), and put it before extremix-net-slaves.
# o	Add keys to acl extremix-net-slaves.
# o	Add nested Acl with nested Acl.
# o	Try changing acl name and write it out/read it back in to test name has changed.
#	Test that name has changed by adding an acl element with old name, to make sure
# 	that old name does not exist anywhere in the internal datastructure.
#	Make sure delete is used instead of undef.
# 	
#
#
# TESTS are in a very unorganised manner. sort this file out.


use strict;
use warnings;
use Test;
BEGIN { plan tests => 70 };

use Unix::Conf;
ok (1);
use Unix::Conf::Bind8;
ok (1);

Unix::Conf->debuglevel (1);

my ($conf, $acl, $ret);

# ensure a blank file
`rm -f t/named.conf`;

$conf = Unix::Conf::Bind8->new_conf (
	FILE			=> 't/named.conf',
	SECURE_OPEN		=> 0
);

ok ($conf->isa ("Unix::Conf::Bind8::Conf"));

$ret = $conf->get_acl ('extremix.net-slaves');
ok ($ret, qr/^_get_acl: acl `extremix.net-slaves' not defined/);

$ret = $conf->delete_acl ('extremix.net-slaves');
ok ($ret, qr/^_get_acl: acl `extremix.net-slaves' not defined/);

# create a new acl with the new_acl interface in Unix::Conf::Bind8::Conf.
$acl = $conf->new_acl (
	NAME		=> 'extremix.net-slaves',
	ELEMENTS	=> [ qw (10.0.0.1 10.0.1.1 10.0.2.1) ],
);
ok ($acl->isa ('Unix::Conf::Bind8::Conf::Acl'));
$acl->die ("couldn't create acl `extremix.net-slaves'") unless ($acl);

$ret = $acl->elements ();
ok (@$ret, 3);
ok ($_, qr/^10\.0\.[012]\.1$/) for (@$ret);

# test with embedded Acl objects.

$ret = $conf->new_acl (ELEMENTS => [ qw(1.1.1.1 1.1.1.2) ]);
ok ($acl->isa ('Unix::Conf::Bind8::Conf::Acl'));
$acl->die ("couldn't create unnamed acl") unless ($acl);

$ret = $conf->new_acl (ELEMENTS => [ '2.2.2.1', '2.2.2.2', $ret ]);
ok ($ret->isa ('Unix::Conf::Bind8::Conf::Acl'));
$ret->die ("couldn't create unnamed acl") unless ($ret);

# 1.1.1.1 was defined in the first acl. we check through the second one.
ok ($ret->defined ('1.1.1.1'));

# set to what is already set + the new acl. 
# same as add_elements, but we want to test the elements () method.
$ret = $acl->elements (@{$acl->elements ()}, $ret);
ok ($ret);
$ret->die ("couldn't set elements") unless ($ret);


# write it out and read it back in
($conf, $acl, $ret) = (undef, undef, undef);

$conf = Unix::Conf::Bind8->new_conf (
	FILE			=> 't/named.conf',
	SECURE_OPEN		=> 0
);

ok ($conf->isa ("Unix::Conf::Bind8::Conf"));
$acl = $conf->get_acl ('extremix.net-slaves');

# get
$ret = $acl->elements ();
ok (@$ret, 7);
ok ($_, qr/^(10\.0\.[012]\.1|1\.1\.1\.[12]|2\.2\.2\.[12])$/)
	for (@$ret);

# test delete_elements thoroughly.
$ret = $acl->delete_elements (qw (1.1.1.1 1.1.1.2));
ok ($ret);
$ret->die ("couldn't delete elements") unless ($ret);

# test delete_elements error handling
$ret = $acl->delete_elements (qw (44.44.44.44 blah));
ok ($ret, qr/^delete_elements: element `44.44.44.44' not defined/);


# how to test that the embedded element has been deleted ?
# need to add new interfaces. then add tests here
# till then try testing by accessing object internals.
my @key = keys (%{$acl->{objects}});
ok (keys (%{$acl->{objects}{$key[0]}{objects}}), 0);


# test elements () error handling.
# extremix.net-office doesn't exist.
$ret = $acl->elements (qw (extremix.net-office 10.0.0.1));
ok ($ret, qr/^__valid_element: acl `extremix.net-office' not defined/);

# key extremix.net-key doesn't exist.
$ret = $acl->elements ('  !   key    extremix.net-key  ', '10.0.0.1');
ok ($ret, qr/^__valid_element: key `extremix.net-key' not defined/);

# create extremix.net-office
$ret = $conf->new_acl (
	NAME		=> 'extremix.net-office',
	ELEMENTS	=> '192.168.1.3',
	WHERE		=> 'before',
	WARG		=> $acl,
);
ok ($ret->isa ('Unix::Conf::Bind8::Conf::Acl'));
$ret->die ("couldn't create acl `extremix.net-office'") unless ($ret);
$ret = $ret->elements ();
ok (@$ret, 1);
ok ($_, qr/^(192\.168\.1\.3)$/) for (@$ret);

# create key extremix.net-key
$ret = $conf->new_key (
	NAME		=> 'extremix.net-key',
	ALGORITHM	=> 'hmac-md5',
	SECRET		=> 'top secret',
	WHERE		=> 'before',
	WARG		=> $acl,
);
ok ($ret->isa ('Unix::Conf::Bind8::Conf::Key'));
$ret->die ("couldn't create key `extremix.net-key'") 
	unless ($ret);

ok ($ret->name (), 'extremix.net-key');
ok ($ret->algorithm (), 'hmac-md5');
ok ($ret->secret (), 'top secret');

# write it out and read it back in
($conf, $acl, $ret) = (undef, undef, undef);

$conf = Unix::Conf::Bind8->new_conf (
	FILE			=> 't/named.conf',
	SECURE_OPEN		=> 0
);

ok ($conf->isa ("Unix::Conf::Bind8::Conf"));
$acl = $conf->get_acl ('extremix.net-slaves');
ok ($acl->isa ("Unix::Conf::Bind8::Conf::Acl"));
$acl->die ("couldn't get acl `extremix.net-slaves'")
	unless ($acl);
$ret = $conf->get_key ('extremix.net-key');
ok ($ret->isa ("Unix::Conf::Bind8::Conf::Key"));
$ret->die ("couldn't get key `extremix.net-key'")
	unless ($ret);

# check the key attributes.
ok ($ret->name (), 'extremix.net-key');
ok ($ret->algorithm (), 'hmac-md5');
ok ($ret->secret (), 'top secret');

# should succeed now.
$ret = $acl->elements (
	'extremix.net-office', ' !   key    extremix.net-key   ','10.1.0.1', '10.2.0.2', '10.3.0.3', '10.4.0.4', '10.5.0.5', ' !  10.6.0.6'
);
ok ($ret);
$ret->die ("couldn't set elements") unless ($ret);
$ret = $acl->elements ();
ok (@$ret, 8);
ok ($_, qr/^(!key extremix.net-key|extremix.net-office|10\.[12345]\.0\.[12345]|!10\.6\.0\.6)$/) for (@$ret);

# test add_elements error handling.
$ret = $acl->add_elements ('   !   key blah  ');
ok ($ret, qr/^__valid_element: key `blah' not defined/);

# trying to add elements which already exist should fail.
ok ($ret = $acl->add_elements ('10.1.0.1'), qr/^add_elements: element `10.1.0.1' already defined/);

$ret= $acl->add_elements (qw (192.168.1.1 192.168.1.2));
ok ($ret);
$ret->die ("couldn't add elements") unless ($ret);
$ret = $acl->elements ();
ok (@$ret, 10);
ok ($_, qr/^(!key extremix.net-key|extremix.net-office|192\.168\.1\.[12]|10\.[12345]\.0\.[12345]|!10\.6\.0\.6)$/)
	for (@$ret);

$ret = $conf->get_acl ('extremix.net-office');
ok ($ret->isa ("Unix::Conf::Bind8::Conf::Acl"));
$ret = $ret->name ("new-name");
ok ($ret);
$ret->die ("couldn't set name") unless ($ret);

$ret = $conf->get_key ('extremix.net-key');
ok ($ret->isa ("Unix::Conf::Bind8::Conf::Key"));
$ret = $ret->name ("new-name");
ok ($ret);
$ret->die ("couldn't set name") unless ($ret);

$ret = $acl->add_elements ('key extremix.net-key');
ok ($ret, qr/^__valid_element: key `extremix.net-key' not defined/);
