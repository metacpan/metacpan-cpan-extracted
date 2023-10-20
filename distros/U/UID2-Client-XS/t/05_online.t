use strict;
use warnings;

use Test::More;

use UID2::Client::XS;

my $endpoint   = $ENV{UID2_ENDPOINT};
my $auth_key   = $ENV{UID2_AUTH_KEY};
my $secret_key = $ENV{UID2_SECRET_KEY};
my $uid2_token = $ENV{UID2_TOKEN};

unless ($endpoint && $auth_key && $secret_key && $uid2_token) {
    plan skip_all => '$ENV{UID2_ENDPOINT} and $ENV{UID2_AUTH_KEY} and $ENV{UID2_SECRET_KEY} and $ENV{UID2_TOKEN} are not set';
}

my $client = UID2::Client::XS->new({
    endpoint => $endpoint,
    auth_key => $auth_key,
    secret_key => $secret_key,
});
my $result = $client->refresh();
ok $result->{is_success};
my $decrypted = $client->decrypt($uid2_token);
ok $decrypted->{is_success};
note "uid: $decrypted->{uid}";
note "site_id: $decrypted->{site_id}";
note "established: " . $decrypted->{established}->get_epoch_milli;

my $data = 'Hello, UID 2.0 world!';
my $encrypted = $client->encrypt_data($data, { advertising_token => $uid2_token });
ok $encrypted->{is_success};

$decrypted = $client->decrypt_data($encrypted->{encrypted_data});
ok $decrypted->{is_success};
is $decrypted->{decrypted_data}, $data;

done_testing;
