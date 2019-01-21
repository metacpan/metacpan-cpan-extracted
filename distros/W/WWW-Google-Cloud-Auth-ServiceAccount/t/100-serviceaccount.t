use Test::More;
use WWW::Google::Cloud::Auth::ServiceAccount;
use HTTP::Response;
use JSON;
use feature 'state';
use Crypt::JWT qw(decode_jwt);

my $public_key = <<ENDKEY;
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDIgnSESkWlGsciNgH45DkXqbpV
mvsrwfyHNTZwXQYVJNXjmqdpw2AsWDvvHwdtAqh8SWPgBtE8NmjsxqS7DxBBI5ku
5Jpt8CwplOA4qt5GLt3/Fc7WDTf8KvZUwuLErp9F0+5O8kOr5SqMARR9Ko60PmJx
NUm2cBx6TYIZ6qoXZQIDAQAB
-----END PUBLIC KEY-----
ENDKEY

{
    no warnings 'once', 'redefine';

    my $call_counter = 0;

    my $mock_token_response = sub {
        my ($self, $url, $args) = @_;

        $call_counter++;

        is($url, "http://auth.url.com", "token request - oauth url");
        my $jwt = delete $args->{assertion};
        my $jwt_decoded = decode_jwt(token => $jwt, key => \$public_key);
        is_deeply(
            $jwt_decoded,
			{
                'aud' => 'https://www.googleapis.com/oauth2/v4/token',
                'exp' => '14533990600',
                'scope' => 'https://www.googleapis.com/auth/cloud-platform',
                'iat' => '14533990001',
                'iss' => 'johndoe@foobar.iam.gserviceaccount.com'
			},
            'JWT'
        );
        is_deeply(
            $args,
            {
                grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            },
            "grant_type"
        );

        my $token = shift @{state $tokens = [
            'token1',
            'token2',
            'token3',
        ]};
        return HTTP::Response->new(200, undef, [], '{"access_token":"'.$token.'","expires_in":"3600"}');
    };

    local *LWP::UserAgent::post = $mock_token_response;

    my $auth = WWW::Google::Cloud::Auth::ServiceAccount->new(
        credentials_path => 't/data/test_creds.json',
        auth_url => 'http://auth.url.com',
        clock    => sub {
			state $time = 14533990000;
			return $time++;
        },
    );

    is_deeply(scalar $auth->get_token(), "token1", "right results");
    is($call_counter, 1, "There was 1 request to fetch the token");

    is_deeply(scalar $auth->get_token(), "token1", "Cached token returned");
    is($call_counter, 1, "Cached token, no new request sent");

    $auth = WWW::Google::Cloud::Auth::ServiceAccount->new(
        credentials_path => 't/data/test_creds.json',
        auth_url => 'http://auth.url.com',
        clock    => sub {
            shift @{state $return_values = [
                14533990000,
                14533990001,
                14533990001,
                14534000000, # expiry
                14533990000,
                14533990001,
                14534000001,
            ]};
        },
    );

    is($auth->get_token(), "token2", "right token");
    is($call_counter, 2, "There was 1 request to fetch the token");

    is($auth->get_token(), "token3", "right token");
    is($call_counter, 3, "Token expiry");
}

done_testing;
