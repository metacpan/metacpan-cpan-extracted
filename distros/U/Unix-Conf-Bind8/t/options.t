use strict;
use warnings;
use Test;

BEGIN { plan tests => 119 };

use Unix::Conf;
ok (1);
use Unix::Conf::Bind8;
ok (1);

Unix::Conf->debuglevel (1);

my ($conf, $options, $acl, $ret);
my @options;

# start out with an empty file. test the code in the
# constructor to set options and whether the actual method's
# interface is compatible
`rm -f t/named.conf`;

$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0,
);

ok ($conf->isa ('Unix::Conf::Bind8::Conf'));
$conf->die ("Unix::Conf::Bind8->new_conf () failed") unless ($conf);

ok ($ret = $conf->get_options (), qr/^_get_options: `options' not defined/);

ok ($ret = $conf->delete_options (), qr/^_get_options: `options' not defined/);
# must fail as no options directive is present

ok (
	($acl = $conf->new_acl ( 
		ELEMENTS => [ qw (localhost localnets) ] 
	))->isa ("Unix::Conf::Bind8::Conf::Acl")
);

$options = $conf->new_options (
	'DIRECTORY'				=> '.',
	'NAMED-XFER'			=> '/usr/libexec/named-xfer',
	'DUMP-FILE'				=> '/named/dump.db',
	'PID-FILE'				=> '/var/run/named.pid',
	'STATISTICS-FILE'		=> 'named.stats',
	'MEMSTATISTICS-FILE'	=> 'named.memstats',
	'CHECK-NAMES'			=> { master	=> 'fail', slave => 'warn', response => 'ignore' },
	'HOST-STATISTICS'		=> 'no',
	'DEALLOCATE-ON-EXIT'	=> 'no',
	'DATASIZE'				=> 'default',
	'STACKSIZE'				=> 'default',
	'CORESIZE'				=> 'default',
	'FILES'					=> 'unlimited',
	'RECURSION'				=> 'yes',
	'FETCH-GLUE'			=> 'yes',
	'FAKE-IQUERY'			=> 'no',
	'NOTIFY'				=> 'yes',
	'MAX-SERIAL-QUERIES'	=> 4,
	'AUTH-NXDOMAIN'			=> 'yes',
	'MULTIPLE-CNAMES'		=> 'no',
	'ALLOW-QUERY'			=> [ 'any' ],
	'ALLOW-TRANSFER'		=> $acl,
	'ALLOW-RECURSION'		=> [ qw(10.0.0.0/24 10.0.1.0/24 10.0.2.0/24 10.0.3.0/24) ],
	'TRANSFERS-IN'			=> 10,
	'TRANSFERS-OUT'			=> 0,
	'MAX-TRANSFER-TIME-IN'	=> 120,
	'TRANSFER-FORMAT'		=> 'one-answer',
	'QUERY-SOURCE'			=> { PORT => '*', ADDRESS => '*' },
	'FORWARD'				=> 'first',
	'FORWARDERS'			=> [],
	'TOPOLOGY'				=> [ qw (localhost localnets) ],
	'LISTEN-ON'				=> {
									53 		=> [ 'any', '5.6.7.8' ],
									1234	=> [ '!1.2.3.4', '1.2.3/24', ],
								},
	'RRSET-ORDER'			=> [
									{ ORDER	=> 'cyclic' },
									{ NAME	=> 'extremix.net', ORDER => 'random' },
									{ NAME	=> 'foo.com', TYPE	=> 'A',	ORDER => 'cyclic' },
									{ NAME	=> 'boo.com', CLASS => 'IN', TYPE => 'NS', ORDER => 'fixed' },
								],
	'CLEANING-INTERVAL'		=> 60,
	'INTERFACE-INTERVAL'	=> 60,
	'STATISTICS-INTERVAL'	=> 60,
	'MAINTAIN-IXFR-BASE'	=> 'no',
	'MAX-IXFR-LOG-SIZE'		=> 20,
);

ok ($options->isa ("Unix::Conf::Bind8::Conf::Options"));
$options->die ("couldn't create options")	unless ($options);

($conf, $options, $acl, $ret) = (undef) x 4;
# read in the same file we wrote out.
$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0,
);

