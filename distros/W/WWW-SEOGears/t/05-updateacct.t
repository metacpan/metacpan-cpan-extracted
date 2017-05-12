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

	skip "Failed to create account", 6 if (not $output->{success});
	my $authkey = $output->{'authkey'};
	my $bizid   = $output->{'bzid'};

	$params = { 'userid' => $params->{'userid'},
				'email'  => $params->{'email'},
	};
	#diag "\nChecking created account:\n".explain($params);
	if ($output =  eval { $api->statuscheck($params); }) {
		#diag "\nStatuscheck output:\n".explain($output);
	} else {
		diag "Statuscheck failed: $output->{debuginfo} - \n";
		diag explain $@;
	}

	my $newemail;
	my $userid = $params->{'userid'};
	SKIP: {
		skip "Failed to fetch current info for '$userid'", 6 if (not $output->{success});

		$params = { 'bzid'    => $output->{bzid},
					'authkey' => $output->{authkey},
					'email'   => CommonSubs::random_uid().'@hostgatortesting.com',
					'pack'    => "35",
					'price'   => "1.00",
					'months'  => "24",
		};
		$newemail = $params->{'email'};

		#diag "\nUpdating account:\n".explain($params);
		if ($output =  eval { $api->update($params); }) {
			#diag "\nUpdate output:\n".explain($output);
		} else {
			diag "\nUpdate failed: $output->{debuginfo} - \n";
			diag explain $@;
		}
		ok ( $output->{success}, "Update account");

		SKIP: {
			skip "Failed to Update info for '$userid'", 4 if (not $output->{success});

			$params = { 'userid'  => $userid,
						'email'   => $newemail,
			};

			#diag "\nChecking updated account info:\n".explain($params);
			$output =  eval { $api->statuscheck($params); };
			if ($output->{success}) {
				#diag "\nUpdated statuscheck output:\n".explain($output);
			} else {
				diag "\nStatuscheck for updated account failed: $output->{debuginfo} - \n";
				diag explain $@;
			}
			ok ( $output->{success} == 1, "Statuscheck on updated acct");
			ok ( $output->{bzid} eq $bizid, "bizid on updated account matches");
			ok ( $output->{authkey} eq $authkey, "authkey on updated account matches");
			ok ( $output->{pack} eq '35', "package id on updated account matches");
			ok ( $output->{months} eq '24', "months on updated account matches");
		}
	}
}

done_testing();