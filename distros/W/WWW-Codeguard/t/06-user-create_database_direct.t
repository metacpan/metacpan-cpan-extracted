use strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use CommonSubs;
use Test::MockModule;

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

subtest 'Create Database Resource using the direct authentication method' => sub {
	if (
		not (
			UNIVERSAL::isa($config->{create_database}, 'HASH') and
			$config->{create_database}->{mysql_username} and
			$config->{create_database}->{mysql_password} and
			$config->{create_database}->{server_name} and
			$config->{create_database}->{database_name}
		)
	) {
		plan skip_all => 'Required partner parameters for create_database_direct tests are not setup in TEST_INFO.json. Please review README_TESTING.';
	}

	my $resp = $user_api->create_database(
		{
			account        => $config->{create_database}->{mysql_username},
			password       => $config->{create_database}->{mysql_password},
			database_name  => $config->{create_database}->{database_name},
			server_address => $config->{create_database}->{server_name},
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

subtest 'List database backups for a website' => sub {

    my $mock = Test::MockModule->new('LWP::UserAgent');
    $mock->mock(request =>
        sub {
            use HTTP::Response;
            return HTTP::Response->new(200, 'OK', undef, '
                {
                    "1234":{
                        "database_name":"backup_codeguard_1",
                        "commit_id" : "87f3b9f036c71aebc49abff30f415e763dead8c2",
                        "backup_time" : "July 1, 2017 = 4:01 am UTC",
                        "error_message": ""
                    },
                    "78910":{
                        "database_name":"backup_codeguard_1",
                        "commit_id" : "",
                        "backup_time" : "",
                        "error_message": "A restore is already in progress"
                    }
                }
            ');
        }
    );

    my $fake_commit_id = '2f902b20d0593051d16acd7b29b5fae28c75fa7d';
    my $resp = $user_api->list_website_database_backup_commits(
        {
            website_id => $created_database_website_id,
            commit_id  => $fake_commit_id,
        }
    );

    if ( ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'list_databse_backup_commits was a hash' ) ) {
	    if ( exists $resp->{error_message} && $resp->{error_message} ne "" or not UNIVERSAL::isa($resp, 'HASH') ) {
            diag 'API ERROR. Full response:';
            diag explain $resp;
            fail 'List website database backups';
        } else {
            ok ( scalar ( grep { exists $resp->{$_}->{commit_id} } keys %$resp ), 'Codeguard returned a commit_id' );
            is (ref($resp), 'HASH', 'list_website_database_backup_commits returned a HASH');
            is ( scalar (keys %$resp), 2, 'list_database_backups returned HASH contains two commits' );
        }
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

subtest 'Exercise database backup endpoints' => sub {
    # We aren't able to do a full test of the endpoints with these due to the
    # database resource not being 'activated' quickly enough (see the 'activated' field returned as part of `list_databases`).
    # So instead, we're only testing our own code out to the point of making the call to codeguard.

    my $num_subtests = 4;
    plan => $num_subtests;
    SKIP: {
        skip 'Requires database_id', $num_subtests
            if ! $created_database_id;

        my $mock = Test::MockModule->new('LWP::UserAgent');
        $mock->mock(request =>
            sub {
                use HTTP::Response;
                return HTTP::Response->new(200, 'OK', undef, '{"message":"200"}');
            }
        );

        note "create_database_backup";
        my $resp = $user_api->create_database_backup({
            website_id  => $created_database_website_id,
            database_id => $created_database_id,
        });
        is ( $resp->{'message'}, 200, 'create_database_backup call is fully functional' );

        note "restore_database_backup";
        my $fake_commit_id = '2f902b20d0593051d16acd7b29b5fae28c75fa7d';
        $resp = $user_api->restore_database_backup({
            website_id  => $created_database_website_id,
            database_id => $created_database_id,
            commit_id   => $fake_commit_id,
        });
        is ( $resp->{'message'}, 200, 'restore_database_backup  call is fully functional' );

        $mock->mock(request =>
            sub {
                use HTTP::Response;
                return HTTP::Response->new(200, 'OK', undef, '
                    [
                        {
                            "commit_id" : "87f3b9f036c71aebc49abff30f415e763dead8c2",
                            "additions" : 0,
                            "modifications" : 2,
                            "deletions" : 0,
                            "new_content" : true,
                            "event_time" : "2014-02-27T12:06:09-05:00"
                        },
                        {
                            "commit_id" : null,
                            "additions" : 0,
                            "modifications" : 0,
                            "deletions" : 0,
                            "new_content" : false,
                            "event_time" : "2014-02-24T12:56:00-05:00"
                        }
                    ]
                ');
            }
        );

        note "list_database_backups";
        $resp = $user_api->list_database_backups({
            website_id  => $created_database_website_id,
            database_id => $created_database_id,
        });
        is ( ref($resp), 'ARRAY', 'list_database_backups returned an ARRAY' );
        is ( scalar(@$resp), 2, 'list_database_backups returned ARRAY contains two backups' );
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

done_testing();
