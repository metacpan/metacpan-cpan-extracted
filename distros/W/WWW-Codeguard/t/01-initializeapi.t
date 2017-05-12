use strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use CommonSubs;

my $config = CommonSubs::read_config();

require_ok ( 'WWW::Codeguard' );
my $api_url = $config->{api_url} || 'http://testing-codeguard.not.real.dns';

subtest "Partner API object creation" => sub {
	my $partner_api = CommonSubs::initiate_api_partner();
	my $partner_key = $config->{partner_api}->{partner_key} || 'mypartnerkey';

	ok ( defined ($partner_api) && ref $partner_api eq 'WWW::Codeguard::Partner', "Partner API object creation" );
	ok ( $partner_api->get_api_url() eq $api_url,  "Codeguard API url");
	ok ( $partner_api->get_partner_key() eq $partner_key, "Codeguard partner key");
};

subtest "User API object creation" => sub {
	my $user_api = CommonSubs::initiate_api_user();
	my $user_key    = $config->{user_api}->{api_key}              || 'myuserkey';
	my $user_secret = $config->{user_api}->{api_secret}           || 'myusersecret';
	my $user_access_secret = $config->{user_api}->{access_secret} || 'myuseraccesssecret';
	my $user_access_token  = $config->{user_api}->{access_token}  || 'myuseraccesstoken';

	ok ( defined ($user_api) && ref $user_api eq 'WWW::Codeguard::User', "User API object creation" );
	ok ( $user_api->get_api_url() eq $api_url,  "Codeguard API url");
	ok ( $user_api->get_api_key() eq $user_key, "Codeguard user api key");
	ok ( $user_api->get_api_secret() eq $user_secret, "Codeguard user api secret");
	ok ( $user_api->get_access_secret() eq $user_access_secret, "Codeguard user access secret");
	ok ( $user_api->get_access_token() eq $user_access_token, "Codeguard user access token");
};

subtest "Partner and User API object creation" => sub {
	my $apis = CommonSubs::initiate_api_both();
	ok ( defined ($apis) && (ref $apis eq 'ARRAY' && scalar(@{$apis}) == 2), "Both APIs initialized");
	ok ( defined ($apis->[0]) && ref $apis->[0] eq 'WWW::Codeguard::Partner', "Partner API object creation" );
	ok ( defined ($apis->[1]) && ref $apis->[1] eq 'WWW::Codeguard::User', "User API object creation" );
};

done_testing;
