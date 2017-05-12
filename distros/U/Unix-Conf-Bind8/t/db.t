use strict;
use warnings;
use Test;

BEGIN { plan tests => 99 };

use Unix::Conf;
ok (1);
use Unix::Conf::Bind8;
ok (1);

# get max debug messages
Unix::Conf->debuglevel (2);

# copy the original db file at the start of every test
`cp t/db.foo.com.org t/db.foo.com`;
my ($db, $ret);
my @records;

$db = Unix::Conf::Bind8->new_db (
	FILE		=> 't/db.foo.com',
	ORIGIN		=> 'foo.com',
	CLASS		=> 'IN',
	SECURE_OPEN	=> 0,
);
ok ($db->isa ('Unix::Conf::Bind8::DB'));
$db->die ("new_db () failed") unless ($db);
@records = $db->records ();
ok (@records, 25);
# make sure the scalar version works as well.
$ret = 0;
$ret++ while ($db->records);
ok ($ret, 25);

###########################################################################

# make sure new_soa blows up as SOA record already exists.
ok ($db->new_soa (
	CLASS	=> 'IN',
	TTL		=> '3d',
	AUTH_NS	=> 'ns1.foo.com',
	MAIL_ADDR	=> 'hostmaster.foo.com',
	SERIAL	=> 2002092700,
	REFRESH	=> '1w',
	RETRY	=> '1w',
	EXPIRE	=> '7w',
	MIN_TTL	=> '1w',
), qr/^new_soa: SOA already defined/);

ok ($ret = $db->get_soa ());
ok ($ret->auth_ns (), 'ns1');
ok ($ret->mail_addr (), 'hostmaster');
ok ($ret->serial (), '0025062001');
ok ($ret->refresh (), '24H');
ok ($ret->retry (), '2H');
ok ($ret->expire (), '14D');
ok ($ret->ttl (), '1D');

ok ($ret = $db->delete_soa ());
$ret->die ("couldn't delete SOA") unless ($ret);

# now get soa should fail
ok ($db->get_soa (), qr/^get_soa: SOA not defined/);

# setting a new soa should succeed
ok ($ret = $db->new_soa (
	CLASS	=> 'IN',
	TTL		=> '3d',
	AUTH_NS	=> 'ns2',
	MAIL_ADDR	=> 'admin',
	SERIAL	=> '2002092700',
	REFRESH	=> '1w',
	RETRY	=> '1w',
	EXPIRE	=> '7w',
	MIN_TTL	=> '1w',
));

ok ($ret->auth_ns (), 'ns2');
ok ($ret->mail_addr (), 'admin');
ok ($ret->serial (), '2002092700');
ok ($ret->refresh (), '1w');
ok ($ret->retry (), '1w');
ok ($ret->expire (), '7w');
ok ($ret->ttl (), '1w');

($db, $ret) = (undef) x 2;
$db = Unix::Conf::Bind8->new_db (
	FILE		=> 't/db.foo.com',
	ORIGIN		=> 'foo.com',
	CLASS		=> 'IN',
	SECURE_OPEN	=> 0,
);
ok ($db->isa ('Unix::Conf::Bind8::DB'));
$db->die ("new_db () failed") unless ($db);
@records = $db->records ();
ok (@records, 25);
ok (($ret = $db->get_soa ())->isa ("Unix::Conf::Bind8::DB::SOA"));
ok ($ret->auth_ns (), 'ns2');
ok ($ret->mail_addr (), 'admin');
ok ($ret->serial (), '2002092700');
ok ($ret->refresh (), '1w');
ok ($ret->retry (), '1w');
ok ($ret->expire (), '7w');
ok ($ret->ttl (), '1w');

###########################################################################
#                         Test get_* (other than SOA)                     #

