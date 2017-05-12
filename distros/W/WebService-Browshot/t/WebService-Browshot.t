use Data::Dumper;

use Test::More;
use lib '../lib/';
BEGIN { use_ok( 'WebService::Browshot' ); }
require_ok( 'WebService::Browshot' );


my $browshot = WebService::Browshot->new(
	key	=> 'vPTtKKLBtPUNxVwwfEKlVvekuxHyTXyi',
	base	=> 'http://127.0.0.1:3000/api/v1/',
	debug	=> 0,
);

is($browshot->api_version(), '1.14', "API version");

SKIP: {
	skip "env BROWSHOT_REMOTE_TESTS not set", 130 if (! $ENV{BROWSHOT_REMOTE_TESTS});

	# Check access to https://browshot.com/
	my $ua = LWP::UserAgent->new();
	$ua->timeout(60);
	$ua->env_proxy;

	my $response = $ua->get('https://browshot.com/');
# 	print $response->as_string, "\n";

	skip "Unable to access https://browshot.com/", 129 if (! $response->is_success);

	my ($code, $png) = $browshot->simple(url => 'http://mobilito.net/', cache => 60 * 60 * 24 * 365, instance_id => 12); # cached for a year
	ok( $code == 200, 					"Screenshot should be succesful: $code");
	ok( length($png) > 0, 					"Screenshot should be succesful");

	my $instances = $browshot->instance_list();
	
	ok( exists $instances->{free}, 				"List of free instances available");
	ok( exists $instances->{shared}, 			"List of shared instances available");
	ok( exists $instances->{private}, 			"List of private instances available");

	ok( scalar(@{$instances->{free}}) > 0, 			"At least one free instance is available");
	ok( scalar(@{$instances->{shared}}) > 0, 		"At least one shared instance is available");
	ok( scalar(@{$instances->{private}}) >= 0, 		"No private instance is available");

	my $free = $instances->{free}->[0];
	ok( exists $free->{id}, 				"Instance ID is present");
	ok( exists $free->{width}, 				"Instance width is present");
	ok( exists $free->{height}, 				"Instance height is present");
	ok( exists $free->{load}, 				"Instance load is present");
	ok( exists $free->{browser}, 				"Instance browser is present");
	ok( exists $free->{browser}->{id}, 			"Instance browser ID is present");
	ok( exists $free->{browser}->{name}, 			"Instance browser name is present");
	ok( exists $free->{browser}->{javascript}, 		"Instance browser javascript is present");
	ok( exists $free->{browser}->{flash}, 			"Instance browser flash is present");
	ok( exists $free->{browser}->{mobile}, 			"Instance browser mobile is present");
	ok( exists $free->{type}, 				"Instance type is present");
	ok( exists $free->{screenshot_cost}, 			"Instance screenshot_cost is present");
	ok( $free->{screenshot_cost} == 0, 			"Instance cost is 0");



	my $instance = $browshot->instance_info(id => $free->{id});
	ok( $free->{id} == $instance->{id}, 						"Correct instance ID");
	ok( $free->{width} == $instance->{width}, 					"Correct instance width");
	ok( $free->{height} == $instance->{height}, 					"Correct instance height");
# 	ok( $free->{load} == $instance->{load}, 					"Correct instance load"); # this can change between 2 calls
	ok( $free->{browser}->{id} == $instance->{browser}->{id}, 			"Correct instance browser ID");
	ok( $free->{browser}->{name} eq $instance->{browser}->{name}, 			"Correct instance browser ID");
	ok( $free->{browser}->{javascript} == $instance->{browser}->{javascript}, 	"Correct instance browser javascript");
	ok( $free->{browser}->{flash} == $instance->{browser}->{flash}, 		"Correct instance browser javascript");
	ok( $free->{browser}->{mobile} == $instance->{browser}->{mobile}, 		"Correct instance browser javascript");
	ok( $free->{type} eq $instance->{type}, 					"Correct instance type");
	ok( $free->{screenshot_cost} == $instance->{screenshot_cost}, 			"Correct instance screenshot_cost");

	my $missing = $browshot->instance_info(id => -1);
	ok( exists $missing->{error}, 					"Instance was not found");
	ok( exists $missing->{status}, 					"Instance was not found");


# 	my $wrong = $browshot->instance_create(width => 3000);
# 	ok( exists $wrong->{error}, 					"Instance width too large");
# 
# 	$wrong = $browshot->instance_create(height => 3000);
# 	ok( exists $wrong->{error}, 					"Instance height too large");
# 
# 	$wrong = $browshot->instance_create(browser_id => -1);
# 	ok( exists $wrong->{error}, 					"Invalid browser_id");
# 
# 	# Privaet instances is enabled for a few account only
# 	my $fake = $browshot->instance_create();
# 	ok( exists $fake->{error}, 						"Private instances not enabled for this account");
# 	ok( exists $fake->{id}, 						"Instance was created");
# 	ok( exists $fake->{width}, 						"Instance was created");
# 	ok( exists $fake->{browser}, 					"Instance was created");
# 	ok( exists $fake->{browser}->{id}, 				"Instance was created");


	my $browsers = $browshot->browser_list();
	ok( scalar( keys %{$browsers} ) > 0,			"Browsers are available");


	my $browser_id = 0;
	foreach my $key (keys %{$browsers}) {
		$browser_id = $key;
		last;
	}
	ok( $browser_id > 0, 							"Browser ID is correct");
	
	my $browser = $browsers->{$browser_id};
	ok( exists $browser->{name}, 					"Browser name exists");
	ok( exists $browser->{user_agent}, 				"Browser user_agent exists");
	ok( exists $browser->{appname}, 				"Browser appname exists");
	ok( exists $browser->{vendorsub}, 				"Browser vendorsub exists");
	ok( exists $browser->{appcodename}, 			"Browser appcodename exists");
	ok( exists $browser->{platform}, 				"Browser platform exists");
	ok( exists $browser->{vendor}, 					"Browser vendor exists");
	ok( exists $browser->{appversion}, 				"Browser appversion exists");
	ok( exists $browser->{javascript}, 				"Browser javascript exists");
	ok( exists $browser->{mobile}, 					"Browser mobile exists");
	ok( exists $browser->{flash}, 					"Browser flash exists");


# 	# Browswer creation is disabled for most accounts
# 	my $new = $browshot->browser_create(mobile => 1, flash => 1, user_agent => 'test');
# 	ok( exists $new->{error}, 						"Browser cannot be created with this account");
# 	ok( exists $new->{name}, 						"Browser name exists");
# 	ok( exists $new->{user_agent}, 					"Browser user_agent exists");
# 	ok( exists $new->{appname}, 					"Browser appname exists");
# 	ok( exists $new->{vendorsub}, 					"Browser vendorsub exists");
# 	ok( exists $new->{appcodename}, 				"Browser appcodename exists");
# 	ok( exists $new->{platform}, 					"Browser platform exists");
# 	ok( exists $new->{vendor}, 						"Browser vendor exists");
# 	ok( exists $new->{appversion}, 					"Browser appversion exists");
# 	ok( exists $new->{javascript}, 					"Browser javascript exists");
# 	ok( exists $new->{mobile}, 						"Browser mobile exists");
# 	ok( exists $new->{flash}, 						"Browser flash exists");



	# screenshot is not actually created for test account, so the reply may not match our parameters
	my $screenshot = $browshot->screenshot_create();
	ok( exists $screenshot->{error}, 				"Screenshot failed");

	$screenshot = $browshot->screenshot_create(url => '-');
	ok( exists $screenshot->{error}, 				"Screenshot failed");

	$screenshot = $browshot->screenshot_create(url => 'http://browshot.com/', cache => 999999, instance_id => 12);
	ok( exists $screenshot->{id}, 				"Screenshot ID is present");
	ok( exists $screenshot->{status}, 			"Screenshot status is present");
	ok( exists $screenshot->{priority}, 			"Screenshot priority is present");
	
	SKIP: {
		skip "Screenshot is not finished", 16 if ($screenshot->{status} ne 'finished');

		ok( exists $screenshot->{screenshot_url}, 	"Screenshot screenshot_url is present");
		ok( exists $screenshot->{url}, 			"Screenshot url is present");
		ok( exists $screenshot->{size}, 		"Screenshot size is present");
		ok( exists $screenshot->{width}, 		"Screenshot width is present");
		ok( exists $screenshot->{height}, 		"Screenshot height is present");
		ok( exists $screenshot->{request_time}, 	"Screenshot request_time is present");
		ok( exists $screenshot->{started}, 		"Screenshot started is present");
		ok( exists $screenshot->{load}, 		"Screenshot load is present");
		ok( exists $screenshot->{content}, 		"Screenshot content is present");
		ok( exists $screenshot->{finished}, 		"Screenshot finished is present");
		ok( exists $screenshot->{instance_id}, 		"Screenshot instance_id is present");
		ok( exists $screenshot->{response_code}, 	"Screenshot response_code is present");
		ok( exists $screenshot->{final_url}, 		"Screenshot final_url is present");
		ok( exists $screenshot->{content_type}, 	"Screenshot content_type is present");
		ok( exists $screenshot->{scale}, 		"Screenshot scale is present");
		ok( exists $screenshot->{cost}, 		"Screenshot cost is present");
	}

	my $screenshot2 = $browshot->screenshot_info();
	ok( exists $screenshot2->{error}, 				"Screenshot ID is missing");

	$screenshot2 = $browshot->screenshot_info(id => $screenshot->{id}, details => 2);
# 	print Dumper($screenshot2), "\n";
	ok( exists $screenshot2->{id}, 					"Screenshot ID is present");
	ok( exists $screenshot2->{status}, 				"Screenshot status is present");
# 	ok( exists $screenshot2->{priority}, 				"Screenshot priority is present");

	SKIP: {
		skip "Screenshot is not finished", 44 if ($screenshot2->{status} ne 'finished');

		ok( exists $screenshot2->{screenshot_url}, 	"Screenshot screenshot_url is present");
		ok( exists $screenshot2->{url}, 		"Screenshot url is present");
		ok( exists $screenshot2->{size}, 		"Screenshot size is present");
		ok( exists $screenshot2->{width}, 		"Screenshot width is present");
		ok( exists $screenshot2->{height}, 		"Screenshot height is present");
		ok( exists $screenshot2->{request_time}, 	"Screenshot request_time is present");
		ok( exists $screenshot2->{started}, 		"Screenshot started is present");
		ok( exists $screenshot2->{load}, 		"Screenshot load is present");
		ok( exists $screenshot2->{content}, 		"Screenshot content is present");
		ok( exists $screenshot2->{finished}, 		"Screenshot finished is present");
		ok( exists $screenshot2->{instance_id}, 	"Screenshot instance_id is present");
		ok( exists $screenshot2->{response_code}, 	"Screenshot response_code is present");
		ok( exists $screenshot2->{final_url}, 		"Screenshot final_url is present");
		ok( exists $screenshot2->{content_type}, 	"Screenshot content_type is present");
		ok( exists $screenshot2->{scale}, 		"Screenshot scale is present");
		ok( exists $screenshot2->{cost}, 		"Screenshot cost is present");
		ok( ! exists $screenshot2->{images}, 		"Screenshot images are NOT present");


		$screenshot2 = $browshot->screenshot_info(id => $screenshot->{id}, details => 0);
		ok( exists $screenshot2->{screenshot_url}, 	"Screenshot screenshot_url is present");
		ok( exists $screenshot2->{final_url}, 		"Screenshot final_url is present");
# 		ok( ! exists $screenshot2->{response_code}, 	"Screenshot response_code is present");
# 		ok( ! exists $screenshot2->{content_type}, 	"Screenshot content_type is present");
# 		ok( ! exists $screenshot2->{finished}, 		"Screenshot finished is present");
# 		ok( ! exists $screenshot2->{images}, 		"Screenshot images are present");
		

		$screenshot2 = $browshot->screenshot_info(id => $screenshot->{id}, details => 1);
		ok( exists $screenshot2->{screenshot_url}, 	"Screenshot screenshot_url is present");
		ok( exists $screenshot2->{final_url}, 		"Screenshot final_url is present");
		ok( exists $screenshot2->{response_code}, "Screenshot response_code is present");
		ok( exists $screenshot2->{content_type}, 	"Screenshot content_type is present");
# 		ok( ! exists $screenshot2->{started}, 		"Screenshot started is NOT present");
# 		ok( ! exists $screenshot2->{iframes}, 		"Screenshot images are NOT present");


		$screenshot2 = $browshot->screenshot_info(id => $screenshot->{id}, details => 2);
		ok( exists $screenshot2->{screenshot_url}, 	"Screenshot screenshot_url is present");
		ok( exists $screenshot2->{final_url}, 		"Screenshot final_url is present");
		ok( exists $screenshot2->{response_code}, 	"Screenshot response_code is present");
		ok( exists $screenshot2->{content_type}, 	"Screenshot content_type is present");
		ok( exists $screenshot2->{started}, 		"Screenshot started is present");
		ok( exists $screenshot2->{finished}, 		"Screenshot finished is present");
# 		ok( ! exists $screenshot2->{iframes}, 		"Screenshot images are NOT present");

# 		API change: details => 3 must be explicit with the screenshot request
# 		$screenshot2 = $browshot->screenshot_info(id => $screenshot->{id}, details => 3);
# 		ok( exists $screenshot2->{screenshot_url}, 	"Screenshot screenshot_url is present");
# 		ok( exists $screenshot2->{final_url}, 		"Screenshot final_url is present");
# 		ok( exists $screenshot2->{response_code}, 	"Screenshot response_code is present");
# 		ok( exists $screenshot2->{content_type}, 	"Screenshot content_type is present");
# 		ok( exists $screenshot2->{started}, 		"Screenshot started is present");
# 		ok( exists $screenshot2->{finished}, 		"Screenshot finished is present");
# 		ok( exists $screenshot2->{iframes}, 		"Screenshot images are present");
# 		ok( exists $screenshot2->{scripts}, 		"Screenshot scripts are present");
# 		ok( exists $screenshot2->{iframes}, 		"Screenshot iframes are present");
	}

	my $screenshots;
	eval {
		$screenshots = $browshot->screenshot_list();
	};
	print $@, "\n" if ($@);
	ok( scalar (keys %$screenshots) > 0, 			"Screenshots are present");

	my $screenshot_id = 0;
	foreach my $key (keys %$screenshots) {
		$screenshot_id = $key;
		last;
	}
	ok( $screenshot_id > 0, 						"Screenshot ID is correct");
	
	$screenshot = '';
	eval {
		$screenshot = $screenshots->{$screenshot_id};
	};
# 	print $@, "\n" if ($@);
	
	ok( exists $screenshot->{id}, 				"Screenshot ID is present");
	ok( exists $screenshot->{status}, 			"Screenshot status is present");
	ok( exists $screenshot->{priority}, 			"Screenshot priority is present");
	ok( exists $screenshot->{screenshot_url}, 		"Screenshot screenshot_url is present");
	ok( exists $screenshot->{url}, 				"Screenshot url is present");
	ok( exists $screenshot->{size}, 			"Screenshot size is present");
	ok( exists $screenshot->{width}, 			"Screenshot width is present");
	ok( exists $screenshot->{height}, 			"Screenshot height is present");
	ok( exists $screenshot->{request_time}, 		"Screenshot request_time is present");
	ok( exists $screenshot->{started}, 			"Screenshot started is present");
	ok( exists $screenshot->{load}, 			"Screenshot load is present");
	ok( exists $screenshot->{content}, 			"Screenshot content is present");
	ok( exists $screenshot->{finished}, 			"Screenshot finished is present");
	ok( exists $screenshot->{instance_id}, 			"Screenshot instance_id is present");
	ok( exists $screenshot->{response_code}, 		"Screenshot response_code is present");
	ok( exists $screenshot->{final_url}, 			"Screenshot final_url is present");
	ok( exists $screenshot->{content_type}, 		"Screenshot content_type is present");
	ok( exists $screenshot->{scale}, 			"Screenshot scale is present");
	ok( exists $screenshot->{cost}, 			"Screenshot cost is present");
	ok( ! exists $screenshot->{images}, 			"Screenshot images are NOT present");


	$screenshots = $browshot->screenshot_list(details => 0);
	$screenshot_id = 0;
	foreach my $key (keys %$screenshots) {
		$screenshot_id = $key;
		last;
	}
	ok( $screenshot_id > 0, 				"Screenshot ID is correct");
	$screenshot = $screenshots->{$screenshot_id};

	ok( exists $screenshot->{id}, 				"Screenshot ID is present");
	ok( exists $screenshot->{final_url}, 			"Screenshot final_url is present");
# 	ok( ! exists $screenshot->{response_code}, 		"Screenshot response_code is NOT present");
# 	ok( ! exists $screenshot->{content_type}, 		"Screenshot content_type is NOT present");
# 	ok( ! exists $screenshot->{finished}, 			"Screenshot finished is NOT present");
# 	ok( ! exists $screenshot->{images}, 			"Screenshot images are NOT present");


	# search
	$screenshots = $browshot->screenshot_search(url => 'google.com', details => 0);
	$screenshot_id = 0;
	foreach my $key (keys %$screenshots) {
		$screenshot_id = $key;
		last;
	}
	ok( $screenshot_id > 0, 				"Screenshot ID is correct");
	$screenshot = $screenshots->{$screenshot_id};

	ok( exists $screenshot->{id}, 				"Screenshot ID is present");
	ok( exists $screenshot->{final_url}, 			"Screenshot final_url is present");
	ok( ! exists $screenshot->{response_code}, 		"Screenshot response_code is NOT present");
	ok( ! exists $screenshot->{content_type}, 		"Screenshot content_type is NOT present");
	ok( ! exists $screenshot->{finished}, 			"Screenshot finished is NOT present");
	ok( ! exists $screenshot->{images}, 			"Screenshot images are NOT present");
	

	# Thumbnail
	$screenshots = $browshot->screenshot_list(details => 0);
# 	print Dumper($screenshots);
	$screenshot_id = 0;
	foreach my $key (keys %$screenshots) {
		if ($screenshots->{$key}->{status} eq 'finished') {
			$screenshot_id = $key;
			last;
		}
	}

	SKIP: {
		skip "No finished screenshot found", 6 if ($screenshot_id == 0);

		my $thumbnail = $browshot->screenshot_thumbnail(id => $screenshot_id, width => 640);
		ok( $thumbnail ne '', 				"Thumbnail was successful (not empty)");
		ok( length($thumbnail) > 100,			"Thumbnail was successful (size > 100)");
		is ( substr($thumbnail, 1, 3), 'PNG',		"Valid PNG file");

		# crop 300x300
		$thumbnail = $browshot->screenshot_thumbnail(id => $screenshot_id, right => 300, bottom => 300);
		ok( $thumbnail ne '', 				"Thumbnail (1) was successful (not empty)");
		ok( length($thumbnail) > 100,			"Thumbnail (1) was successful (size > 100)");
		is ( substr($thumbnail, 1, 3), 'PNG',		"Valid PNG file (1)");

		$thumbnail = $browshot->screenshot_thumbnail(id => $screenshot_id, right => 300, bottom => 300, width => 150);
		ok( $thumbnail ne '', 				"Thumbnail (2) was successful (not empty)");
		ok( length($thumbnail) > 100,			"Thumbnail (2) was successful (size > 100)");
		is ( substr($thumbnail, 1, 3), 'PNG',		"Valid PNG file (2)");


		# verify backward compatibility
		$thumbnail = $browshot->screenshot_thumbnail(url => $screenshots->{$screenshot_id}->{screenshot_url}, width => 640);
		ok( $thumbnail ne '', 				"Thumbnail was successful (not empty - url)");
		ok( length($thumbnail) > 100,			"Thumbnail was successful (size > 100 - url)");
		is ( substr($thumbnail, 1, 3), 'PNG',		"Valid PNG file (url)");
	}

	SKIP: {
		skip "No finished screenshot found", 1 if ($screenshot_id == 0);

		my $html = $browshot->screenshot_html(id => $screenshot_id);
		is ( $html, '',				"No HTML retrieved");
		print $html, "\n" if ($html ne '');
	}

# 	my $thumbnail = $browshot->screenshot_thumbnail(id => -1, width => 640);
# 	is( $thumbnail, '', 							"Missing screenshot ID");


	# Screenshot share
	my $share = $browshot->screenshot_share(id => 1);
	is( $share->{status}, 'error', 				"Incorrect screenshot ID");

	# Multiple screenshots - Cannot be tested with Test user
# 	$screenshots = $browshot->screenshot_multiple(urls => ['http://mobilito.net/', 'http://www.google.com/'], instances => [12, 72]);
# 	my $screenshot_id = 0;
# 	foreach my $key (keys %$screenshots) {
# 		$screenshot_id = $key;
# 		last;
# 	}
# 	ok( $screenshot_id > 0, 						"Screenshot ID is correct");
# 	ok( exists $screenshot->{id}, 						"Screenshot ID is present");
# 	ok( exists $screenshot->{status}, 					"Screenshot status is present");

	# Hosting disabled for this account
	my $hosting = $browshot->screenshot_host(id => $screenshot_id, hosting => 'browshot');
	is( $hosting->{status}, 'error', 					"Browshot hosting option not enabled for this account");

	$hosting = $browshot->screenshot_host(id => $screenshot_id, hosting => 'foobar');
	is( $hosting->{status}, 'error', 					"Hosting option incorrect");


	# Batch request
	my $batch = $browshot->batch_create();
	is( $batch->{status}, 'error', 					"Batch request inccorect");

	$batch = $browshot->batch_info(id => 1);
	is( $batch->{status}, 'error', 					"Batch id inccorect");

	# Account information
	my $account = $browshot->account_info();
	ok( exists $account->{balance}, 			"Account balance is present");
	is( $account->{balance}, 0, 				"Balance is empty");
	ok( exists $account->{active}, 				"Account active is present");
	is( $account->{active}, 1, 				"Account is active");
# 	ok( exists $account->{instances}, 			"Account instances is present"); # not present for details=1
	ok( exists $account->{free_screenshots_left}, 		"Free screenshots is present");
	ok( $account->{free_screenshots_left} > 0,		"Free screenshots left");
	is( $account->{private_instances}, 0, 			"Private instances disabled");
	is( $account->{hosting_browshot}, 0, 			"Browshot hosting disabled");


	# Error tests
	$browshot = WebService::Browshot->new(
		key		=> 'test1',
	# 	debug	=> 1,
	);

	$account = $browshot->account_info();
	ok( exists $account->{error}, 				"Invalid key");
}

done_testing;
