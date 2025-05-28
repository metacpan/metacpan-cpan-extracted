#
#===============================================================================
#
#         FILE: errors.t
#
#  DESCRIPTION: Test errors
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 02/07/20 23:30:24
#===============================================================================

use strict;
use warnings;

use Test::More;
use Test::MockModule 'strict';
use Test::Warn;
use JSON::MaybeXS;

plan tests => 21;

use WebService::AbuseIPDB;

my %MOCK;
my $mock = Test::MockModule->new ('REST::Client');
mock_now ($mock) if defined $ENV{NO_NETWORK_TESTING};

my $ipdb = WebService::AbuseIPDB->new (key => 'ABCD987');
ok ($ipdb, 'Client object created');

%MOCK = (
	'Content-type' => 'application/json',
	code           => 401
);
my $res = $ipdb->check (ip => '10.0.0.1', max_age => '75');
ok ($res,                 'Results obtained');
ok (!$res->successful,    'Method "success" returns false');
ok (!exists $res->{data}, 'Has no "data"');
is ($res->errors->[0]->{status}, '401', 'Returns 401');

my $now = time;
$ipdb->{ua}->setHost ("https://$now.example.com/");
$MOCK{code} = 500;

warnings_exist {$res = $ipdb->check (ip => '10.0.0.1', max_age => '75');}
	[qr/REST error 500/],
	'500 error warned';
ok ($res,                 'Results obtained');
ok (!$res->successful,    'Method "success" returns false');
ok (!exists $res->{data}, 'Has no "data"');

$MOCK{code} = 400;
mock_now ($mock);

try_400 ($res, $ipdb);
$MOCK{badcontent} = 'Client error';
try_400 ($res, $ipdb);
$MOCK{'Client-Warning'} = 'Internal error';
try_400 ($res, $ipdb);

done_testing ();

sub try_400 {
	my ($res, $ipdb) = @_;
	warnings_exist { $res = $ipdb->check (ip => '10.0.0.1', max_age => '75'); }
	[qr/REST error 400/, qr/Problem with GET/], '400 error warned';
	ok ($res,                 'Results obtained');
	ok (!$res->successful,    'Method "success" returns false');
	ok (!exists $res->{data}, 'Has no "data"');
}

sub my_resp_cont {
	my $json = {body => {},};
	if ($MOCK{code} == 401) {
		$json->{errors} = [
			{   detail => 'Authentication failed. You are either missing '
				  . 'your API key or it is incorrect. Note: The APIv2 key '
				  . 'differs from the APIv1 key.',
				status => $MOCK{code},
			}
		];
	} elsif ($MOCK{code} == 400) {
		if ($MOCK{badcontent}) {
			$json->{errors} = [
				{   detail => "400 Bad Request: $MOCK{badcontent}",
					status => 400
				}
			];
		} else {
			return undef;
		}
	}
	return encode_json ($json);
}

sub my_resp_head {
	my ($self, $head) = @_;
	return $MOCK{$head};
}

sub my_resp_code {
	return $MOCK{code};
}

sub mock_now {
	my $mock = shift;

	# Mock it
	$mock = Test::MockModule->new ('REST::Client');
	$mock->redefine ('GET',             sub { 1; });
	$mock->redefine ('responseContent', \&my_resp_cont);
	$mock->redefine ('responseHeader',  \&my_resp_head);
	$mock->redefine ('responseCode',    \&my_resp_code);
}
