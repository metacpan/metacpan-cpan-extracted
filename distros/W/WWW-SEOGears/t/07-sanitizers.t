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
my $output = CommonSubs::newuser($api, $params, 1);
if ($output->{success}) {
	diag "\nCreate account output:\n".explain($output);
} else {
	#diag "\nFailed to create account:\n";
	#diag explain $@;
}
ok (not (keys %{$output}), "Create account sanitization failed");

$params = { 'userid' => CommonSubs::random_uid(),
			'email'  => '',
};
#diag "\nStatuscheck:\n".explain($params);
$output = eval { $api->statuscheck($params); };
if ($output->{success}) {
	diag "\nStatuscheck output:\n".explain($output);
} else {
	#diag explain $@;
}
ok (not (keys %{$output}), "Statuscheck sanitization failed");

$params = { 'bzid' => CommonSubs::random_uid() };
#diag "\nInactivate account:\n".explain($params);
$output = eval { $api->inactivate($params); };
if ($output->{success}) {
	diag "\nInactivate output:\n".explain($output);
} else {
	#diag explain $@;
}
ok (not (keys %{$output}), "Inactivate sanitization failed");

$params = { 'bzid' => CommonSubs::random_uid() };
#diag "\nUpdate account:\n".explain($params);
$output = eval { $api->update($params); };
if ($output->{success}) {
	diag "\nUpdate output:\n".explain($output);
} else {
	#diag explain $@;
}
ok (not (keys %{$output}), "Update sanitization failed");

$params = { 'bzid' => CommonSubs::random_uid() };
#diag "\nGet tempauth:\n".explain($params);
$output = eval { $api->inactivate($params); };
if ($output->{success}) {
	diag "\nGet Tempauth output:\n".explain($output);
} else {
	#diag explain $@;
}
ok (not (keys %{$output}), "Get tempauth sanitization failed");

done_testing();