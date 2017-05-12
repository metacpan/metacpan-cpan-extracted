use Test::More;
use FindBin;
use lib $FindBin::Bin;
use CommonSubs;

unless ($ENV{'SEOGEARS_BRANDNAME'} and $ENV{'SEOGEARS_BRANDKEY'}) {
	plan skip_all => 'No $ENV{SEOGEARS_BRANDNAME} and $ENV{SEOGEARS_BRANDKEY} set - Please run the test with a valid brandname and brandkey in the ENV.';
}

my $api = CommonSubs::initiate_api();

my $params = CommonSubs::gen_rand_params();
#diag "\nCreating an account:\n".explain($params);
my $output = CommonSubs::newuser($api, $params);
if ($output->{success}) {
	#diag "\nCreate account output:\n".explain($output);
} else {
	diag "\nCreate account failed: $output->{debuginfo} - \n";
	diag explain $@;
}
ok ($output->{success}, "Account creation");
SKIP: {

	skip "Failed to create account", 1 if (not $output->{success});
	my $authkey = $output->{'authkey'};
	my $email = $params->{'email'};
	my $userid = $params->{'userid'};
	$params = { 'userid' => $userid,
				'email'  => $email,
	};

	#diag "\nChecking created account:\n".explain($params);
	if ($output =  eval { $api->statuscheck($params); }) {
		#diag "\nStatuscheck output:\n".explain($output);
	} else {
		diag "Statuscheck failed: $output->{debuginfo} - \n";
		diag explain $@;
	}

	SKIP: {
		skip "Failed to fetch current info for $params->{'userid'}", 1 if (not $output->{success});

		$params = { 'bzid'    => $output->{bzid},
					'authkey' => $output->{authkey},
		};
		#diag "\nInactivating account:\n".explain($params);
		$output =  eval { $api->inactivate($params); };
		if ($output->{success}) {
			#diag "\nInactivate output:\n".explain($output);
		} else {
			diag "\nInactivate failed: $output->{debuginfo} - \n";
			diag explain $@;
		}
		ok ( $output->{success}, "Inactivate account");
		
		SKIP: {
				skip "Failed to inactivate account", 2 if (not $output->{success});
				my $authkey = $output->{'authkey'};

				$params = { 'userid' => $userid,
							'email'  => $email,
				};

				#diag "\nChecking inactivated account:\n".explain($params);
				if ($output =  eval { $api->statuscheck($params); }) {
					#diag "\nStatuscheck output:\n".explain($output);
				} else {
					diag "Statuscheck failed: $output->{debuginfo} - \n";
					diag explain $@;
				}
				ok( $output->{inactive}, "Account is inactivated.");
				SKIP: {
					skip "Account is not inactive", 1 if (not $output->{inactive});
					my $authkey = $output->{'authkey'};
					my $bzid    = $output->{'bzid'};

					$params = { 'bzid'    => $bzid,
								'authkey' => $authkey, 
					};

					#diag "\nRe-activating account:\n".explain($params);
					if ($output = eval { $api->activate($params); }) {
						#diag "\nReactivate output:\n".explain($output);
					} else {
						diag "Reactivate failed: $output->{debuginfo} - \n";
						diag explain $@;
					}
					ok ($output->{success}, 'Reactivate account');

					$params = { 'userid' => $userid,
								'email'  => $email,
					};
					if ($output =  eval { $api->statuscheck($params); }) {
						#diag "\nStatuscheck output:\n".explain($output);
					} else {
						diag "Statuscheck failed: $output->{debuginfo} - \n";
						diag explain $@;
					}
					ok( $output->{inactive} == 0, "Account is reactivated.");
				}
		}
	}
}

done_testing();