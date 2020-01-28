#
#===============================================================================
#
#         FILE: opts.t
#
#  DESCRIPTION: Check options
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 19/01/20 15:27:10
#===============================================================================

use strict;
use warnings;

use Test::More tests => 15;
use Test::Fatal;
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
  WebService::AbuseIPDB->new (key => $ENV{AIPDB_KEY}, timeout => 3, retry => 2,
	ver => 2);
is ($ipdb->{api_ver}, 2, 'Version is 2');
ok ($ipdb, 'Valid object with opts');
is ($ipdb->{retry},          2, 'Retry is 2');
is ($ipdb->{ua}->getTimeout, 3, 'Timeout is 3');

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
my $start = time ();
my $res   = $ipdb->check (ip => '1.1.1.1');
my $dur   = time () - $start;
ok (!$res->successful, 'Check failed (timed out)');
like (
	$res->errors->[0]->{detail},
	qr/could not connect/,
	'Error is "could not connect"'
);
TODO: {
	local $TODO = 'Bug: timeout acts twice';
	cmp_ok (abs (9 - $dur), '<', 2, 'Timeout seems OK')
	  or diag "Start: $start, Dur: $dur";
}

%MOCK = (
	code        => '200',
	contenttype => 'text/html; charset=utf-8'
);
$ipdb->{ua}->setHost ('https://www.w3.org/');
$res = $ipdb->check (ip => '1.1.1.1');
ok (!$res->successful, 'Check failed (not JSON)');
like (
	$res->errors->[0]->{detail},
	qr/could not connect/,
	'Error is "could not connect"'
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
