#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Deep;
#use Test::Warn;

plan tests => 9;

use WWW::Gittip;

# 123  or  123.3  or 123.45
my $MONEY = re('\d+(\.\d\d?)?$');

# like MONEY but can also accept - at the beginning
my $NMONEY = re('-?\d+(\.\d\d?)?$');

# '2012-06-15'
my $DATE = re('^\d\d\d\d-\d\d-\d\d$'),

# '2012-06-15T11:09:54.298416+00:00'
my $TIMESTAMP = re('^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d+\+\d\d:\d\d$');

# 123
my $INT = re('^\d+$');

my $USERNAME = re('^[\w .-]+$');

my $gt = WWW::Gittip->new;
isa_ok $gt, 'WWW::Gittip';

subtest charts => sub {
	plan tests => 1;
	my $chart_entry = {
		"active_users" => re('^\d+$'),
		"charges"      => $MONEY,
		"date"         => $DATE,
		"total_gifts"  => $MONEY,
		"total_users"  => re('^\d+$'),
		"weekly_gifts" => $MONEY,
		"withdrawals"  => $MONEY, 
	};

	my $charts = $gt->charts();
	#diag scalar @$charts;
	cmp_deeply($charts, array_each($chart_entry), 'charts');
};

subtest user_chars => sub {
	plan tests => 3;
	my $charts_user = $gt->user_charts('szabgab');
	#diag scalar @$charts_user;
	#diag explain $charts_user;
	my $user_chart_entry_old = {
		'date'     => $DATE,
		'npatrons' => re('^\d+$'),
		'receipts' => $MONEY,
	};
	my $user_chart_entry_new = {
		'date'     => $DATE,
		'npatrons' => re('^\d+$'),
		'receipts' => $MONEY,
		'ts_start' => $TIMESTAMP,
	};
	my $user_chart_entry = any($user_chart_entry_old, $user_chart_entry_new);

	#diag explain $charts_user->[0];
	#cmp_deeply $charts_user->[0], $user_chart_entry_old;
	#cmp_deeply $charts_user->[0], $user_chart_entry_new;
	#cmp_deeply $charts_user->[0], any($user_chart_entry_old, $user_chart_entry_new);
	#cmp_deeply $charts_user->[0], $user_chart_entry;
	
	cmp_deeply($charts_user, array_each($user_chart_entry), 'user_charts');

	my $invalid;
	{
		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		$invalid = $gt->user_charts('a/b');
		$_ =~ s/[\r\n]*$// for @warnings;
		#diag explain \@warnings;
		is_deeply \@warnings, [
			q{Failed request https://www.gratipay.com/a/b/charts.json},
			q{404 Not Found},
		], 'expected warnings';
	}
	#warnings_are { $invalid = $gt->user_charts('a/b') } [
	#	qq{Failed request https://www.gratipay.com/a/b/charts.json},
	#	qq{404 Not Found},
	#], 'expected warnings';
	cmp_deeply $invalid, [], 'invalid requets';
};

subtest communities => sub {
	plan tests => 1;
	my $empty = $gt->communities;
	#diag explain $data;
	cmp_deeply $empty, {
		'communities' => []
	};
};

subtest user_public => sub {
	plan tests => 3+4;
	my $pub = $gt->user_public('szabgab');
	#diag explain $pub;
	is $pub->{username}, 'szabgab', 'username';
	is $pub->{id},       25031,     'id';
	is $pub->{on},       'gratipay',  'on';
	foreach my $f (qw(giving receiving)) {
		ok exists $pub->{$f};
		if (defined $pub->{$f}) {
			cmp_deeply $pub->{$f}, $MONEY, $f;
		} else {
			is $pub->{$f}, undef, $f;
		}
	}
	#cmp_deeply $pub->{giving},    any($MONEY, undef), 'giving';
	#cmp_deeply $pub->{receiving}, any($MONEY, undef), 'receiving';
};

subtest paydays => sub {
	plan tests => 1;


	my $expected_payday = {
		'ach_fees_volume'    => $MONEY,
		'ach_volume'         => $NMONEY,
		'charge_fees_volume' => $MONEY,
		'charge_volume'      => $MONEY,
		'nachs'              => $INT,
		'nactive'            => $INT, 
		'ncc_failing'        => $INT,
		'ncc_missing'        => $INT,
		'ncharges'           => $INT,
		'nparticipants'      => $INT,
		'ntransfers'         => $INT,
		'ntippers'           => $INT,
		'transfer_volume'    => $MONEY,
		'ts_end'             => $TIMESTAMP,
		'ts_start'           => $TIMESTAMP,
	};

	my $paydays = $gt->paydays();
	cmp_deeply($paydays, array_each($expected_payday), 'paydays');
	#diag explain $paydays;
};

subtest stats => sub {
	plan tests => 4+7;

	my $stats = $gt->stats();
	#diag explain $stats;
	foreach my $f (qw(average_tip escrow total_backed_tips transfer_volume)) {
    	cmp_deeply $stats->{$f}, $MONEY, $f;
	}
    foreach my $f (qw(tip_n nach nactive ncc ngivers noverlap nreceivers)) {
    	cmp_deeply $stats->{$f}, $INT, $f;
	}
};

subtest community_members => sub {
	plan tests => 4;
	my $members = $gt->community_members('perl');
	my $expected = {
		name => $USERNAME,
	};
	cmp_ok scalar @{ $members->{new} }, '>', 500;
	cmp_deeply($members->{new},     array_each($expected));
	cmp_deeply($members->{give},    array_each($expected));
	cmp_deeply($members->{receive}, array_each($expected));
};


subtest api_key => sub {
	my $config = get_config();
	if ($config->{api_key}) {
		plan tests => 2;
	} else {
		plan skip_all => 'API_KEY is needed';
	}

	# If user is logged in, the method returns a list of all the communities.
	$gt->api_key($config->{api_key});
	my $communities = $gt->communities;

	#diag explain $communities;
	my $expected_community = {
		#'is_member' => isa('JSON::PP::Boolean'),
		'name'      => re('^[\w., -]+$'),
		'nmembers'  => re('^\d+$'),
		'slug'      => re('^[\w-]+$'),
		'ctime'     => $TIMESTAMP,
	};
	#cmp_deeply($communities->{communities}[0], $expected_community);
	cmp_deeply($communities->{communities}, array_each($expected_community));

	my $tips = $gt->user_tips($config->{username});
	my $expected_tip = {
		'username' => $USERNAME,
		'platform' => 'gittip',
		'amount'   => $MONEY,
	};

	cmp_deeply($tips, array_each($expected_tip));
};

exit;



sub get_config {
	my $gittiprc = "$ENV{HOME}/.gittip";
	#die if not -e $gittiprc;
	my %config;
	if (open my $fh, '<', $gittiprc) {
		while (my $row = <$fh>) {
			chomp $row;
			my ($field, $key) = split /=/,  $row;
			$config{$field} = $key;
		}
	}
	return \%config;
}

