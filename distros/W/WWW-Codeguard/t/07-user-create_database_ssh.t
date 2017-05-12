use strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use CommonSubs;

plan skip_all => 'SSH tests are currently disabled, as the calls are not fully functional on the Codeguard API';

my $config = CommonSubs::read_config();
if (not $config) {
	plan skip_all => 'Failed to read TEST_INFO.json. Please review README_TESTING.';
}

if (
	not (
		UNIVERSAL::isa($config, 'HASH') and
		$config->{api_url} and
		$config->{user_api}->{api_key} and
		$config->{user_api}->{api_secret} and
		$config->{user_api}->{access_secret} and
		$config->{user_api}->{access_token}
	)
) {
	plan skip_all => 'Required partner parameters for user tests are not setup in TEST_INFO.json. Please review README_TESTING.';
}

require_ok ( 'WWW::Codeguard' );
my $user_api;
my $created_database_id;
my $created_database_website_id;

subtest 'User API object creation' => sub {
	$user_api = WWW::Codeguard->new(
		{
			api_url => $config->{api_url},
			user => {
				api_key         => $config->{user_api}->{api_key},
				api_secret      => $config->{user_api}->{api_secret},
				access_secret   => $config->{user_api}->{access_secret},
				access_token    => $config->{user_api}->{access_token},
				verify_hostname => 0,
			},
		}
	);

	ok ( defined ($user_api) && UNIVERSAL::isa($user_api, 'WWW::Codeguard::User'), 'User API object creation' );
	ok ( $user_api->get_api_url(), 'Codeguard API url was present');
	ok ( $user_api->get_api_secret(), 'Codeguard API secret was present');
	ok ( $user_api->get_api_key(), 'Codeguard API key was present');
	ok ( $user_api->get_access_secret(), 'Codeguard Access secret was present');
	ok ( $user_api->get_access_token(), 'Codeguard Access token was present');
} or plan skip_all => 'Failed to generate WWW::Codeguard::User object. Please ensure the information in TEST_INFO.json is valid';

subtest 'Create Database Resource using the SSH authentication method' => sub {
	if (
		not (
			UNIVERSAL::isa($config->{create_database}, 'HASH') and
			$config->{create_database}->{mysql_username} and
			$config->{create_database}->{mysql_password} and
			$config->{create_database}->{server_name} and
			$config->{create_database}->{database_name} and
			$config->{create_database}->{ssh_username} and
			$config->{create_database}->{ssh_password}
		)
	) {
		plan skip_all => 'Required partner parameters for create_database_ssh tests are not setup in TEST_INFO.json. Please review README_TESTING.';
	}

	my $resp = $user_api->create_database(
		{
			account         => $config->{create_database}->{mysql_username},
			password        => $config->{create_database}->{mysql_password},
			database_name   => $config->{create_database}->{database_name},
			server_address  => $config->{create_database}->{server_name},
			server_account  => $config->{create_database}->{ssh_username},
			server_password => $config->{create_database}->{ssh_password},
			authentication_mode => 'ssh',
			( $config->{create_database}->{mysql_port}? ( port => $config->{create_database}->{mysql_port} ) : ( port => 3306 ) ),
		}
	);

	ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'create_database response was a hash' );
	if ( exists $resp->{error} or not (exists $resp->{database_backup} and UNIVERSAL::isa($resp->{database_backup}, 'HASH') ) ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Create database resource';
	} else {
		ok ( $resp->{database_backup}->{id}, 'Codeguard Database ID is present' );
		ok ( $resp->{database_backup}->{database_name} eq $config->{create_database}->{database_name}, 'Database resource name is correct' );
		ok ( $resp->{database_backup}->{server_address} eq $config->{create_database}->{server_name}, 'Database resource hostname is correct' );
		ok ( $resp->{database_backup}->{account} eq $config->{create_database}->{mysql_username}, 'Database resource account is correct' );
		ok ( $resp->{database_backup}->{authentication_mode} eq 'direct', 'Database resource authentication_mode is correct' );
		$created_database_id = $resp->{database_backup}->{id};
		$created_database_website_id = $resp->{database_backup}->{website_id};
	}
};

