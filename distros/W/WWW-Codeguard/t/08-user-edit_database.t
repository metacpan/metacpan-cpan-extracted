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
		$config->{user_api}->{api_key} and
		$config->{user_api}->{api_secret} and
		$config->{user_api}->{access_secret} and
		$config->{user_api}->{access_token}
	)
) {
	plan skip_all => 'Required partner parameters for user tests are not setup in TEST_INFO.json. Please review README_TESTING.';
}

if (
	not (
		UNIVERSAL::isa($config->{edit_database}, 'HASH') and
		$config->{edit_database}->{database_id} and
		(
			$config->{edit_database}->{website_id} or
			$config->{edit_database}->{server_address} or
			$config->{edit_database}->{account} or
			$config->{edit_database}->{password} or
			$config->{edit_database}->{port} or
			$config->{edit_database}->{database_name} or
			$config->{edit_database}->{authentication_mode} or
			$config->{edit_database}->{server_account} or
			$config->{edit_database}->{server_password}
		)
	)
) {
	plan skip_all => 'Required partner parameters for edit_database tests are not setup in TEST_INFO.json. Please review README_TESTING.';
}

require_ok ( 'WWW::Codeguard' );
my $user_api;

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

my $old_values;
my $edit_params;

subtest 'Check existing database resource' => sub {
	my $resp = $user_api->list_databases;
	ok (defined $resp && UNIVERSAL::isa($resp, 'ARRAY'), 'list_databases response was an array' );
	if ( ok ( (not scalar ( grep { not UNIVERSAL::isa($_, 'HASH') } @{ $resp } )), 'response was an array of hashes' ) ) {
		my @databases = grep { $_->{database_backup}->{id} eq $config->{edit_database}->{database_id} } @{ $resp };
		if ( ok ( scalar @databases, 'Database resource with the database_id specified exists on the account' ) ) {
			$old_values = $databases[0];
		}
	} else {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'List database resources';
	}
};

subtest 'Edit database resource' => sub {
	if ( not UNIVERSAL::isa($old_values, 'HASH') ) {
		plan skip_all => 'Unable to find database_id specified';
	}
	$edit_params = {
		database_id => $config->{edit_database}->{database_id},
		( $config->{edit_database}->{website_id}? ( website_id => $config->{edit_database}->{website_id} ) : () ),
		( $config->{edit_database}->{server_address}? ( server_address => $config->{edit_database}->{server_address} ) : () ),
		( $config->{edit_database}->{account}? ( account => $config->{edit_database}->{account} ) : () ),
		( $config->{edit_database}->{password}? ( password => $config->{edit_database}->{password} ) : () ),
		( $config->{edit_database}->{port}? ( port => $config->{edit_database}->{port} ) : () ),
		( $config->{edit_database}->{database_name}? ( database_name => $config->{edit_database}->{database_name} ) : () ),
	};
	my $resp = $user_api->edit_database($edit_params);

	ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'edit_database response was a hash' );
	if ( exists $resp->{error} or not (exists $resp->{database_backup} and UNIVERSAL::isa($resp->{database_backup}, 'HASH') ) ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Edit database resource';
	} else {
		if ( $config->{edit_database}->{website_id} ) {
			ok ( $resp->{database_backup}->{website_id} eq $config->{edit_database}->{website_id}, 'Edit database - website_id updated successfully' );
		}
		if ( $config->{edit_database}->{server_address} ) {
			ok ( $resp->{database_backup}->{server_address} eq $config->{edit_database}->{server_address}, 'Edit database - server_address updated successfully' );
		}
		if ( $config->{edit_database}->{account} ) {
			ok ( $resp->{database_backup}->{account} eq $config->{edit_database}->{account}, 'Edit database - account updated successfully' );
		}
		if ( $config->{edit_database}->{password} ) {
			ok ( $resp->{database_backup}->{password} eq $config->{edit_database}->{password}, 'Edit database - password updated successfully' );
		}
		if ( $config->{edit_database}->{port} ) {
			ok ( $resp->{database_backup}->{port} eq $config->{edit_database}->{port}, 'Edit database - port updated successfully' );
		}
		if ( $config->{edit_database}->{database_name} ) {
			ok ( $resp->{database_backup}->{database_name} eq $config->{edit_database}->{database_name}, 'Edit database - database_name updated successfully' );
		}
	}
};

subtest "Resetting database resource" => sub {
	if ( not (UNIVERSAL::isa($old_values, 'HASH') and UNIVERSAL::isa($edit_params, 'HASH') ) ) {
		plan skip_all => 'Unable to find database_id specified';
	}
	foreach my $param (keys %{$edit_params}) {
		if (exists $old_values->{database_backup}->{$param}) {
			$edit_params->{$param} = $old_values->{database_backup}->{$param};
		}
	}
	my $resp = $user_api->edit_database($edit_params);

	ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'edit_database response was a hash' );
	if ( exists $resp->{error} or not (exists $resp->{database_backup} and UNIVERSAL::isa($resp->{database_backup}, 'HASH') ) ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Reset website resource';
	} else {
		pass 'Reset website resource';
	}
};

done_testing;
