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

require_ok ( 'WWW::Codeguard' );
my $user_api;
my $created_website_id;

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
} or plan skip_all => 'Failed to generate WWW::Codeguard::User object. Please ensure the information in TEST_INFO.json is valid.';

subtest 'Create Website Resource with password using SFTP' => sub {
	if (
		not (
			UNIVERSAL::isa($config->{create_website}, 'HASH') and
			$config->{create_website}->{domain_name} and
			$config->{create_website}->{server_name} and
			$config->{create_website}->{username} and
			$config->{create_website}->{password}
		)
	) {
		plan skip_all => 'Required partner parameters for create_website, with a password using SFTP, tests are not setup in TEST_INFO.json. Please review README_TESTING.';
	}

	my $resp = $user_api->create_website(
		{
			url      => $config->{create_website}->{domain_name},
			hostname => $config->{create_website}->{server_name},
			account  => $config->{create_website}->{username},
			password => $config->{create_website}->{password},
			provider => 'sftp',
			( $config->{create_website}->{ssh_port}? ( port => $config->{create_website}->{ssh_port} ) : () ),
		}
	);

	ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'create_website response was a hash' );
	if ( exists $resp->{error} or not (exists $resp->{website} and UNIVERSAL::isa($resp->{website}, 'HASH') ) ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Create website resource';
	} else {
		ok ( $resp->{website}->{id}, 'Codeguard Website ID is present' );
		ok ( $resp->{website}->{hostname} eq $config->{create_website}->{server_name}, 'Website resource hostname is correct' );
		ok ( $resp->{website}->{account} eq $config->{create_website}->{username}, 'Website resource account is correct' );
		ok ( $resp->{website}->{url} eq $config->{create_website}->{domain_name}, 'Website resource url is correct' );
		ok ( $resp->{website}->{provider} eq 'sftp', 'Website resource provider is correct' );
		$created_website_id = $resp->{website}->{id};
	}
};

subtest 'Delete created website resource with password via SFTP' => sub {
	if (not $created_website_id) {
		pass 'Delete created website resource with password via SFTP skipped';
		return;
	}

	my $resp = $user_api->delete_website(
		{
			website_id => $created_website_id,
		}
	);

	ok ( defined ($resp) && UNIVERSAL::isa($resp, 'HASH'), 'delete_website response was a hash' );
	if ( exists $resp->{error} ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Delete created user';
	}
	ok ( $resp->{message} eq '200', 'delete_website call was successful' );
	undef $created_website_id;
};

subtest 'Create Website Resource with SSH key using SFTP' => sub {
	if (
		not (
			UNIVERSAL::isa($config->{create_website}, 'HASH') and
			$config->{create_website}->{domain_name} and
			$config->{create_website}->{server_name} and
			$config->{create_website}->{username} and
			$config->{create_website}->{ssh_key}
		)
	) {
		plan skip_all => 'Required partner parameters for create_website, with a SSH key using SFTP, tests are not setup in TEST_INFO.json. Please review README_TESTING.';
	}

	my $resp = $user_api->create_website(
		{
			url      => $config->{create_website}->{domain_name},
			hostname => $config->{create_website}->{server_name},
			account  => $config->{create_website}->{username},
			key      => $config->{create_website}->{ssh_key},
			provider => 'sftp',
			( $config->{create_website}->{ssh_port}? ( port => $config->{create_website}->{ssh_port} ) : () ),
		}
	);

	ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'create_website response was a hash' );
	if ( exists $resp->{error} or not (exists $resp->{website} and UNIVERSAL::isa($resp->{website}, 'HASH') ) ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Create website resource';
	} else {
		ok ( $resp->{website}->{id}, 'Codeguard Website ID is present' );
		ok ( $resp->{website}->{hostname} eq $config->{create_website}->{server_name}, 'Website resource hostname is correct' );
		ok ( $resp->{website}->{account} eq $config->{create_website}->{username}, 'Website resource account is correct' );
		ok ( $resp->{website}->{url} eq $config->{create_website}->{domain_name}, 'Website resource url is correct' );
		ok ( $resp->{website}->{provider} eq 'sftp', 'Website resource provider is correct' );
		$created_website_id = $resp->{website}->{id};
	}
};

