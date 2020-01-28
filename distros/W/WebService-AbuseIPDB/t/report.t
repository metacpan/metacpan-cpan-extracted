#
#===============================================================================
#
#         FILE: report.t
#
#  DESCRIPTION: Test the "report" endpoint
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 16/08/19 16:54:26
#===============================================================================

use strict;
use warnings;

use Test::More;
use Test::MockModule;
use JSON::XS;

use WebService::AbuseIPDB;

my %map = (
	score => 'abuseConfidenceScore',
	ip    => 'ipAddress'
);
plan tests => 12 + 2 * keys %map;

my $mock;
my %MOCK;
if (defined $ENV{NO_NETWORK_TESTING} || !defined $ENV{AIPDB_KEY}) {

	# Mock it
	$mock = Test::MockModule->new ('REST::Client');
	$mock->redefine ('POST', sub { 1; });
	$mock->redefine ('responseContent', \&my_resp_cont);
	$mock->redefine ('responseHeader',  \&my_resp_head);
	$mock->redefine ('responseCode',    \&my_resp_code);
}

my $ipdb = WebService::AbuseIPDB->new (key => $ENV{AIPDB_KEY});
ok ($ipdb, 'Client object created');

# Bad reports - Check the diagnostics from these
my $res = $ipdb->report (ip => '8.8.8.8');
ok (!$res, 'Categories missing');
$res = $ipdb->report (categories => [4, 5]);
ok (!$res, 'IP missing');
%MOCK = (
	response => {
		errors => [
			{   detail => 'The categories field is required.',
				status => '422',
				source => {parameter => 'categories'}
			}
		]
	},
	contenttype => 'application/json',
	code        => '429'
);
$res = $ipdb->report (ip => '127.0.0.2', categories => [46, 55]);
ok (!$res->successful, 'Bad categories');
my $err = $res->errors;
ok (defined $err, 'Has "errors"');
SKIP: {
	skip 'Oddly, no errors', 1 unless defined $err;
	is ($err->[0]->{status}, '422', 'Status code is 422');
	is ($err->[0]->{detail},
		'The categories field is required.',
		'Error msg is correct'
	);
}

my $classc = '127.';
{
	my @lt = localtime (time);
	$classc .= "$lt[1].$lt[0].";
}
my $iter = 2;

%MOCK = (
	response => {
		data => {
			ipAddress            => $classc . $iter,
			abuseConfidenceScore => '6',
		}
	},
	contenttype => 'application/json',
	code        => '200'
);

$res = $ipdb->report (
	ip         => $classc . $iter,
	categories => [7, 11],
	comment    => 'Just testing WebService::AbuseIPDB'
);
ok ($res->successful,    'Method "successful" returns true');
ok (exists $res->{data}, 'Has "data"');
my $data = $res->{data};

for my $key (values %map) {
	ok (exists $data->{$key}, qq#Has "$key"#);
}
while (my ($meth, $key) = each %map) {
	is ($res->$meth, $data->{$key}, "Method '$meth' matches $key");
}

# Bad report for duplicate
%MOCK = (
	response => {
		errors => [
			{   detail =>
				  'You can only report the same IP address (`127.0.0.2`)' .
				  ' once in 15 minutes.',
				status => '429',
				source => {parameter => 'ip'}
			}
		]
	},
	contenttype => 'application/json',
	code        => '429'
);

$res = $ipdb->report (ip => $classc . $iter, categories => [7, 11]);
ok (!$res->successful, 'Method "successful" returns false');
$err = $res->errors;
ok (defined $err, 'Has "errors"');
SKIP: {
	skip 'Oddly, no errors', 1 unless defined $err;
	is ($err->[0]->{status}, '429', 'Status code is 429');
}

done_testing ();

sub my_resp_cont {
	return encode_json ($MOCK{response});
}

sub my_resp_head {
	my ($self, $head);
	return $MOCK{contenttype};
}

sub my_resp_code {
	return $MOCK{code};
}