# test error handling
ok ($ret = $db->get_ns ('', 'ns5'), qr/^get_ns: NS record for `' with rdata of `ns5' not defined/);
ok ($ret = $db->get_ns ('subdom'), qr/^get_ns: NS record for `subdom' not defined/);
ok (
	$ret = $db->new_ns 
		(
			LABEL	=> '',
			RDATA	=> 'ns1'
		), qr/^_insert_object: Record with label `' of type `NS' with data `ns1' already defined/
);
ok (($ret = $db->new_ns ( LABEL	=> '', RDATA	=> 'ns2',))->isa ("Unix::Conf::Bind8::DB::NS"));
ok ($ret->label (), '');
ok ($ret->rdata (), 'ns2');
ok ($ret->rtype (), 'NS');

# write out read back in and test again.
($db, $ret) = (undef) x 2;
$db = Unix::Conf::Bind8->new_db (
	FILE		=> 't/db.foo.com',
	ORIGIN		=> 'foo.com',
	CLASS		=> 'IN',
	SECURE_OPEN	=> 0,
);
ok ($db->isa ('Unix::Conf::Bind8::DB'));
$db->die ("new_db () failed") unless ($db);
@records = $db->records ();
ok (@records, 26);
ok (($ret = $db->get_ns ('', 'ns2'))->isa ("Unix::Conf::Bind8::DB::NS"));
ok ($ret->label (), '');
ok ($ret->rdata (), 'ns2');
ok ($ret->rtype (), 'NS');

# now try getting all NS records for ''.
ok (@{$ret = $db->get_ns ('')}, 3);
ok ($_->rdata (), qr/^(ns\.offsite\.net\.|ns1|ns2)$/) for (@$ret);

# test set_*
ok ($ret = $db->set_ns ('',
	[ 
		{ RDATA	=> 'name1' },
		{ RDATA	=> 'name2.foo.com.' },
		{ RDATA	=> 'name.offsite.net.' },
		{ RDATA	=> 'ns.sub' },
	]
));
$ret->die ("couldn't set NS records for `'") unless ($ret);
ok (@{$ret = $db->get_ns ('')}, 4);
ok ($_->rdata (), qr/^(name\.offsite\.net\.|name1|name2\.foo\.com\.|ns\.sub)$/) for (@$ret);

# write out read back in and test again.
($db, $ret) = (undef) x 2;
$db = Unix::Conf::Bind8->new_db (
	FILE		=> 't/db.foo.com',
	ORIGIN		=> 'foo.com',
	CLASS		=> 'IN',
	SECURE_OPEN	=> 0,
);
ok ($db->isa ('Unix::Conf::Bind8::DB'));
$db->die ("new_db () failed") unless ($db);
@records = $db->records ();
ok (@records, 27);
ok (@{$ret = $db->get_ns ('')}, 4);
# now the name are db relative.
ok ($_->rdata (), qr/^(name\.offsite\.net\.|name1|name2|ns\.sub)$/) for (@$ret);

# delete_meth () error handling. 
ok ($ret = $db->delete_mx ('', 'mx5'), qr/^delete_mx: MX record for `' with rdata of `mx5' not defined/);
ok ($ret = $db->delete_mx ('subdom'), qr/^delete_mx: MX record for `subdom' not defined/);

ok ($ret = $db->delete_mx ('', 'mx1'));
$ret->die ("could not delete MX record `mx1' for `'") unless ($ret);
ok (@{$ret = $db->get_mx ('')}, 2);
ok ($_->rdata (), qr/^(mail\.isp\.net\.|mx2)$/) for (@$ret);

# delete all MX records for bigboss
ok ($ret = $db->delete_mx ('bigboss'));
ok ($ret = $db->get_mx ('bigboss'), qr/^get_mx: MX record for `bigboss' not defined/);

# test object delete
ok ($ret = $db->get_ns ('', 'ns.sub'));
ok ($ret->delete ());
ok ($db->get_ns ('', 'ns.sub'), qr/^get_ns: NS record for `' with rdata of `ns.sub' not defined/);

# write out read back in and test again.
($db, $ret) = (undef) x 2;
$db = Unix::Conf::Bind8->new_db (
	FILE		=> 't/db.foo.com',
	ORIGIN		=> 'foo.com',
	CLASS		=> 'IN',
	SECURE_OPEN	=> 0,
);
ok ($db->isa ('Unix::Conf::Bind8::DB'));
$db->die ("new_db () failed") unless ($db);
ok (@records = $db->records (), 23);
ok (@{$ret = $db->get_mx ('')}, 2);
ok ($_->rdata (), qr/^(mail\.isp\.net\.|mx2)$/) for (@$ret);
ok ($ret = $db->get_mx ('bigboss'), qr/^get_mx: MX record for `bigboss' not defined/);
ok ($db->get_ns ('', 'ns.sub'), qr/^get_ns: NS record for `' with rdata of `ns.sub' not defined/);

# test that after deleting all records for a node, that node doesn't turn up.
ok ($db->delete_ns ('downtown'));
ok ($db->delete_a ('router.downtown'));

# write out read back in and test again.
($db, $ret) = (undef) x 2;
$db = Unix::Conf::Bind8->new_db (
	FILE		=> 't/db.foo.com',
	ORIGIN		=> 'foo.com',
	CLASS		=> 'IN',
	SECURE_OPEN	=> 0,
);
ok ($db->isa ('Unix::Conf::Bind8::DB'));
$db->die ("new_db () failed") unless ($db);
ok (@records = $db->records (), 20);

###########################################################################
# test that changing the label reattaches the record properly.
ok ($ret = $db->get_a ('gw', '192.168.5.1'));
ok ($ret->label ('gw.accts.foo.com.'));
ok ($ret->rdata ('192.168.11.1'));
ok (@records = $db->records ('accts'), 4);
ok (@records = $db->records ('maximus'), 4);
ok ($ret = $db->get_a ('gw.accts.foo.com.', '192.168.11.1'));
ok ($ret->rdata (), '192.168.11.1');

# write out read back in and test again.
($db, $ret) = (undef) x 2;
$db = Unix::Conf::Bind8->new_db (
	FILE		=> 't/db.foo.com',
	ORIGIN		=> 'foo.com',
	CLASS		=> 'IN',
	SECURE_OPEN	=> 0,
);
ok ($db->isa ('Unix::Conf::Bind8::DB'));
$db->die ("new_db () failed") unless ($db);

ok ($ret = $db->delete_records ('accts.foo.com.'));
$ret->die ("couldn't delete records for `accts.foo.com'") unless ($ret);
ok ($ret = $db->delete_records ('maximus'));
$ret->die ("couldn't delete records for `maximus'") unless ($ret);

# write out read back in and test again.
($db, $ret) = (undef) x 2;
$db = Unix::Conf::Bind8->new_db (
	FILE		=> 't/db.foo.com',
	ORIGIN		=> 'foo.com',
	CLASS		=> 'IN',
	SECURE_OPEN	=> 0,
);
ok ($db->isa ('Unix::Conf::Bind8::DB'));
$db->die ("new_db () failed") unless ($db);

ok (@records = $db->records (), 12);
ok ($db->records ('maximus'), qr/^records: no records defined for `maximus'/);

1;
