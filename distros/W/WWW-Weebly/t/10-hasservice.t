use Test::More;
use FindBin;
use lib $FindBin::Bin;
use CommonSubs;

SKIP: {
	skip 'No $ENV{WEEBLY_SECRET} and $ENV{WEEBLY_URL} set - Please run these test with a valid API key in the ENV.', 3 unless ($ENV{'WEEBLY_SECRET'} and $ENV{'WEEBLY_URL'});
	my $api = CommonSubs::initiate_api();
	ok ( defined ($api) && ref $api eq 'WWW::Weebly', "API object creation" );
	my $newuser = $api->new_user();
	diag explain $newuser if $ENV{'WEEBLY_DEBUG'};
	if (ok ((ref $newuser eq 'HASH' and $newuser->{success}), "newuser call successfull")) {
		if(ok ($newuser->{new_id} =~ m/\d+/, "newuser returned valid new_id")) {
			my $has_service_params = {
				user_id    => $newuser->{new_id},
				service_id => 'Weebly.proAccount',
			};
			my $hasservice = $api->has_service( $has_service_params );
			diag explain $hasservice if $ENV{'WEEBLY_DEBUG'};
			ok ( $hasservice->{success} == 0, "has service checked successfully");
		}
	}
}

done_testing();