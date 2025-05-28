#
#===============================================================================
#
#         FILE: check-block.t
#
#  DESCRIPTION: Test the "check-block" endpoint
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 04/07/20 14:24:34
#===============================================================================

use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::Warn;
use JSON::MaybeXS;

my %mainmap = (
	network          => 'networkAddress',
	netmask          => 'netmask',
	min_addr         => 'minAddress',
	max_addr         => 'maxAddress',
	num_addr         => 'numPossibleHosts',
	usage_type       => 'addressSpaceDesc',
);

my %reportmap = (
	cc               => 'countryCode',
	score            => 'abuseConfidenceScore',
	report_count     => 'numReports',
#	whitelisted      => 'isWhitelisted',
#	isp              => 'isp',
	last_report_time => 'mostRecentReport',
#	usage_type       => 'usageType',
	ip               => 'ipAddress',
#	ipv              => 'ipVersion',
#	public           => 'isPublic',
#	domain           => 'domain',
#	reporter_count   => 'numDistinctUsers'
);

#plan tests => 10 + 2 * keys %map;

use WebService::AbuseIPDB;
use Data::Dumper;

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

# Check a good range
%MOCK = (
	contenttype => 'application/json',
	code        => 200,
	data        => {
		data => {
			networkAddress    => '127.0.0.0',
			netmask           => '255.255.255.248',
			minAddress        => '127.0.0.1',
			maxAddress        => '127.0.0.6',
			numPossibleHosts  => '6',
			addressSpaceDesc  => 'Loopback',
			reportedAddress   => [
				{
					ipAddress             => '127.0.0.1',
					numReports            => 39,
					mostRecentReport      => '2020-09-21T16:35:18+00:00',
					abuseConfidenceScore  => 3,
					countryCode           => undef
				},
				{
					ipAddress             => '127.0.0.2',
					numReports            => 7,
					mostRecentReport      => '2020-08-30T12:41:16+00:00',
					abuseConfidenceScore  => 1,
					countryCode           => undef
				},
			]
		}
	}
);
$res = $ipdb->check_block (ip => '127.0.0.0/29');
ok ($res,                'Results obtained');
ok ($res->successful,    'Method "success" returns true');
ok (exists $res->{data}, 'Has "data"');
my $data = $res->{data};

for my $key (values %mainmap) {
	ok (exists $data->{$key}, qq#Has "$key"#);
}
is ($data->{networkAddress},     '127.0.0.0', 'networkAddress value');
is ($data->{netmask},            '255.255.255.248', 'netmask value');
is ($data->{minAddress},         '127.0.0.1', 'minAddress value');
is ($data->{maxAddress},         '127.0.0.6', 'maxAddress value');
is ($data->{numPossibleHosts},   '6',         'numPossibleHosts value');
is ($data->{addressSpaceDesc},   'Loopback',  'addressSpaceDesc value')
	or diag Dumper $data;
while (my ($meth, $key) = each %mainmap) {
	is ($res->$meth, $data->{$key}, "Method '$meth' matches $key");
}

my $i = 0;
my @addresses = $res->reports;
for my $rep (@addresses) {
	$i++;
	isa_ok $rep, 'WebService::AbuseIPDB::ReportedAddress',
		"Address $i report";
	like $rep->ip, qr/^127\.0\.0\.\d$/, "Address $i: IP matches";
	cmp_ok $rep->report_count, '>', -1,
		"Address $i: Report count is whole number";
	like $rep->last_report_time, qr/\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\+00:00/,
		"Address $i: Report timestamp matches";
	cmp_ok $rep->score, '>', -1,
		"Address $i: Report score is whole number";
	is $rep->cc, undef, 'No country code for loopback';
}
my @duplicate = $res->reports;
is_deeply \@duplicate, \@addresses, 'Second call to reports shows no change';

# Check bad input
warnings_exist {$res = $ipdb->check_block ();}
	[(qr/No IP in argument hash/)],
	'Missing IP argument warned';
is ($res, undef, 'No IP provided');
$MOCK{code} = 422;
$MOCK{data} = {
		'errors' => [
			{
				'status' => 422,
				'detail' => 'The max age in days must be between 1 and 365.',
				'source' => {
					'parameter' => 'maxAgeInDays'
				}
			}
		]
	};
$res = $ipdb->check_block (ip => '127.0.0.0/24', max_age => 500);
ok (!$res->successful, 'Bad max_age unsuccessful');
my $err = $res->errors;
ok (defined $err, 'Has "errors"');
SKIP: {
	skip 'Oddly, no errors', 1 unless defined $err;
	is ($err->[0]->{status}, '422', 'Status code is 422');
	is ($err->[0]->{detail},
		'The max age in days must be between 1 and 365.',
		'Error msg is correct'
	);
}

done_testing ();

sub my_resp_cont {
	return encode_json (
		$MOCK{data} //
		{   data => {
				networkAddress            => '127.0.0.0',
				netmask            => '255.255.255.248',
				minAddress            => '127.0.0.1',
				maxAddress            => '127.0.0.6',
				numPossibleHosts            => '6',
				addressSpaceDesc  => 'Loopback',
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
