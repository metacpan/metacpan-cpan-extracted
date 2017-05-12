use strict;
use warnings;
use Test::More;
use Data::Dumper 'Dumper';
use Digest::SHA 'hmac_sha1_base64';
use JSON::PP 'decode_json';
use URI;
use URI::Escape 'uri_escape_utf8', 'uri_unescape';
use WWW::OAuth;
use WWW::OAuth::Util 'form_urldecode', 'form_urlencode', 'oauth_request';

my $api_key = $ENV{TWITTER_API_KEY};
my $api_secret = $ENV{TWITTER_API_SECRET};
my $token = $ENV{TWITTER_ACCESS_TOKEN};
my $token_secret = $ENV{TWITTER_ACCESS_SECRET};

my $oauth_base_url = 'https://api.twitter.com/oauth/';
my $api_base_url = 'https://api.twitter.com/1.1/';

my $test_online;
if ($ENV{AUTHOR_TESTING} and defined $api_key and defined $api_secret and defined $token and defined $token_secret) {
	note 'Running online test for Twitter OAuth 1.0';
	$test_online = 1;
	require HTTP::Tiny;
	HTTP::Tiny->VERSION('0.014');
} else {
	note 'Running offline test for Twitter OAuth 1.0; set AUTHOR_TESTING and TWITTER_API_KEY/TWITTER_API_SECRET/TWITTER_ACCESS_TOKEN/TWITTER_ACCESS_SECRET for online test';
	$api_key = 'foo';
	$api_secret = 'bar';
	$token = 'baz';
	$token_secret = 'ban';
}

# OAuth token request
my $oauth_request_url = $oauth_base_url . 'request_token';
my $oauth_request = _request(POST => $oauth_request_url);

my $auth = WWW::OAuth->new(client_id => $api_key, client_secret => $api_secret);
my $auth_header = $auth->authorization_header($oauth_request, { oauth_callback => 'oob' });
like $auth_header, qr/^OAuth oauth_/, 'Formed Authorization header';
$oauth_request->header(Authorization => $auth_header);
is $auth_header, $oauth_request->header('Authorization'), 'Authorization header has been set';

my $oauth_params = _parse_oauth_header($auth_header);
is $oauth_params->{oauth_consumer_key}, $api_key, 'oauth_consumer_key is set to API key';
ok defined($oauth_params->{oauth_nonce}), 'oauth_nonce is set';
is $oauth_params->{oauth_signature_method}, 'HMAC-SHA1', 'oauth_signature_method is set to HMAC-SHA1';
ok defined($oauth_params->{oauth_timestamp}), 'oauth_timestamp is set';
is $oauth_params->{oauth_version}, '1.0', 'oauth_version is set to 1.0';
ok defined($oauth_params->{oauth_signature}), 'oauth_signature is set';
is $oauth_params->{oauth_callback}, 'oob', 'oauth_callback is set to "oob"';
ok !defined($oauth_params->{oauth_token}), 'oauth_token is not set';

my $test_signature = _test_signature('POST', $oauth_request_url, $oauth_params, $api_secret);
is $test_signature, $oauth_params->{oauth_signature}, 'signature formed correctly';

my $response;
if ($test_online) {
	my $res = $oauth_request->request_with(HTTP::Tiny->new);
	ok $res->{success}, 'OAuth request successful' or diag Dumper $res;
	$response = $res->{content};
} else {
	$response = q{oauth_token=aaaaaaaaaaaaaaaaaaaaaaaaaaa&oauth_token_secret=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb&oauth_callback_confirmed=true};
}

my %response_params = @{form_urldecode($response)};
is $response_params{oauth_callback_confirmed}, 'true', 'OAuth callback was confirmed';
ok defined(my $request_token = $response_params{oauth_token}), 'got request token';
ok defined(my $request_secret = $response_params{oauth_token_secret}), 'got request secret';

# Verify credentials request
my $verify_url = $api_base_url . 'account/verify_credentials.json';
my $verify_request = _request(GET => $verify_url);

$auth->token($token);
$auth->token_secret($token_secret);
$auth->authenticate($verify_request);
$auth_header = $verify_request->header('Authorization');
ok defined $auth_header, 'Authorization header has been set';

$oauth_params = _parse_oauth_header($auth_header);
is $oauth_params->{oauth_consumer_key}, $api_key, 'oauth_consumer_key is set to API key';
ok defined($oauth_params->{oauth_nonce}), 'oauth_nonce is set';
is $oauth_params->{oauth_signature_method}, 'HMAC-SHA1', 'oauth_signature_method is set to HMAC-SHA1';
ok defined($oauth_params->{oauth_timestamp}), 'oauth_timestamp is set';
is $oauth_params->{oauth_version}, '1.0', 'oauth_version is set to 1.0';
ok defined($oauth_params->{oauth_signature}), 'oauth_signature is set';
is $oauth_params->{oauth_token}, $token, 'oauth_token is set to API access token';

