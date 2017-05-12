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
		UNIVERSAL::isa($config->{edit_website}, 'HASH') and
		$config->{edit_website}->{website_id} and
		(
			$config->{edit_website}->{dir_path} or
			$config->{edit_website}->{url} or
			$config->{edit_website}->{monitor_frequency} or
			$config->{edit_website}->{account} or
			$config->{edit_website}->{password} or
			$config->{edit_website}->{key} or
			$config->{edit_website}->{hostname}
		)
	)
) {
	plan skip_all => 'Required partner parameters for edit_website tests are not setup in TEST_INFO.json. Please review README_TESTING.';
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

subtest 'Check existing website resource' => sub {
	my $resp = $user_api->list_websites;
	ok (defined $resp && UNIVERSAL::isa($resp, 'ARRAY'), 'list_websites response was an array' );
	if ( ok ( (not scalar ( grep { not UNIVERSAL::isa($_, 'HASH') } @{ $resp } )), 'response was an array of hashes' ) ) {
		my @websites = grep { $_->{website}->{id} eq $config->{edit_website}->{website_id} } @{ $resp };
		if ( ok ( scalar @websites, 'Website resource with the website_id specified exists on the account' ) ) {
			$old_values = $websites[0];
		}
	} else {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'List website resources';
	}
};

subtest 'Edit website resource' => sub {
	if ( not UNIVERSAL::isa($old_values, 'HASH') ) {
		plan skip_all => 'Unable to find website_id specified';
	}
	$edit_params = {
		website_id => $config->{edit_website}->{website_id},
		( $config->{edit_website}->{dir_path}? ( dir_path => $config->{edit_website}->{dir_path} ) : () ),
		( $config->{edit_website}->{url}? ( url => $config->{edit_website}->{url} ) : () ),
		( $config->{edit_website}->{monitor_frequency}? ( monitor_frequency => $config->{edit_website}->{monitor_frequency} ) : () ),
		( $config->{edit_website}->{account}? ( account => $config->{edit_website}->{account} ) : () ),
		( $config->{edit_website}->{password}? ( password => $config->{edit_website}->{password} ) : () ),
		( $config->{edit_website}->{key}? ( key => $config->{edit_website}->{key} ) : () ),
		( $config->{edit_website}->{hostname}? ( hostname => $config->{edit_website}->{hostname} ) : () ),
	};

	my $resp = $user_api->edit_website($edit_params);

	ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'edit_website response was a hash' );
	if ( exists $resp->{error} or not (exists $resp->{website} and UNIVERSAL::isa($resp->{website}, 'HASH') ) ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Edit website resource';
	} else {
		if ( $config->{edit_website}->{dir_path} ) {
			ok ( $resp->{website}->{dir_path} eq $config->{edit_website}->{dir_path}, 'Edit website - dir_path updated successfully' );
		}
		if ( $config->{edit_website}->{url} ) {
			ok ( $resp->{website}->{url} eq $config->{edit_website}->{url}, 'Edit website - URL updated successfully' );
		}
		if ( $config->{edit_website}->{monitor_frequency} ) {
			ok ( $resp->{website}->{monitor_frequency} eq $config->{edit_website}->{monitor_frequency}, 'Edit website - monitor_frequency updated successfully' );
		}
		if ( $config->{edit_website}->{account} ) {
			ok ( $resp->{website}->{account} eq $config->{edit_website}->{account}, 'Edit website - account updated successfully' );
		}
		if ( $config->{edit_website}->{hostname} ) {
			ok ( $resp->{website}->{hostname} eq $config->{edit_website}->{hostname}, 'Edit website - hostname updated successfully' );
		}
	}
};

subtest "Resetting website resource" => sub {
	if ( not (UNIVERSAL::isa($old_values, 'HASH') and UNIVERSAL::isa($edit_params, 'HASH') ) ) {
		plan skip_all => 'Unable to find website_id specified';
	}
	foreach my $param (keys %{$edit_params}) {
		if (exists $old_values->{website}->{$param}) {
			$edit_params->{$param} = $old_values->{website}->{$param};
		}
	}
	my $resp = $user_api->edit_website($edit_params);

	ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'edit_website response was a hash' );
	if ( exists $resp->{error} or not (exists $resp->{website} and UNIVERSAL::isa($resp->{website}, 'HASH') ) ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Reset website resource';
	} else {
		pass 'Reset website resource';
	}
};

done_testing;
