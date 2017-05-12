use strict;
use warnings;
use Test;

BEGIN { plan tests => 105 };

use Unix::Conf;
Unix::Conf->debuglevel (1);
use Unix::Conf::Bind8;

# ensure a blank file
`rm -f t/named.conf`;

my ($conf, $logging, $channel, $ret);
my @categories;

$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0,
);
ok ($conf->isa ("Unix::Conf::Bind8::Conf"));

$conf->die ("couldn't create `t/named.conf'") unless ($conf);

ok ($ret = $conf->get_logging (), qr/^_get_logging: `logging' not defined/);
ok ($ret = $conf->delete_logging (), qr/^_get_logging: `logging' not defined/);

$logging = $conf->new_logging (
		CHANNELS	=> [
	        {
                NAME             => 'my_file_chan',
                OUTPUT           => 'file',
                FILE             => {
				  PATH     		 => '/var/log/named/file_chan.log',
				  VERSIONS 		 => 3,
				  SIZE     		 => '10k',
                },
                SEVERITY         => { NAME => 'debug', LEVEL => '3' },
                'PRINT-TIME'     => 'yes',
                'PRINT-SEVERITY' => 'yes',
                'PRINT-CATEGORY' => 'yes'
            },
            {
                NAME             => 'my_syslog_chan',
                OUTPUT           => 'syslog',
                SYSLOG           => 'daemon',
                SEVERITY         => { NAME => 'info' },
                'PRINT-TIME'     => 'yes',
                'PRINT-SEVERITY' => 'yes',
                'PRINT-CATEGORY' => 'yes'
            },
			{	NAME			 => 'my_debug_chan',
				OUTPUT			 => 'file',
				FILE			 => {
					PATH		 => '/var/log/named/debug_chan.log',
					VERSIONS	 => 3,
					SIZE		 => '10m',
				},
				SEVERITY		 => { NAME => 'debug', LEVEL => 'dynamic' },
                'PRINT-TIME'     => 'yes',
                'PRINT-SEVERITY' => 'yes',
                'PRINT-CATEGORY' => 'yes'
			},
        ],
        CATEGORIES => [
            [ db                => [ qw (my_file_chan default_debug default_syslog) ] ],
            [ 'lame-servers'    => [ qw (null) ], ],
            [ cname             => [ qw (my_syslog_chan) ], ],
            ['xfer-out'         => [ qw (default_stderr my_debug_chan) ], ]
        ],
		WHERE	=> 'FIRST',
);

my @defined_channels = qw (my_file_chan my_syslog_chan my_debug_chan);

my %channels = (
	db				=> [ qw (my_file_chan default_debug default_syslog) ],
	'lame-servers'	=> [ qw (null) ],
	cname			=> [ qw (my_syslog_chan) ],
	'xfer-out'		=> [ qw (default_stderr my_debug_chan) ],
);

ok ($logging->isa ("Unix::Conf::Bind8::Conf::Logging"));
$logging->die ("couldnt create logging") unless ($logging);

ok (($channel = $logging->get_channel ('my_file_chan'))->isa ("Unix::Conf::Bind8::Conf::Logging::Channel"));
ok ($channel->name (), "my_file_chan");
ok ($channel->output (), 'file');
ok ($ret = $channel->file ());
$ret->die ("couldn't get file for `my_file_chan'")	unless ($ret);
ok ($ret->{PATH}, '/var/log/named/file_chan.log');
ok ($ret->{VERSIONS}, 3);
ok (lc ($ret->{SIZE}), '10k');
ok ($channel->print_time (), 'yes');
ok ($channel->print_severity (), 'yes');
ok ($channel->print_category (), 'yes');

# now test categories defined and channels defined for each of them.
local $" = "|";
ok ($_, qr/^(db|lame-servers|cname|xfer-out)$/) for (@categories = $logging->categories ());
for my $cat (@categories) {
	ok ($ret = $logging->category ($cat));
	$ret->die ("could not get channels for category `$cat'") unless ($ret);
	ok ($_, qr/^(@{$channels{$cat}})$/) for (@$ret);
}
ok ($_->name (), qr/^(@defined_channels)$/) for ($logging->channels ());

# write out, read in and test again.
($conf, $logging, $channel, $ret) = (undef) x 4;
$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0,
);
ok ($conf->isa ("Unix::Conf::Bind8::Conf"));
$conf->die ("couldn't create `t/named.conf'") unless ($conf);
ok (($logging = $conf->get_logging ())->isa ("Unix::Conf::Bind8::Conf::Logging"));
$logging->die ("couldnt get logging") unless ($logging);

ok (($channel = $logging->get_channel ('my_file_chan'))->isa ("Unix::Conf::Bind8::Conf::Logging::Channel"));
ok ($channel->name (), "my_file_chan");
ok ($channel->output (), 'file');
ok ($ret = $channel->file ());
$ret->die ("couldn't get file for `my_file_chan'")	unless ($ret);
ok ($ret->{PATH}, '/var/log/named/file_chan.log');
ok ($ret->{VERSIONS}, 3);
ok (lc ($ret->{SIZE}), '10k');
ok ($channel->print_time (), 'yes');
ok ($channel->print_severity (), 'yes');
ok ($channel->print_category (), 'yes');

ok ($_, qr/^(db|lame-servers|cname|xfer-out)$/) for (@categories = $logging->categories ());
for my $cat (@categories) {
	ok ($ret = $logging->category ($cat));
	$ret->die ("could not get channels for category `$cat'") unless ($ret);
	ok ($_, qr/^(@{$channels{$cat}})$/) for (@$ret);
}
ok ($_->name (), qr/^(@defined_channels)$/) for ($logging->channels ());