ok (UNIVERSAL::isa ($conf, 'Unix::Conf::Bind8::Conf'));
# die if we fail as all tests below depend on success of this test.
$conf->die ("\nUnix::Conf::Bind8->new_conf () failed") unless ($conf);

# new_options should fail as options is already defined.
ok ($ret = $conf->new_options (), qr/^_add_options: `options' already defined/);

ok (($options = $conf->get_options ())->isa ("Unix::Conf::Bind8::Conf::Options"));
$options->die ("couldn't get options")	unless ($options);

ok (@options = $options->options (), 37);

# test autocreated delete. with this all autocreated deletes are ok.
ok ($ret = $options->delete_directory ());
$ret->die ("couldn't delete option `directory'") unless ($ret);

# should fail as version not yet defined.
ok ($ret = $options->version (), qr/^version: option not defined/);

ok ($ret = $options->version ('NAMED-8.2.3'));
$ret->die ("couldn't set option `version'") unless ($ret);
ok ($ret = $options->version (), 'NAMED-8.2.3');
$ret->die ("couldn't get option `version'")	unless ($ret);

# TEST add_to_ code for Acl type options.
ok ($ret = $options->add_to_allow_query ('none'));
$ret->die ("couldn't add to option `allow-query'") unless ($ret);
ok (@{$ret = $options->allow_query_elements ()}, 2);
$ret->die ("couldn't get option `allow-query'") unless ($ret);

# This option is not yet defined. should get created.
ok ($ret = $options->add_to_blackhole ( [ qw (10.0.0.1 10.0.0.2 10.0.0.3 10.0.0.4) ]));
$ret->die ("couldn't add to option `blackhole'") unless ($ret);
ok (@{$ret = $options->blackhole_elements ()}, 4);
$ret->die ("couldn't get option `blackhole'") unless ($ret);

# delete_from test for Acl type options.
ok ($ret = $options->delete_from_allow_recursion (qw (10.0.0.0/24 10.0.9.0/24)),
	qr/^delete_elements: element `10.0.9.0\/24' not defined/);

ok ($ret = $options->delete_from_allow_recursion (qw (10.0.0.0/24 10.0.3.0/24)));
$ret->die ("could not delete from option `allow-recursion'") unless ($ret);
ok (@{$ret = $options->allow_recursion_elements ()}, 2);
$ret->die ("couldn't get option `allow-recursion'") unless ($ret);


############################### query-source #######################################

ok ($ret = $options->query_source ( PORT	=> 53,	ADDRESS	=> '192.168.1.1' ));
$ret->die ("couldn't set option `query-source'") unless ($ret);
ok ($ret = $options->query_source ());
$ret->die ("couldn't get option `query-source'") unless ($ret);
ok ($ret->{PORT}, 53);
ok ($ret->{ADDRESS}, '192.168.1.1');

ok ($ret = $options->delete_query_source ());
$ret->die ("couldn't delete option `query-source'") unless ($ret);

ok ($ret = $options->query_source (), qr/^query_source: option not defined/);

############################### check-names #######################################

# set only master to see if we are resetting the old values, or only adding.
ok ($ret = $options->check_names ( master => 'ignore' ));
$ret->die ("couldn't set option `check-names'") unless ($ret);
# if keys > 1 most probably check-names () above is not resetting the values. 
# instead it is just adding them.
ok (keys (%{$ret = $options->check_names ()}), 1);
$ret->die ("couldn't get option `check-names'") unless ($ret);
ok ($ret->{master}, 'ignore');

# test add_to with error condition
ok ($ret = $options->add_to_check_names ( master => 'fail'), 
	qr/^add_to_check_names: `master' already defined/);

# try to delete a key not present `response'
ok ($ret = $options->delete_from_check_names ('master', 'response'), 
	qr/^delete_from_check_names: `response' not defined/);

# only key being deleted, which should delete the option itself.
ok ($ret = $options->delete_from_check_names ('master'));
$ret->die ("couldn't delete from option `check-names'") unless ($ret);

# getting option should bomb.
ok ($ret = $options->check_names (), 
	qr/^check_names: option not defined/);

ok ($ret = $options->add_to_check_names ( master => 'warn', slave => 'warn', response => 'warn'));
$ret->die ("couldn't add to option `check-names'") unless ($ret);

ok (keys (%{$ret = $options->check_names ()}), 3);
$ret->die ("couldn't get option `check-names'") unless ($ret);
ok ($ret->{master}, 'warn');
ok ($ret->{slave}, 'warn');
ok ($ret->{response}, 'warn');

############################### forwarders #######################################

ok (@{$ret = $options->forwarders ()}, 0);
$ret->die ("couldn't get forwarders") unless ($ret);

ok ($ret = $options->add_to_forwarders (qw (10.0.0.1 10.0.0.2 10.0.0.3 10.0.0.4 10.0.0.5)));
$ret->die ("couldn't add to  forwarders") unless ($ret);

ok (@{$ret = $options->forwarders ()}, 5);
$ret->die ("couldn't get forwarders") unless ($ret);
ok (@$ret, 5);

# now add_to_forwarders should bomb.
ok ($ret = $options->add_to_forwarders (qw (10.0.0.2)), 
	qr/^add_to_forwarders: address `10.0.0.2' already defined/);

# delete from forwarders bombs
ok ($ret = $options->delete_from_forwarders (qw (10.0.0.9)),
	qr/^delete_from_forwarders: address `10.0.0.9' not defined/);

# delete from forwarders succceeds.
ok ($ret = $options->delete_from_forwarders (qw (10.0.0.2)));
$ret->die ("couldn't delete from  forwarders") unless ($ret);

ok (@{$ret = $options->forwarders ()}, 4);
$ret->die ("couldn't get forwarders") unless ($ret);

# now test set (overwriting previous values)
# try setting to emtpy array
ok ($ret = $options->forwarders ([]));
$ret->die ("couldn't set forwarders") unless ($ret);

ok (@{$ret = $options->forwarders ()}, 0);
$ret->die ("couldn't get forwarders") unless ($ret);

# forwarders get should fail after deleting option
ok ($ret = $options->delete_forwarders ());
$ret->die ("couldn't delete forwarders") unless ($ret);

ok ($ret = $options->forwarders (), qr/^forwarders: option not defined/);

# delete_forwarders should fail.
ok ($ret = $options->delete_forwarders (), qr/^delete_forwarders: option not defined/);

############################### listen-on #######################################

# test get

ok (keys (%{$ret = $options->listen_on ()}), 2);
ok ($_, qr/^(1234|)$/) for (keys (%$ret));
ok ($_, qr/^(any|5\.6\.7\.8)$/) for (@{$ret->{''}});
ok ($_, qr{^(1\.2\.3/24|\!1\.2\.3\.4)$}) for (@{$ret->{1234}});

# listen_on () has been tested in the Options::new ().
# now test for illegal port.
ok ($ret = $options->listen_on (
	blah	=> [ qw (192.168.1.1) ],
), qr/^listen_on: illegal PORT `blah'/);

ok ($ret = $options->listen_on (
	53	=> [ qw(10.0.0.1) ],
	54	=> [ qw(10.0.0.1 10.0.0.2 10.0.0.3 10.0.0.4) ],
));

ok ($ret = $options->get_listen_on (55), qr/^get_listen_on: no elements defined for port `55'/);

ok (($ret = $options->get_listen_on (53))->isa ('Unix::Conf::Bind8::Conf::Acl')); 
ok (@{$ret = $ret->elements ()}, 1);

ok ($ret = $options->get_listen_on_elements (55), 
	qr/^get_listen_on_elements: no elements defined for port `55'/);

ok (@{$ret = $options->get_listen_on_elements (53)}, 1);

# deleting the only address should delete the port itself from the datastructure
# so the get below should fail
ok ($ret = $options->delete_from_listen_on (
	53	=> [ qw(10.0.0.1) ],
));

ok ($ret = $options->get_listen_on (53), qr/^get_listen_on: no elements defined for port `53'/);

ok ($ret = $options->delete_from_listen_on (
	54	=> [ qw(10.0.0.1 10.0.0.4) ],
));
ok (@{$ret = $options->get_listen_on_elements (54)}, 2);

# with this the whole option must have been deleted.
ok ($ret = $options->delete_from_listen_on (
	54	=> [ qw(10.0.0.2 10.0.0.3) ],
));

ok ($ret = $options->listen_on (), qr/^get_listen_on_elements: option not defined/);

# set again to test delete_listen_on.
ok ($ret = $options->listen_on (
	53	=> [ qw(10.0.0.1 10.0.0.2) ],
	54	=> [ qw(10.0.0.1 10.0.0.2) ],
	55	=> [ qw(10.0.0.1 10.0.0.2) ],
	56	=> [ qw(10.0.0.1 10.0.0.2) ],
));

ok ($ret = $options->delete_listen_on (53, 55));
ok (keys (%{$ret = $options->listen_on ()}), 2);
ok ($ret = $options->delete_listen_on ());
ok ($ret = $options->listen_on (), qr/^get_listen_on_elements: option not defined/);

############################### rrset-order #######################################

# check the number of names defined
ok (keys (%{$ret = $options->rrset_order ()}), 4);

# test get_rrset_order successfully.
ok ($ret = $options->get_rrset_order ('*', 'ANY', 'ANY'), 'cyclic');
$ret->die ("couldn't get rrset_order") unless ($ret);

ok ($ret = $options->get_rrset_order ('', '', ''), 'cyclic');
$ret->die ("couldn't get rrset_order") unless ($ret);
ok ($ret = $options->get_rrset_order ('foo.com', 'ANY', 'A'), 'cyclic');
$ret->die ("couldn't get rrset_order") unless ($ret);
ok ($ret = $options->get_rrset_order ('boo.com', 'IN', 'NS'), 'fixed');
$ret->die ("couldn't get rrset_order") unless ($ret);
ok ($ret = $options->get_rrset_order ('extremix.net', 'ANY', 'ANY'), 'random');
$ret->die ("couldn't get rrset_order") unless ($ret);

# test add_to_rrset_order
ok ($ret = $options->add_to_rrset_order (
	NAME	=> 'boo.com',
	CLASS	=> 'IN',
	TYPE	=> 'A',
	ORDER	=> 'fixed',
));
$ret->die ("couldn't add to rrset-order") unless ($ret);
ok ($ret = $options->get_rrset_order ('boo.com', 'IN', 'A'), 'fixed');
$ret->die ("couldn't get rrset-order") unless ($ret);

# test add_to_rrset_order with error condition
ok ($ret = $options->add_to_rrset_order (
	ORDER	=> 'cyclic',
), qr/^add_to_rrset_order: order already defined for \*, ANY, ANY/);

# test the part where keys up the tree are automatically deleted if
# no keys exist, to the option itself being deleted. also test
# get_rrset_order returning differnt parts of the tree, in the process.

ok ($ret = $options->rrset_order (
	{
		NAME 	=> 'extremix.net',
		CLASS	=> 'IN',
		TYPE	=> 'A',
		ORDER	=> 'cyclic',
	},
	{
		NAME 	=> 'extremix.net',
		CLASS	=> 'IN',
		TYPE	=> 'NS',
		ORDER	=> 'cyclic',
	},
	{
		NAME 	=> 'extremix.net',
		CLASS	=> 'ANY',
		TYPE	=> 'ANY',
		ORDER	=> 'cyclic',
	},
	{
		NAME 	=> 'foo.com',
		CLASS	=> 'IN',
		TYPE	=> 'A',
		ORDER	=> 'cyclic',
	},
));
# should get two keys 'extremix.net' and 'foo.com'
ok (keys (%{$ret = $options->get_rrset_order ()}), 2);
ok ($_, qr/^(extremix.net|foo.com)$/)  for (keys (%$ret));

# should get two keys 'IN', 'ANY'
ok (keys (%{$ret = $options->get_rrset_order ('extremix.net')}), 2);
ok ($_, qr/^(IN|ANY)$/)  for (keys (%$ret));
# should get two keys 'A', 'NS'
ok (keys (%{$ret = $options->get_rrset_order ('extremix.net', 'IN')}), 2);
ok ($_, qr/^(A|NS)$/)  for (keys (%$ret));

# test delete_from_rrset_order error handling
ok ($ret = $options->delete_from_rrset_order (
	NAME	=> 'foo.com', 
	CLASS	=> 'IN', 
	TYPE	=> 'NS'
), qr/^delete_from_rrset_order: NS not defined for foo.com, IN/);

ok ($ret = $options->delete_from_rrset_order (
	NAME	=> 'foo.com', 
	CLASS	=> 'ANY', 
), qr/^delete_from_rrset_order: ANY not defined for foo.com/);

ok ($ret = $options->delete_from_rrset_order ( NAME	=> 'boo.com'), 
	qr/^delete_from_rrset_order: boo.com not defined/);

# progressively delete parts of the tree, and ensure the higher
# nodes get deleted if they are empty.
ok ($ret = $options->delete_from_rrset_order (
	NAME	=> 'extremix.net', 
	CLASS	=> 'IN', 
	TYPE	=> 'A'
));
$ret->die ("couldnt delete from rrset-order") unless ($ret);
# should get only one key now 'NS'
ok (keys (%{$ret = $options->get_rrset_order ('extremix.net', 'IN')}), 1);
ok ($_, qr/^(NS)$/)  for (keys (%$ret));
# now delete the other type defined for `extremix.net' 'IN'
# this should delete `extremix.net', 'IN'
ok ($ret = $options->delete_from_rrset_order (
	NAME	=> 'extremix.net', 
	CLASS	=> 'IN', 
	TYPE	=> 'NS'
));
$ret->die ("couldnt delete from rrset-order") unless ($ret);

# should get error now
ok ($ret = $options->get_rrset_order ('extremix.net', 'IN'), 
	qr /^get_rrset_order: IN not defined for extremix.net/);

# delete the only remaining class for 'extremix.net' and the name 
# should get deleted too.
ok ($ret = $options->delete_from_rrset_order (
	NAME	=> 'extremix.net', 
	CLASS	=> 'ANY', 
	TYPE	=> 'ANY'
));
$ret->die ("couldnt delete from rrset-order") unless ($ret);

# should get error now
ok ($ret = $options->get_rrset_order ('extremix.net', 'IN'),
	qr/^get_rrset_order: extremix.net not defined/);

# the only remaining name is `foo.com'. once deleted
# the option should get deleted all by itself.
ok ($ret = $options->delete_from_rrset_order (
	NAME	=> 'foo.com', 
	CLASS	=> 'IN', 
	TYPE	=> 'A'
));
$ret->die ("couldnt delete from rrset-order") unless ($ret);

# should get error now
ok ($ret = $options->get_rrset_order (), qr/^get_rrset_order: option not defined/);

# test delete_rrset_order

ok ($ret = $options->rrset_order (
	{
		NAME 	=> 'extremix.net',
		CLASS	=> 'IN',
		TYPE	=> 'A',
		ORDER	=> 'cyclic',
	},
	{
		NAME 	=> 'extremix.net',
		CLASS	=> 'IN',
		TYPE	=> 'NS',
		ORDER	=> 'cyclic',
	},
	{
		NAME 	=> 'extremix.net',
		CLASS	=> 'ANY',
		TYPE	=> 'ANY',
		ORDER	=> 'cyclic',
	},
	{
		NAME 	=> 'foo.com',
		CLASS	=> 'IN',
		TYPE	=> 'A',
		ORDER	=> 'cyclic',
	},
));
ok ($ret = $options->delete_rrset_order ('extremix.net', 'IN', 'A'));
$ret->die ("couldnt delete rrset-order") unless ($ret);
# should get only one key now 'NS'
ok (keys (%{$ret = $options->get_rrset_order ('extremix.net', 'IN')}), 1);
ok ($_, qr/^(NS)$/)  for (keys (%$ret));

# now delete the other type defined for `extremix.net' 'IN'
# this should delete `extremix.net', 'IN'
ok ($ret = $options->delete_rrset_order ('extremix.net', 'IN', 'NS'));
$ret->die ("couldnt delete rrset-order") unless ($ret);

# should get error now
ok ($ret = $options->get_rrset_order ('extremix.net', 'IN'), 
	qr/^get_rrset_order: IN not defined for extremix.net/);

# delete the only remaining class for 'extremix.net' and the name 
# should get deleted too.
ok ($ret = $options->delete_rrset_order ('extremix.net', 'ANY', 'ANY'));
$ret->die ("couldnt delete from rrset-order") unless ($ret);

# should get error now
ok ($ret = $options->get_rrset_order ('extremix.net', 'IN'), 
	qr /^get_rrset_order: extremix.net not defined/);

# the only remaining name is `foo.com'. once deleted
# the option should get deleted all by itself.
ok ($ret = $options->delete_rrset_order ('foo.com', 'IN', 'A'));
$ret->die ("couldnt delete from rrset-order") unless ($ret);

# should get error now
ok ($ret = $options->get_rrset_order (), qr/^get_rrset_order: option not defined/);

1;
