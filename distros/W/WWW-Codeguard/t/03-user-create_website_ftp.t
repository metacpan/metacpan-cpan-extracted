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
} or plan skip_all => 'Failed to generate WWW::Codeguard::User object. Please ensure the information in TEST_INFO.json is valid';

subtest 'Create Website Resource with a password using FTP' => sub {
	if (
		not (
			UNIVERSAL::isa($config->{create_website}, 'HASH') and
			$config->{create_website}->{domain_name} and
			$config->{create_website}->{server_name} and
			$config->{create_website}->{username} and
			$config->{create_website}->{password}
		)
	) {
		plan skip_all => 'Required partner parameters for create_website, with a password using FTP, tests are not setup in TEST_INFO.json. Please review README_TESTING';
	}

	my $resp = $user_api->create_website(
		{
			url      => $config->{create_website}->{domain_name},
			hostname => $config->{create_website}->{server_name},
			account  => $config->{create_website}->{username},
			password => $config->{create_website}->{password},
			provider => 'ftp',
			( $config->{create_website}->{ftp_port}? ( port => $config->{create_website}->{ftp_port} ) : () ),
		}
	);

	ok ( defined $resp && UNIVERSAL::isa($resp, 'HASH'), 'create_website response was a hash' );
	if ( exists $resp->{error} or not (exists $resp->{website} and UNIVERSAL::isa($resp->{website}, 'HASH') ) ) {
		diag 'API ERROR. Full response:';
		diag explain $resp;
		fail 'Create website resource';
	} else {
		ok ( $resp->{website}->{id}, 'Codeguard Website ID was present' );
		ok ( $resp->{website}->{hostname} eq $config->{create_website}->{server_name}, 'Website resource hostname was correct' );
		ok ( $resp->{website}->{account} eq $config->{create_website}->{username}, 'Website resource account was correct' );
		ok ( $resp->{website}->{url} eq $config->{create_website}->{domain_name}, 'Website resource url was correct' );
		ok ( $resp->{website}->{provider} eq 'ftp', 'Website resource provider was correct' );
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

subtest 'Exercise backup endpoints' => sub {
    # We aren't able to do a full test of the endpoints with these due to the
    # website resource not being 'activated' quickly enough (see the 'activated' field returned as part of `list_websites`).
    # So instead, we're only testing our own code out to the point of making the call to codeguard.

    my $num_subtests = 9;
    plan => $num_subtests;

    SKIP: {
        skip 'Requires website_id', $num_subtests
            if ! $created_website_id;

        my $mock = Test::MockModule->new('LWP::UserAgent');
        $mock->mock(request =>
            sub {
                use HTTP::Response;
                return HTTP::Response->new(200, 'OK', undef, '{"message":"200"}');
            }
        );

        my $resp = $user_api->create_website_backup( { website_id => $created_website_id });
        is ( $resp->{'message'}, 200, 'create_website_backup call is fully functional' );

        my $fake_commit_id = '2f902b20d0593051d16acd7b29b5fae28c75fa7d';
        $resp = $user_api->restore_website_backup({
            website_id => $created_website_id,
            commit_id  => $fake_commit_id,
        });
        is ( $resp->{'message'}, 200, 'restore_website_backup  call is fully functional' );

        $resp = $user_api->selective_restore_website_backup({
            website_id => $created_website_id,
            commit_id  => $fake_commit_id,
            paths      => ['foo/bar.html','baz/spam.html'],
        });
        is ( $resp->{'message'}, 200, 'selective_restore_website_backup call is fully functional' );

        $resp = eval {
            $user_api->archive_website_backup({
                website_id => $created_website_id,
                commit_id  => $fake_commit_id,
            });
        } || $@;
        is ( $resp->{'message'}, 200, 'archive_website_backup call is fully functional' );

        $resp = $user_api->archive_website_selective_backup({
            website_id => $created_website_id,
            commit_id  => $fake_commit_id,
            paths      => ['foo/bar.js'],
        });
        is ( $resp->{'message'}, 200, 'archive_website_selective_backup call is fully functional' );

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

        $resp = $user_api->list_website_backups({ website_id => $created_website_id });
        is ( ref($resp), 'ARRAY', 'list_website_backups returned an ARRAY' );
        is ( scalar(@$resp), 2, 'list_website_backups returned ARRAY contains two backups' );

        $mock->mock(request =>
            sub {
                use HTTP::Response;
                return HTTP::Response->new(200, 'OK', undef, '
                    {
                      "name":"public_html",
                      "parent":"/home1/hgbackup",
                      "owner":null,
                      "group":null,
                      "mode":null,
                      "entries":[
                          {
                          "group":31304,
                          "name":".ftpquota",
                          "parent":"/home1/hgbackup/public_html",
                          "size":15,
                          "mode":384,
                          "modified_at":"2014-11-15T07:35:24Z",
                          "owner":31304
                          },
                          {
                          "group":31304,
                          "name":".htaccess",
                          "parent":"/home1/hgbackup/public_html",
                          "size":12893,
                          "mode":420,
                          "modified_at":"2014-02-24T19:41:02Z",
                          "owner":31304
                          }
                        ]
                    }
                ');
            }
        );

        $resp = $user_api->browse_website_backup({
            website_id => $created_website_id,
            commit_id  => $fake_commit_id,
        });
        ok ( exists $resp->{entries}, 'browse_website_backup returned an "entries" field' );
        is ( ref($resp->{entries}), 'ARRAY', 'browse_website_backup "entires" field in the response is an ARRAY' );

    }
};

subtest 'List website rules in the CG account' => sub {
    my $num_tests = 2;
    plan => $num_tests;

    SKIP: {
        skip 'Requires website_id', $num_tests
            if ! $created_website_id;

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
    }
};

subtest 'Set website exclude rules in the CG account' => sub {
    my $num_tests = 3;
    plan => $num_tests;

    SKIP: {
        skip 'Requires website_id', $num_tests
            if ! $created_website_id;

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

subtest 'Delete created website resource with a password via FTP' => sub {
	if (not $created_website_id) {
		pass 'Delete created website resource with a password via FTP skipped';
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