# test add_to_category and delete_from category

# add_to_category error handling
ok ($ret = $logging->add_to_category ('no_category', 'arg1', 'arg2'), 
	qr/^add_to_category: illegal category `no_category'/);
ok ($ret = $logging->add_to_category ('lame-servers', 'default_stderr', 'dont_exist'),
	qr/^__valid_channel: invalid channel `dont_exist'/);
ok ($ret = $logging->add_to_category ('lame-servers', 'default_stderr', 'null'),
	qr/^add_to_category: channel `null' already defined for lame-servers/);

ok ($ret = $logging->add_to_category ('lame-servers', 'default_stderr', 'default_debug', 'default_syslog'));
$ret->die ("couldn't add to category `lame-servers'") unless ($ret);

# test that add_to_category did succeed
$ret = $logging->category ('lame-servers');
$ret->die ("couldnt get channels for category `lame-servers'") unless ($ret);
ok (@$ret, 4);
ok ($_, qr/^(null|default_stderr|default_debug|default_syslog)$/) for (@$ret);

# write out, read in and test again.
($conf, $logging, $channel, $ret) = (undef) x 4;
$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0,
);
ok ($conf->isa ("Unix::Conf::Bind8::Conf"));
$conf->die ("couldn't create `t/named.conf'") unless ($conf);
ok (($logging = $conf->get_logging ())->isa ("Unix::Conf::Bind8::Conf::Logging"));
$logging->die ("couldnt get logging") unless ($logging);

# test that add_to_category did succeed
$ret = $logging->category ('lame-servers');
$ret->die ("couldnt get channels for category `lame-servers'") unless ($ret);
ok (@$ret, 4);
ok ($_, qr/^(null|default_stderr|default_debug|default_syslog)$/) for (@$ret);





# delete_from_category error handling
ok ($ret = $logging->delete_from_category ('no_category', 'arg1', 'arg2'),
	qr/^delete_from_category: illegal category `no_category'/);
ok ($ret = $logging->delete_from_category ('lame-servers', 'default_stderr', 'dont_exist'),
	qr/^__valid_channel: invalid channel `dont_exist'/);
ok ($ret = $logging->delete_from_category ('lame-servers', 'default_stderr', 'my_file_chan'),
	qr/^delete_from_category: channel `my_file_chan' not defined for lame-servers/);

# delete all channels for db and check that db is deleted.
ok ($ret = $logging->delete_from_category ('db', 'default_debug', 'default_syslog', 'my_file_chan'));
# test that it succeeded.
ok ($ret = $logging->category ('db'), qr/^category: category `db' not defined/);
ok ($_, qr/^(lame-servers|cname|xfer-out)$/) for ($logging->categories ());

# test delete category
ok ($ret = $logging->delete_category ('xfer-out'));
ok ($ret = $logging->category ('xfer-out'), qr/^category: category `xfer-out' not defined/);
ok ($_, qr/^(lame-servers|cname)$/) for ($logging->categories ());

# write out, read in and test again.
($conf, $logging, $channel, $ret) = (undef) x 4;
$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0,
);
ok ($conf->isa ("Unix::Conf::Bind8::Conf"));
$conf->die ("couldn't create `t/named.conf'") unless ($conf);
ok (($logging = $conf->get_logging ())->isa ("Unix::Conf::Bind8::Conf::Logging"));
$logging->die ("couldnt get logging") unless ($logging);

# test delete category
ok ($ret = $logging->category ('xfer-out'), qr/^category: category `xfer-out' not defined/);
ok ($_, qr/^(lame-servers|cname)$/) for ($logging->categories ());



# now test get_channel, delete_channel.

# get_channel error handling.
ok ($logging->get_channel ('does_not_exist'), qr/^_get_channel: channel `does_not_exist' not defined/);
# delete_channel error handling. my_syslog_chan still in use in cname.
ok ($ret = $logging->delete_channel ('my_syslog_chan'), qr/^delete: channel still in use, cannot delete/);
ok ($logging->get_channel ('my_syslog_chan')->categories (), 1);
$ret = undef;
@$ret = $logging->get_channel ('my_syslog_chan')->categories ();
ok ($_, qr/^/) for (@$ret);

# my_file_chan, my_debug_chan have been freed.
ok ($ret = $logging->delete_channel ('my_file_chan'));
$ret->die ("couldn't delete `my_file_chan'") unless ($ret);
ok ($ret = $logging->get_channel ('my_debug_chan')->delete ());
$ret->die ("couldn't delete `my_file_chan'") unless ($ret);
# check that only my_syslog_chan key now exists in the channels hash
ok ($_->name (), qr/^(my_syslog_chan)$/) for ($logging->channels ());

# write out, read in and test again.
($conf, $logging, $channel, $ret) = (undef) x 4;
$conf = Unix::Conf::Bind8->new_conf (
	FILE		=> 't/named.conf',
	SECURE_OPEN	=> 0,
);
ok ($conf->isa ("Unix::Conf::Bind8::Conf"));
$conf->die ("couldn't create `t/named.conf'") unless ($conf);
ok (($logging = $conf->get_logging ())->isa ("Unix::Conf::Bind8::Conf::Logging"));
$logging->die ("couldnt get logging") unless ($logging);

# check that only my_syslog_chan key now exists in the channels hash
ok ($_->name (), qr/^(my_syslog_chan)$/) for ($logging->channels ());
