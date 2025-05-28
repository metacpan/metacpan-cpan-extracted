#
#===============================================================================
#
#         FILE: blacklist.t
#
#  DESCRIPTION: Test the "blacklist" endpoint
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 11/02/20 14:18:03
#===============================================================================

use strict;
use warnings;

use Test::More tests => 25;
use Test::MockModule;
use Test::Warn;
use WebService::AbuseIPDB;

my ($res, $mock, %MOCK);
if (defined $ENV{NO_NETWORK_TESTING} || !defined $ENV{AIPDB_KEY}) {

	# Mock it
	$mock = Test::MockModule->new ('REST::Client');
	$mock->redefine ('GET', sub { 1; });
	$mock->redefine ('responseContent', \&my_resp_cont);
	$mock->redefine ('responseHeader',  \&my_resp_head);
	$mock->redefine ('responseCode',    \&my_resp_code);
}

my $ipdb = WebService::AbuseIPDB->new (key => $ENV{AIPDB_KEY});
ok ($ipdb, 'Client object created');

# Invalid args
%MOCK = (
	contenttype => 'application/json',
	code        => 200
);
warnings_exist {$res = $ipdb->blacklist (limit => 'foo');}
	[qr/limit must be a whole number/],
	'non-integer limit warned';
is ($res, undef, 'Limit must be an integer');
warnings_exist {$res = $ipdb->blacklist (limit => 0);}
	[qr/limit must be greater than zero/],
	'zero limit warned';
is ($res, undef, 'Limit must be > 0');
warnings_exist {$res = $ipdb->blacklist (min_abuse => 'foo');}
	[qr/min_abuse must be a whole number/],
	'non-integer min_abuse warned';
is ($res, undef, 'Minimum abuse score must be an integer');
warnings_exist {$res = $ipdb->blacklist (min_abuse => 10);}
	[qr/min_abuse is \d+ but must be greater than 24/],
	'Too low min_abuse warned';
is ($res, undef, 'Minimum abuse score must be > 24');
warnings_exist {$res = $ipdb->blacklist (min_abuse => 101);}
	[qr/min_abuse is \d+ but must be less than 100/],
	'Too high min_abuse warned';
is ($res, undef, 'Minimum abuse score must be < 101');

# Run it right
$res = $ipdb->blacklist (min_abuse => 99, limit => 3);
ok ($res,                'Results obtained');
ok ($res->successful,    'Method "success" returns true');
ok (exists $res->{data}, 'Has "data"');
my $when = $res->as_at;
ok ($when, 'as_at() returns true');
like ($when, qr/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d[+-]\d\d:\d\d$/,
	'as_at format OK');
my @list = $res->list;
is ($#list, 2, '3 IP addresses in the list');

my $item = $list[2];
my $ip = $item->ip;
my $score = $item->score;
like ($score, qr/^[0-9]+$/, 'Score is a whole number');
cmp_ok ($score, '<=', 100, 'Score is at most 100');
cmp_ok ($score, '>=', 99, 'Score is at least 99');
like ($ip, qr/^[0-9a-f:.]+$/, "IP $ip is plausibly an IP address");

# Default min_abuse
SKIP: {
	skip 'Only run blacklist once for "live" access', 4 unless $mock;
	$res = $ipdb->blacklist (limit => 3);
	ok ($res,                'Results obtained w/ default min_abuse');
	ok ($res->successful,    'Method "success" returns true');
	ok (exists $res->{data}, 'Has "data"');
	@list = $res->list;
	is ($#list, 2, '3 IP addresses in the list');
}

sub my_resp_cont {
	return (<<EOT
{
  "meta": {
    "generatedAt": "2018-12-21T16:00:04+00:00"
  },
  "data": [
    {
      "ipAddress": "5.188.10.179",
      "abuseConfidenceScore": 100
    },
    {
      "ipAddress": "185.222.209.14",
      "abuseConfidenceScore": 100
    },
    {
      "ipAddress": "191.96.249.183",
      "abuseConfidenceScore": 100
    }
  ]
}
EOT
	);
}

sub my_resp_head {
	my ($self, $head);
	return $MOCK{contenttype};
}

sub my_resp_code {
	return $MOCK{code};
}
