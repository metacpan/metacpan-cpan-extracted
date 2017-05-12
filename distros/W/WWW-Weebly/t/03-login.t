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
		if (ok ($newuser->{new_id} =~ m/\d+/, "newuser returned valid new_id")) {
			my $login_params = {
				user_id        => $newuser->{new_id},
				ftp_url        => '1.1.1.1',
				ftp_username   => 'testing',
				ftp_password   => 'testing',
				ftp_path       => '/',
				property_name  => 'testing property name',
				upgrade_url    => 'http://1.1.1.1',
				publish_domain => 'testingfqdn.com',
				platform       => 'Unix',
			};
			my $login = $api->login($login_params);
			diag explain $login if $ENV{'WEEBLY_DEBUG'};
			ok (exists $login->{login_url}, "login url returned");
		}
	}
}

done_testing();