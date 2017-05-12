use strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use CommonSubs;

my $config = CommonSubs::read_config();
if (not $config) {
	plan skip_all => 'Failed to read TEST_INFO.json. Please review README_TESTING.';
}

if (
	not (
		UNIVERSAL::isa($config, 'HASH') and
		$config->{api_url} and
		$config->{partner_api}->{partner_key}
	)
) {
	plan skip_all => 'Required partner parameters for partner tests are not setup in TEST_INFO.json. Please review README_TESTING.';
}

require_ok ( 'WWW::Codeguard' );
my $partner_api;
my $created_user_id;
my $created_plan_id;

subtest 'Partner API object creation' => sub {
	$partner_api = WWW::Codeguard->new(
		{
			api_url => $config->{api_url},
			partner => {
				partner_key => $config->{partner_api}->{partner_key},
				verify_hostname => 0,
			},
		}
	);

	ok ( defined ($partner_api) && UNIVERSAL::isa($partner_api, 'WWW::Codeguard::Partner'), 'Partner API object creation' );
	ok ( $partner_api->get_api_url(), 'Codeguard API url is present');
	ok ( $partner_api->get_partner_key(), 'Codeguard partner key is present');
} or plan skip_all => 'Failed to generate WWW::Codeguard::Partner object. Please ensure the information in TEST_INFO.json is valid.';

subtest 'Create new user' => sub {
	my $resp = $partner_api->create_user(
		{
			name  => 'WWW::Codeguard Test user'.substr(getppid, 0, 6),
			email => CommonSubs::random_str(12).'@'.CommonSubs::random_str(12).'.com',
		}
	);

	ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'create_user response was a hash' );
	if ( exists $resp->{error} or not (exists $resp->{user} and UNIVERSAL::isa($resp->{user}, 'HASH') ) ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Create new user';
	} else {
		ok ( $resp->{user}->{id}, 'Codeguard User ID was present' );
		ok ( $resp->{user}->{access_secret}, 'Codeguard Access Secret was present' );
		ok ( $resp->{user}->{access_token}, 'Codeguard Access Token was present' );
		ok ( $resp->{user}->{api_key}, 'Codeguard API Key was present' );
		ok ( $resp->{user}->{api_secret}, 'Codeguard API Secret was present' );
		$created_user_id = $resp->{user}->{id};
		$created_plan_id = $resp->{user}->{plan_id};
	}
} or plan skip_all => 'create_user call failed.';

subtest 'List user' => sub {
	my $resp = $partner_api->list_user(
		{
			user_id => $created_user_id,
		}
	);

	ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'list_user response was a hash' );
	if ( exists $resp->{error} or not (exists $resp->{user} and UNIVERSAL::isa($resp->{user}, 'HASH') ) ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'list user';
	} else {
		ok ( $resp->{user}->{id} eq $created_user_id, 'Codeguard User ID matched what we received on create user' );
		ok ( $resp->{user}->{plan_id} eq $created_plan_id, 'Codeguard Plan ID matched what we received on create user' );
		ok ( $resp->{user}->{name} eq 'WWW::Codeguard Test user'.substr(getppid, 0, 6), 'Name matched what we sent on create user' );
	}
};

subtest 'Change user plan' => sub {
	my $resp = $partner_api->change_user_plan(
		{
			user_id => $created_user_id,
			plan_id => $created_plan_id + 1,
		}
	);

	ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'change_user_plan response was a hash' );
	if ( exists $resp->{error} or not (exists $resp->{user} and UNIVERSAL::isa($resp->{user}, 'HASH') ) ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'change user plan';
	} else {
		ok ( $resp->{user}->{id} eq $created_user_id, 'Codeguard User ID matched what we received on create user' );
		ok ( $resp->{user}->{plan_id} eq $created_plan_id + 1, 'Codeguard Plan ID was updated successfully' );
		ok ( $resp->{user}->{name} eq 'WWW::Codeguard Test user'.substr(getppid, 0, 6), 'Name matched what we sent on create user' );
	}
};

subtest 'Delete created user' => sub {
	my $resp = $partner_api->delete_user(
		{
			user_id => $created_user_id,
		}
	);

	ok ( defined ($resp) && UNIVERSAL::isa($resp, 'HASH'), 'delete_user response was a hash' );
	if ( exists $resp->{error} ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Delete created user';
	}
	ok ( $resp->{message} eq '200', 'delete_user call was successful' );
};

done_testing;