subtest 'List websites in the CG account' => sub {
	my $resp = $user_api->list_websites();

	ok (defined $resp && UNIVERSAL::isa($resp, 'ARRAY'), 'list_websites response was an array' );
	if ( ok ( (not scalar ( grep { not UNIVERSAL::isa($_, 'HASH') } @{ $resp } )), 'response was an array of hashes' ) ) {
		if ( $created_website_id ) {
			ok ( scalar ( grep { $_->{website}->{id} eq $created_website_id } @{ $resp } ), 'Website resource we created was present on the CG website list' );
		}
	} else {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'List website resources';
	}
};

subtest 'List website rules in the CG account' => sub {
	my $resp = $user_api->list_website_rules(
		{
			website_id => $created_website_id,
		}
	);

	if ( ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'list_website_rules response was a hash' ) ) {
		ok ( UNIVERSAL::isa($resp->{exclude_rules}, 'ARRAY'), 'exclude_rules were present' );
	} else {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'List website resource rules';
	}
};

subtest 'Set website exclude rules in the CG account' => sub {
	my $resp = $user_api->set_website_rules(
		{
			website_id => $created_website_id,
			exclude_rules => [ '*'.substr(getppid, 0, 6).'/*' ],
		}
	);

	if ( ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'list_website_rules response was a hash' ) ) {
		if ( ok ( UNIVERSAL::isa($resp->{exclude_rules}, 'ARRAY'), 'exclude_rules were present' ) ) {
			ok ( scalar ( grep { $_ eq '*'.substr(getppid, 0, 6).'/*' } @{ $resp->{exclude_rules} } ), 'exclude rules were updated properly' )
		}
	} else {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'List website resource rules';
	}
};

subtest 'Disable created website resource' => sub {
	if (not $created_website_id) {
		pass 'Disable created website resource with a password via FTP skipped';
		return;
	}

	my $resp = $user_api->disable_website(
		{
			website_id => $created_website_id,
		}
	);

	ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'disable_website response was a hash' );
	if ( exists $resp->{error} or not (exists $resp->{website} and UNIVERSAL::isa($resp->{website}, 'HASH') ) ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Disable website resource';
	} else {
		ok ( $resp->{website}->{id} eq $created_website_id, 'Codeguard website ID matched what we received on create user' );
		ok ( $resp->{website}->{hostname} eq $config->{create_website}->{server_name}, 'Website resource hostname was correct' );
		ok ( $resp->{website}->{account} eq $config->{create_website}->{username}, 'Website resource account was correct' );
		ok ( $resp->{website}->{url} eq $config->{create_website}->{domain_name}, 'Website resource url was correct' );
		ok ( $resp->{website}->{disabled} eq JSON::true, 'Website resource is disabled' );
	}
};

subtest 'Enable created website resource' => sub {
	if (not $created_website_id) {
		pass 'Enable created website resource with a password via FTP skipped';
		return;
	}

	my $resp = $user_api->enable_website(
		{
			website_id => $created_website_id,
		}
	);

	ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'enable_website response was a hash' );
	if ( exists $resp->{error} or not (exists $resp->{website} and UNIVERSAL::isa($resp->{website}, 'HASH') ) ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Create website resource';
	} else {
		ok ( $resp->{website}->{id} eq $created_website_id, 'Codeguard website ID matched what we received on create user' );
		ok ( $resp->{website}->{hostname} eq $config->{create_website}->{server_name}, 'Website resource hostname was correct' );
		ok ( $resp->{website}->{account} eq $config->{create_website}->{username}, 'Website resource account was correct' );
		ok ( $resp->{website}->{url} eq $config->{create_website}->{domain_name}, 'Website resource url was correct' );
		ok ( $resp->{website}->{disabled} eq JSON::false, 'Website resource is enabled' );
	}
};

subtest 'Delete created website resource with SSH key via SFTP' => sub {
	if (not $created_website_id) {
		pass 'Delete created website resource with SSH key via SFTP skipped';
		return;
	}

	my $resp = $user_api->delete_website(
		{
			website_id => $created_website_id,
		}
	);

	ok ( defined ($resp) && UNIVERSAL::isa($resp, 'HASH'), 'delete_website response was a hash' );
	if ( exists $resp->{error} ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Delete created user';
	}
	ok ( $resp->{message} eq '200', 'delete_website call was successful' );
};

done_testing;