$test_signature = _test_signature('GET', $verify_url, $oauth_params, $api_secret, $token_secret);
is $test_signature, $oauth_params->{oauth_signature}, 'signature formed correctly';

if ($test_online) {
	my $res = $verify_request->request_with(HTTP::Tiny->new);
	ok $res->{success}, 'OAuth request successful' or diag Dumper $res;
	$response = $res->{content};
} else {
	$response = <<'JSON_RESPONSE';
{"id":36885345,"id_str":"36885345","name":"Grinnz","screen_name":"TheGrinnz","location":"CT","description":"nerrrrrd","url":"http:\/\/t.co\/IomLjiiycH","entities":{"url":{"urls":[{"url":"http:\/\/t.co\/IomLjiiycH","expanded_url":"http:\/\/grinnz.net","display_url":"grinnz.net","indices":[0,22]}]},"description":{"urls":[]}},"protected":false,"followers_count":73,"friends_count":74,"listed_count":3,"created_at":"Fri May 01 04:45:52 +0000 2009","favourites_count":0,"utc_offset":-18000,"time_zone":"Quito","geo_enabled":true,"verified":false,"statuses_count":365,"lang":"en","status":{"created_at":"Thu Aug 14 03:05:35 +0000 2014","id":499753673501990912,"id_str":"499753673501990912","text":"@GermanFatass vpssd down, at least one irc server still up","source":"\u003ca href=\"http:\/\/twitter.com\" rel=\"nofollow\"\u003eTwitter Web Client\u003c\/a\u003e","truncated":false,"in_reply_to_status_id":499752682178224128,"in_reply_to_status_id_str":"499752682178224128","in_reply_to_user_id":66307969,"in_reply_to_user_id_str":"66307969","in_reply_to_screen_name":"GermanFatass","geo":null,"coordinates":null,"place":null,"contributors":null,"retweet_count":0,"favorite_count":0,"entities":{"hashtags":[],"symbols":[],"user_mentions":[{"screen_name":"GermanFatass","name":"John ","id":66307969,"id_str":"66307969","indices":[0,13]}],"urls":[]},"favorited":false,"retweeted":false,"lang":"en"},"contributors_enabled":false,"is_translator":false,"is_translation_enabled":false,"profile_background_color":"C6E2EE","profile_background_image_url":"http:\/\/abs.twimg.com\/images\/themes\/theme2\/bg.gif","profile_background_image_url_https":"https:\/\/abs.twimg.com\/images\/themes\/theme2\/bg.gif","profile_background_tile":false,"profile_image_url":"http:\/\/pbs.twimg.com\/profile_images\/221712898\/tux_redhat80_normal.png","profile_image_url_https":"https:\/\/pbs.twimg.com\/profile_images\/221712898\/tux_redhat80_normal.png","profile_link_color":"1F98C7","profile_sidebar_border_color":"C6E2EE","profile_sidebar_fill_color":"DAECF4","profile_text_color":"663B12","profile_use_background_image":true,"has_extended_profile":false,"default_profile":false,"default_profile_image":false,"following":false,"follow_request_sent":false,"notifications":false}
JSON_RESPONSE
}

my $response_data = decode_json $response;
ok defined($response_data->{id_str}), 'Twitter ID returned in response';

sub _request {
	my ($method, $url, $params) = @_;
	my %req = (method => $method, url => $url);
	if (defined $params) {
		if ($method eq 'GET' or $method eq 'HEAD') {
			my $uri = URI->new($url);
			$uri->query_form($params);
			$req{url} = $uri->as_string;
		} else {
			$req{content} = form_urlencode($params);
			$req{headers}{'content-type'} = 'application/x-www-form-urlencoded';
		}
	}
	return oauth_request(Basic => \%req);
}

sub _parse_oauth_header {
	my $auth_header = shift;
	return {} unless defined $auth_header;
	my %oauth_params;
	while ($auth_header =~ m/(\w+)="(.+?)"/g) {
		$oauth_params{$1} = uri_unescape $2;
	}
	return \%oauth_params;
}

sub _test_signature {
	my ($method, $request_url, $oauth_params, $client_secret, $token_secret) = @_;
	my $params_str = join '&', map { $_ . '=' . uri_escape_utf8($oauth_params->{$_}) } grep { defined $oauth_params->{$_} }
		qw(oauth_callback oauth_consumer_key oauth_nonce oauth_signature_method oauth_timestamp oauth_token oauth_version);
	my $base_str = uc($method) . '&' . uri_escape_utf8($request_url) . '&' . uri_escape_utf8($params_str);
	my $signing_key = uri_escape_utf8($client_secret) . '&';
	$signing_key .= uri_escape_utf8($token_secret) if defined $token_secret;
	my $test_signature = hmac_sha1_base64($base_str, $signing_key);
	$test_signature .= '='x(4 - length($test_signature) % 4) if length($test_signature) % 4;
	return $test_signature;
}

done_testing;
