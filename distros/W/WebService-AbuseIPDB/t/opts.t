#
#===============================================================================
#
#         FILE: opts.t
#
#  DESCRIPTION: Check options and exceptions
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 19/01/20 15:27:10
#===============================================================================

use strict;
use warnings;

use Test::More tests => 16;
use Test::Fatal;
use Test::Warn;
use Test::MockModule;

use WebService::AbuseIPDB;

my $ipdb;
like (exception { $ipdb = WebService::AbuseIPDB->new (); },
	qr/No key/, 'Dies on missing key');
like (
	exception { $ipdb = WebService::AbuseIPDB->new (ver => 1); },
	qr/Only version 2 is supported/,
	'Dies on incorrect version'
);
is (exception { $ipdb = WebService::AbuseIPDB->new (key => $ENV{AIPDB_KEY}); },
	undef,
	'Valid object'
);
is ($ipdb->{api_ver},        2,  'Version default is 2');
is ($ipdb->{retry},          0,  'Retry default is 0');
is ($ipdb->{ua}->getTimeout, 20, 'Timeout default is 20');
$ipdb =
  WebService::AbuseIPDB->new (key => $ENV{AIPDB_KEY}, timeout => 2, retry => 1,
	ver => 2);
is ($ipdb->{api_ver}, 2, 'Version is 2');
ok ($ipdb, 'Valid object with opts');
is ($ipdb->{retry},          1, 'Retry is 1');
is ($ipdb->{ua}->getTimeout, 2, 'Timeout is 2');

my $mock;
my %MOCK;
if (defined $ENV{NO_NETWORK_TESTING}) {
	$mock = Test::MockModule->new ('REST::Client');
	$mock->redefine ('GET', sub { 1; });
	$mock->redefine ('responseContent', \&my_resp_cont);
	$mock->redefine ('responseHeader',  \&my_resp_head);
	$mock->redefine ('responseCode',    \&my_resp_code);
}

%MOCK = (code => '500');
$ipdb->{ua}->setHost ('http://abuseipdb.com:999/');
my $res;
my $start = time ();
warnings_exist {$res   = $ipdb->check (ip => '1.1.1.1');}
	[(qr/REST error 500/) x 2],
	'Error 500 warned';
my $dur   = time () - $start;
ok (!$res->successful, 'Check failed (timed out)');
like (
	$res->errors->[0]->{detail},
	$ENV{NO_NETWORK_TESTING} ? qr/Server Problem/ :
	qr/Can't connect to abuseipdb.com:999/,
	q/Connection failure warned/
);

# Give up on the timing tests for now as there are far too many
# variables: version of IO::Socket::IP, IPv4 yes/no, IPv6 yes/no,
# actually number of addresses in each family to which the host
# resolves, etc.
#TODO: {
#	local $TODO = 'Bug: timeout acts twice';
#	cmp_ok (abs (9 - $dur), '<', 2, 'Timeout seems OK')
#	  or diag "Start: $start, Dur: $dur";
#}

%MOCK = (
	code        => '200',
	contenttype => 'text/html; charset=utf-8'
);
$ipdb->{ua}->setHost ('https://duckduckgo.com/');
$res = $ipdb->check (ip => '1.1.1.1');
ok (!$res->successful, 'Check failed (not JSON)');
like (
	$res->errors->[0]->{detail},
	qr/could not connect/,
	q/Connection failure warned/
);

like (exception { $ipdb->_send_receive ('PUT', 'foo') },
	qr/Unrecognised method 'PUT'/,
	'Non GET/POST thrown'
);

done_testing ();

sub my_resp_cont {
	return '<html><body>Not JSON, you know.</body></html>'
	  unless $MOCK{code} eq '500';
	return;
}

sub my_resp_head {
	my ($self, $head);
	return $MOCK{contenttype};
}

sub my_resp_code {
	return $MOCK{code};
}
