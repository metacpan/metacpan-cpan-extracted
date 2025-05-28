#
#===============================================================================
#
#         FILE: check.t
#
#  DESCRIPTION: Test the "check" endpoint
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 09/08/19 15:07:29
#===============================================================================

use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::Warn;
use JSON::MaybeXS;

my %map = (
	cc               => 'countryCode',
	score            => 'abuseConfidenceScore',
	report_count     => 'totalReports',
	whitelisted      => 'isWhitelisted',
	isp              => 'isp',
	last_report_time => 'lastReportedAt',
	usage_type       => 'usageType',
	ip               => 'ipAddress',
	ipv              => 'ipVersion',
	public           => 'isPublic',
	domain           => 'domain',
	reporter_count   => 'numDistinctUsers'
);

plan tests => 11 + 2 * keys %map;

use WebService::AbuseIPDB;

my $mock;
my %MOCK;
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

# Check a good IP
%MOCK = (
	contenttype => 'application/json',
	code        => 200
);
my $res = $ipdb->check (ip => '8.8.8.8', max_age => '75');
ok ($res,                'Results obtained');
ok ($res->successful,    'Method "success" returns true');
ok (exists $res->{data}, 'Has "data"');
my $data = $res->{data};

for my $key (values %map) {
	ok (exists $data->{$key}, qq#Has "$key"#);
}
is ($data->{ipAddress},            '8.8.8.8', 'ipAddress value');
is ($data->{ipVersion},            '4',       'ipVersion value');
is ($data->{abuseConfidenceScore}, '0',       'abuseConfidenceScore value');
is ($data->{usageType}, 'Data Center/Web Hosting/Transit', 'usageType value');
is ($data->{countryCode}, 'US', 'countryCode value');
while (my ($meth, $key) = each %map) {
	is ($res->$meth, $data->{$key}, "Method '$meth' matches $key");
}

# Check bad input
warnings_exist {$res = $ipdb->check ();}
	[qr/No IP in argument hash/],
	'Missing IP in check argument hash warned';
is ($res, undef, 'No IP provided');

done_testing ();

sub my_resp_cont {
	return encode_json (
		{   data => {
				ipAddress            => '8.8.8.8',
				ipVersion            => '4',
				abuseConfidenceScore => '0',
				usageType            => 'Data Center/Web Hosting/Transit',
				countryCode          => 'US',
				isPublic             => '1',
				domain               => 'google.com',
				numDistinctUsers     => '24',
				lastReportedAt       => '2020-01-19T21:04:46+00:00',
				totalReports         => '90',
				isWhitelisted        => '1',
				isp                  => 'Google',
			}
		}
	);
}

sub my_resp_head {
	my ($self, $head);
	return $MOCK{contenttype};
}

sub my_resp_code {
	return $MOCK{code};
}
