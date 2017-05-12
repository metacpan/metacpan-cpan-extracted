package CommonSubs;

use 5.006;
use strict;

use FindBin;
use JSON qw(decode_json);

sub read_config {

	my $path = shift || $FindBin::Bin."/config/";
	my $json;
	eval {
		local $/;
		open( my $fh, '<', "$path/TEST_INFO.json" );
		my $json_text = <$fh>;
		$json = decode_json($json_text);
	};
	if (not $@ and $json) {
		return $json;
	}
	return;
}

sub initiate_api_partner {

	require WWW::Codeguard;
	my $config = read_config() || {};

	my $api = WWW::Codeguard->new(
		{
			api_url => $config->{api_url} || 'http://testing-codeguard.not.real.dns',
			partner => {
				partner_key => $config->{partner_api}->{partner_key} || 'mypartnerkey',
			},
		}
	);

	return $api;
}

sub initiate_api_user {

	require WWW::Codeguard;
	my $config = read_config() || {};

	my $api = WWW::Codeguard->new(
		{
			api_url => $config->{api_url} || 'http://testing-codeguard.not.real.dns',
			user    => {
				api_key       => $config->{user_api}->{api_key}       || 'myuserkey',
				api_secret    => $config->{user_api}->{api_secret}    || 'myusersecret',
				access_secret => $config->{user_api}->{access_secret} || 'myuseraccesssecret',
				access_token  => $config->{user_api}->{access_token}  || 'myuseraccesstoken',
			},
		}
	);

	return $api;
}

sub initiate_api_both {

	require WWW::Codeguard;
	my $config = read_config() || {};

	my @apis = WWW::Codeguard->new(
		{
			api_url => $config->{api_url} || 'http://testing-codeguard.not.real.dns',
			user    => {
				api_key       => $config->{user_api}->{api_key}       || 'myuserkey',
				api_secret    => $config->{user_api}->{api_secret}    || 'myusersecret',
				access_secret => $config->{user_api}->{access_secret} || 'myuseraccesssecret',
				access_token  => $config->{user_api}->{access_token}  || 'myuseraccesstoken',
			},
			partner => {
				partner_key => $config->{partner_api}->{partner_key}  || 'mypartnerkey',
			},
		}
	);

	return \@apis;
}

sub random_str {

	my $limit    = shift || 8;
	my $possible = 'abcdefghijkmnpqrstuvwxyz0123456789';
	my $string   = '';
	while (length($string) < $limit) {
		$string .= substr( $possible, ( int( rand( length($possible) ) ) ), 1 );
	}
	return $string;
}

1;