subtest 'List databases in the CG account' => sub {
	my $resp = $user_api->list_databases();

	ok (defined $resp && UNIVERSAL::isa($resp, 'ARRAY'), 'list_databases response was an array' );
	if ( ok ( (not scalar ( grep { not UNIVERSAL::isa($_, 'HASH') } @{ $resp } )), 'response was an array of hashes' ) ) {
		if ( $created_database_id ) {
			ok ( scalar ( grep { $_->{database_backup}->{id} eq $created_database_id } @{ $resp } ), 'Database resource we created was present on the CG database list' );
		}
	} else {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'List website resources';
	}
};

subtest 'Show created database' => sub {
	if ( not ($created_database_id and $created_database_website_id) ) {
		pass 'Show created database resource skipped';
		return;
	}

	my $resp = $user_api->show_database(
		{
			database_id => $created_database_id,
			website_id  => $created_database_website_id,
		}
	);

	if ( ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'show_database response was a hash' ) ) {
		ok ( $resp->{database_backup}->{id} eq $created_database_id, 'Codeguard Database ID matches what we created' );
		ok ( $resp->{database_backup}->{website_id} eq $created_database_website_id, 'Codeguard Database website id matches what we created' );
	} else {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'List website resource rules';
	}
};

subtest 'Disable created database resource' => sub {
	if (not $created_database_id) {
		pass 'Disable created database resource skipped';
		return;
	}

	my $resp = $user_api->disable_database(
		{
			database_id => $created_database_id,
		}
	);

	ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'disable_database response was a hash' );
	if ( exists $resp->{error} or not (exists $resp->{database_backup} and UNIVERSAL::isa($resp->{database_backup}, 'HASH') ) ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Disable website resource';
	} else {
		ok ( $resp->{database_backup}->{id} eq $created_database_id, 'Codeguard Database ID matched what we received on create user' );
		ok ( $resp->{database_backup}->{database_name} eq $config->{create_database}->{database_name}, 'Database resource name is correct' );
		ok ( $resp->{database_backup}->{server_address} eq $config->{create_database}->{server_name}, 'Database resource hostname is correct' );
		ok ( $resp->{database_backup}->{account} eq $config->{create_database}->{mysql_username}, 'Database resource account is correct' );
		ok ( $resp->{database_backup}->{disabled} eq JSON::true, 'Database resource is disabled' );
	}
};

subtest 'Enable created database resource' => sub {
	if (not $created_database_id) {
		pass 'Enable created database resource skipped';
		return;
	}

	my $resp = $user_api->enable_database(
		{
			database_id => $created_database_id,
		}
	);

	ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'enable_database response was a hash' );
	if ( exists $resp->{error} or not (exists $resp->{database_backup} and UNIVERSAL::isa($resp->{database_backup}, 'HASH') ) ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Create website resource';
	} else {
		ok ( $resp->{database_backup}->{id} eq $created_database_id, 'Codeguard Database ID matched what we received on create user' );
		ok ( $resp->{database_backup}->{database_name} eq $config->{create_database}->{database_name}, 'Database resource name is correct' );
		ok ( $resp->{database_backup}->{server_address} eq $config->{create_database}->{server_name}, 'Database resource hostname is correct' );
		ok ( $resp->{database_backup}->{account} eq $config->{create_database}->{mysql_username}, 'Database resource account is correct' );
		ok ( $resp->{database_backup}->{disabled} eq JSON::false, 'Database resource is enabled' );
	}
};

subtest 'Delete created database resource' => sub {
	if (not $created_database_id) {
		pass 'Delete created database resource skipped';
		return;
	}

	my $resp = $user_api->delete_database(
		{
			database_id => $created_database_id,
		}
	);

	ok ( defined ($resp) && UNIVERSAL::isa($resp, 'HASH'), 'delete_database response was a hash' );
	if ( exists $resp->{error} ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Delete created user';
	}
	ok ( $resp->{message} eq '200', 'delete_website call was successful' );
};

done_testing;