#
#===============================================================================
#
#         FILE: rt-132655.t
#
#  DESCRIPTION: Test the bug from RT 132655 agianst regression
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 19/05/2020
#===============================================================================

use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::Warn;
use JSON::MaybeXS;

plan tests => 5;

use WebService::AbuseIPDB;

# Must mock this as no other way to guarantee a 503.
my %MOCK;
my $mock = Test::MockModule->new ('REST::Client');
$mock->redefine ('GET', sub { 1; });
$mock->redefine ('responseContent', \&my_resp_cont);
$mock->redefine ('responseHeader',  \&my_resp_head);
$mock->redefine ('responseCode',    \&my_resp_code);

my $ipdb = WebService::AbuseIPDB->new (key => $ENV{AIPDB_KEY});
ok ($ipdb, 'Client object created');

%MOCK = (
	contenttype => 'application/json',
	code        => 503
);
my $res;
warnings_exist {$res = $ipdb->check (ip => '10.0.0.1', max_age => '75');}
	[(qr/REST error 503/)],
	'Error 503 warned';
ok ($res,                 'Results obtained');
ok (!$res->successful,    'Method "success" returns false');
ok (!exists $res->{data}, 'Has no "data"');

done_testing ();

sub my_resp_cont {
	return encode_json (
		{   body => {},
			data => {},
			meta => {
				statusMessage => '503 Service Unavailable',
				statusCode    => 1
			}
		}
	);
}

sub my_resp_head {
	my ($self, $head) = @_;
	return $MOCK{$head};
}

sub my_resp_code {
	return $MOCK{code};
}
