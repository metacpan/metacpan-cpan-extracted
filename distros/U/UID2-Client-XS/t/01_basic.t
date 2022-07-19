use strict;
use warnings;
use lib '.';

use Test::More;
use Crypt::Misc qw(encode_b64 decode_b64);

use UID2::Client::XS;
use UID2::Client::XS::DecryptionStatus;
use UID2::Client::XS::EncryptionStatus;
use UID2::Client::XS::IdentityScope;
use UID2::Client::XS::IdentityType;
use UID2::Client::XS::Timestamp;

use t::TestUtils;

my $master_key_id = 164;
my $site_key_id = 165;
my $site_id = 9000;
my $site_id2 = 2;
my $master_secret = pack('C32',
    139, 37, 241, 173, 18, 92, 36, 232,
    165, 168, 23, 18, 38, 195, 123, 92,
    160, 136, 185, 40, 91, 173, 165, 221,
    168, 16, 169, 164, 38, 139, 8, 155,
);
my $site_secret = pack('C32',
    32, 251, 7, 194, 132, 154, 250, 86,
    202, 116, 104, 29, 131, 192, 139, 215,
    48, 164, 11, 65, 226, 110, 167, 14,
    108, 51, 254, 125, 65, 24, 23, 133,
);
my $now = UID2::Client::XS::Timestamp->now();
my $master_key = {
    id        => $master_key_id,
    site_id   => -1,
    created   => $now->add_days(-1),
    activates => $now,
    expires   => $now->add_days(1),
    secret    => $master_secret,
};
my $site_key = {
    id        => $site_key_id,
    site_id   => $site_id,
    created   => $now->add_days(-10),
    activates => $now->add_days(-9),
    expires   => $now->add_days(1),
    secret    => $site_secret,
};
my $example_uid = 'ywsvDNINiZOVSsfkHpLpSJzXzhr6Jx9Z/4Q0+lsEUvM=';
my $secret_key = 'ioG3wKxAokmp+rERx6A4kM/13qhyolUXIu14WN16Spo=';
my $client_options = {
    endpoint => 'ep',
    auth_key => 'ak',
    secret_key => $secret_key,
    identity_scope => UID2::Client::XS::IdentityScope::UID2,
};

subtest SmokeTest => sub {
    my $client = UID2::Client::XS->new($client_options);
    isa_ok $client, 'UID2::Client::XS';
    my $json = t::TestUtils::key_set_to_json($master_key, $site_key);
    my $refresh_result = $client->refresh_json($json);
    ok $refresh_result->{is_success};
    my $advertising_token = t::TestUtils::encrypt_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_type => UID2::Client::XS::IdentityType::EMAIL,
        identity_scope => UID2::Client::XS::IdentityScope::UID2,
        master_key => { id => $master_key_id, secret => $master_key->{secret} },
        site_key => { id => $site_key_id, secret => $site_key->{secret} },
    );
    my $result = $client->decrypt($advertising_token);
    ok $result->{is_success};
    is $result->{status}, UID2::Client::XS::DecryptionStatus::SUCCESS();
    is $result->{uid}, $example_uid;
};

subtest EmptyKeyContainer => sub {
    my $client = UID2::Client::XS->new($client_options);
    my $advertising_token = t::TestUtils::encrypt_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_type => UID2::Client::XS::IdentityType::EMAIL,
        identity_scope => UID2::Client::XS::IdentityScope::UID2,
        master_key => { id => $master_key_id, secret => $master_key->{secret} },
        site_key => { id => $site_key_id, secret => $site_key->{secret} },
    );
    my $result = $client->decrypt($advertising_token);
    ok !$result->{is_success};
    is $result->{status}, UID2::Client::XS::DecryptionStatus::NOT_INITIALIZED();
};

subtest NotAuthorizedForKey => sub {
    my $client = UID2::Client::XS->new($client_options);
    my $advertising_token = t::TestUtils::encrypt_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_type => UID2::Client::XS::IdentityType::EMAIL,
        identity_scope => UID2::Client::XS::IdentityScope::UID2,
        master_key => { id => $master_key_id, secret => $master_key->{secret} },
        site_key => { id => $site_key_id, secret => $site_key->{secret} },
    );
    my $another_master_key = {
        id        => $master_key_id + $site_key_id + 1,
        site_id   => -1,
        created   => $now,
        activates => $now->add_days(-2),
        expires   => $now->add_days(-1),
        secret    => $master_secret,
    };
    my $another_site_key = {
        id        => $master_key_id + $site_key_id + 2,
        site_id   => $site_id,
        created   => $now,
        activates => $now->add_days(-2),
        expires   => $now->add_days(-1),
        secret    => $site_secret,
    };
    $client->refresh_json(t::TestUtils::key_set_to_json($another_master_key, $another_site_key));
    my $res = $client->decrypt($advertising_token, UID2::Client::XS::Timestamp->now());
    ok !$res->{is_success};
    is $res->{status}, UID2::Client::XS::DecryptionStatus::KEYS_NOT_SYNCED();
};

subtest InvalidPayload => sub {
    my $client = UID2::Client::XS->new($client_options);
    my $advertising_token = t::TestUtils::encrypt_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_type => UID2::Client::XS::IdentityType::EMAIL,
        identity_scope => UID2::Client::XS::IdentityScope::UID2,
        master_key => { id => $master_key_id, secret => $master_key->{secret} },
        site_key => { id => $site_key_id, secret => $site_key->{secret} },
    );
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $site_key));
    is $client->decrypt(substr($advertising_token, 0, length($advertising_token) -1), $now)->{status},
            UID2::Client::XS::DecryptionStatus::INVALID_PAYLOAD;
    is $client->decrypt(substr($advertising_token, 0, length($advertising_token) -4), $now)->{status},
            UID2::Client::XS::DecryptionStatus::INVALID_PAYLOAD;
    is $client->decrypt(substr($advertising_token, 0, 4), $now)->{status},
            UID2::Client::XS::DecryptionStatus::INVALID_PAYLOAD;
};

subtest TokenExpiryAndCustomNow => sub {
    my $expiry = $now->add_days(-6);
    my $client = UID2::Client::XS->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $site_key));
    my $advertising_token = t::TestUtils::encrypt_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_type => UID2::Client::XS::IdentityType::EMAIL,
        identity_scope => UID2::Client::XS::IdentityScope::UID2,
        master_key => { id => $master_key_id, secret => $master_key->{secret} },
        site_key => { id => $site_key_id, secret => $site_key->{secret} },
        token_expiry => $expiry,
    );
    my $result = $client->decrypt($advertising_token, $expiry->add_seconds(1));
    ok !$result->{is_success};
    is $result->{status}, UID2::Client::XS::DecryptionStatus::EXPIRED_TOKEN();

    $result = $client->decrypt($advertising_token, $expiry->add_seconds(-1));
    ok $result->{is_success};
    is $result->{uid}, $example_uid;
};

subtest SpecificSiteId => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($site_key));
    my $encrypted = $client->encrypt_data($data, { site_id => $site_id });
    ok $encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::SUCCESS();
    my $decrypted = $client->decrypt_data($encrypted->{encrypted_data});
    ok $decrypted->{is_success};
    is $decrypted->{status}, UID2::Client::XS::DecryptionStatus::SUCCESS();
    is $decrypted->{decrypted_data}, $data;
};

subtest SiteIdFromToken => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $site_key));
    my $advertising_token = t::TestUtils::encrypt_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_type => UID2::Client::XS::IdentityType::EMAIL,
        identity_scope => UID2::Client::XS::IdentityScope::UID2,
        master_key => { id => $master_key_id, secret => $master_key->{secret} },
        site_key => { id => $site_key_id, secret => $site_key->{secret} },
    );
    my $encrypted = $client->encrypt_data($data, { advertising_token => $advertising_token });
    ok $encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::SUCCESS();
    $client->refresh_json(t::TestUtils::key_set_to_json($site_key));
    my $decrypted = $client->decrypt_data($encrypted->{encrypted_data});
    ok $decrypted->{is_success};
    is $decrypted->{status}, UID2::Client::XS::DecryptionStatus::SUCCESS();
    is $decrypted->{decrypted_data}, $data;
};

subtest SiteIdFromTokenCustomSiteKeySiteId => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $site_key));
    my $advertising_token = t::TestUtils::encrypt_token_v3(
        id_str => $example_uid,
        site_id => $site_id2,
        identity_type => UID2::Client::XS::IdentityType::EMAIL,
        identity_scope => UID2::Client::XS::IdentityScope::UID2,
        master_key => { id => $master_key_id, secret => $master_key->{secret} },
        site_key => { id => $site_key_id, secret => $site_key->{secret} },
    );
    my $encrypted = $client->encrypt_data($data, { advertising_token => $advertising_token });
    ok $encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::SUCCESS();
    $client->refresh_json(t::TestUtils::key_set_to_json($site_key));
    my $decrypted = $client->decrypt_data($encrypted->{encrypted_data});
    ok $decrypted->{is_success};
    is $decrypted->{status}, UID2::Client::XS::DecryptionStatus::SUCCESS();
    is $decrypted->{decrypted_data}, $data;
};

subtest SiteIdAndTokenSet => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $site_key));
    my $advertising_token = t::TestUtils::encrypt_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_type => UID2::Client::XS::IdentityType::EMAIL,
        identity_scope => UID2::Client::XS::IdentityScope::UID2,
        master_key => { id => $master_key_id, secret => $master_key->{secret} },
        site_key => { id => $site_key_id, secret => $site_key->{secret} },
    );
    eval {
        $client->encrypt_data($data, { advertising_token => $advertising_token, site_id => $site_id });
    };
    ok $@; # only one of siteId or advertisingToken can be specified
};

subtest MultipleSiteKeys => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    my $make_key = sub {
        my @values = @_;
        my @fields = qw(id site_id created activates expires secret);
        +{ map { $fields[$_] => $values[$_] } (0 .. scalar(@fields) - 1) };
    };
    my $make_key_secret = sub { pack 'C32', map { $_[0] } 1..32 };
    my @keys = (
        &$make_key(0, $site_id, $now, $now->add_days(3),  $now->add_days(10), &$make_key_secret(0)),
        &$make_key(1, $site_id, $now, $now->add_days(-4), $now->add_days(10), &$make_key_secret(1)),
        &$make_key(2, $site_id, $now, $now->add_days(-2), $now->add_days(10), &$make_key_secret(2)),
        &$make_key(3, $site_id, $now, $now->add_days(-4), $now->add_days(-3), &$make_key_secret(3)),
        &$make_key(4, $site_id, $now, $now->add_days(-4), $now->add_days(1),  &$make_key_secret(4)),
        &$make_key(5, $site_id, $now, $now->add_days(-5), $now->add_days(2),  &$make_key_secret(5)),
        &$make_key(6, $site_id, $now, $now->add_days(-1), $now->add_days(2),  &$make_key_secret(6)),
    );
    my $test = sub {
        my ($now, $key) = @_;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $client->refresh_json(t::TestUtils::key_set_to_json(@keys));
        my $encrypted = $client->encrypt_data($data, { site_id => $site_id, now => $now });
        is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::SUCCESS;
        $client->refresh_json(t::TestUtils::key_set_to_json($key));
        my $decrypted = $client->decrypt_data($encrypted->{encrypted_data});
        is $decrypted->{status}, UID2::Client::XS::DecryptionStatus::SUCCESS;
        is $decrypted->{decrypted_data}, $data;
    };
    &$test($now->add_days(-5), $keys[5]);
    &$test($now->add_days(-4), $keys[4]);
    &$test($now->add_days(-3), $keys[4]);
    &$test($now->add_days(-2), $keys[2]);
    &$test($now->add_days(-1), $keys[6]);
    &$test($now->add_days( 0), $keys[6]);
    &$test($now->add_days( 1), $keys[6]);
    &$test($now->add_days( 2), $keys[2]);
    &$test($now->add_days( 3), $keys[0]);
};

subtest TokenDecryptFailed => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $site_key));
    my $encrypted = $client->encrypt_data($data, { advertising_token => 'bogus-token' });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::TOKEN_DECRYPT_FAILURE;
};


subtest TokenDecryptKeyExpired => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    my $key = {
        id        => $site_key_id,
        site_id   => $site_id2,
        created   => $now,
        activates => $now->add_days(-2),
        expires   => $now->add_days(-1),
        secret    => $site_secret,
    };
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $key));
    my $advertising_token = t::TestUtils::encrypt_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_type => UID2::Client::XS::IdentityType::EMAIL,
        identity_scope => UID2::Client::XS::IdentityScope::UID2,
        master_key => { id => $master_key_id, secret => $master_key->{secret} },
        site_key => { id => $key->{id}, secret => $key->{secret} },
    );
    my $encrypted = $client->encrypt_data($data, { advertising_token => $advertising_token });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::NOT_AUTHORIZED_FOR_KEY;
};

subtest NoSiteKey => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $site_key));
    my $encrypted = $client->encrypt_data($data, { site_id => $site_id2 });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::NOT_AUTHORIZED_FOR_KEY;
};

subtest SiteKeyExpired => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    my $key = { %$site_key, expires => $now->add_days(-1) };
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $key));
    my $encrypted = $client->encrypt_data($data, { site_id => $site_id });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::NOT_AUTHORIZED_FOR_KEY;
};

subtest SiteKeyInactive => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    my $key = { %$site_key, activates => $now->add_days(1) };
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $key));
    my $encrypted = $client->encrypt_data($data, { site_id => $site_id });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::NOT_AUTHORIZED_FOR_KEY;
};

subtest SiteKeyInactiveCustomNow => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $site_key));
    my $encrypted = $client->encrypt_data($data, {
        site_id => $site_id,
        now => $site_key->{activates}->add_seconds(-1),
    });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::NOT_AUTHORIZED_FOR_KEY;
};

subtest TokenExpired => sub {
    my $expiry = $now->add_days(-6);
    my %params = (token_expiry => $expiry);
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key, $site_key));
    my $advertising_token = t::TestUtils::encrypt_token_v3(
        id_str => $example_uid,
        site_id => $site_id,
        identity_type => UID2::Client::XS::IdentityType::EMAIL,
        identity_scope => UID2::Client::XS::IdentityScope::UID2,
        master_key => { id => $master_key_id, secret => $master_key->{secret} },
        site_key => { id => $site_key_id, secret => $site_key->{secret} },
        %params,
    );
    my $encrypted = $client->encrypt_data($data, { advertising_token => $advertising_token });
    ok !$encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::TOKEN_DECRYPT_FAILURE;

    my $now = $expiry->add_seconds(-1);
    $encrypted = $client->encrypt_data($data, { advertising_token => $advertising_token, now => $now });
    ok $encrypted->{is_success};
    is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::SUCCESS;
    my $decrypted = $client->decrypt_data($encrypted->{encrypted_data});
    ok $decrypted->{is_success};
    is $decrypted->{status}, UID2::Client::XS::DecryptionStatus::SUCCESS;
    is $decrypted->{decrypted_data}, $data;
};

subtest BadPayloadType => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($site_key));
    my $encrypted = $client->encrypt_data($data, { site_id => $site_id });
    is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::SUCCESS;
    my $encrypted_bytes = decode_b64($encrypted->{encrypted_data});
    substr($encrypted_bytes, 0, 1) = 0;
    my $decrypted = $client->decrypt_data(encode_b64($encrypted_bytes));
    is $decrypted->{status}, UID2::Client::XS::DecryptionStatus::INVALID_PAYLOAD_TYPE;
};

subtest BadVersion => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($site_key));
    my $encrypted = $client->encrypt_data($data, { site_id => $site_id });
    is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::SUCCESS;
    my $encrypted_bytes = decode_b64($encrypted->{encrypted_data});
    substr($encrypted_bytes, 1, 1) = 0;
    my $decrypted = $client->decrypt_data(encode_b64($encrypted_bytes));
    is $decrypted->{status}, UID2::Client::XS::DecryptionStatus::VERSION_NOT_SUPPORTED;
};

subtest BadPayload => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($site_key));
    my $encrypted = $client->encrypt_data($data, { site_id => $site_id });
    is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::SUCCESS;
    my $encrypted_bytes = decode_b64($encrypted->{encrypted_data});
    my $encrypted_bytes_larger = $encrypted_bytes;
    $encrypted_bytes_larger .= '1';
    my $decrypted = $client->decrypt_data(encode_b64($encrypted_bytes_larger));
    is $decrypted->{status}, UID2::Client::XS::DecryptionStatus::INVALID_PAYLOAD;

    my $encrypted_bytes_smaller = $encrypted_bytes;
    $encrypted_bytes_smaller =~ s/.\z//;
    $decrypted = $client->decrypt_data(encode_b64($encrypted_bytes_smaller));
    is $decrypted->{status}, UID2::Client::XS::DecryptionStatus::INVALID_PAYLOAD;

    $decrypted = $client->decrypt_data(substr($encrypted_bytes, 0, 4));
    is $decrypted->{status}, UID2::Client::XS::DecryptionStatus::INVALID_PAYLOAD;

    $decrypted = $client->decrypt_data($encrypted_bytes . '0');
    is $decrypted->{status}, UID2::Client::XS::DecryptionStatus::INVALID_PAYLOAD;
};

subtest NoDecryptionKey => sub {
    my $data = pack('C*', 1, 2, 3, 4, 5, 6);
    my $client = UID2::Client::XS->new($client_options);
    $client->refresh_json(t::TestUtils::key_set_to_json($site_key));
    my $encrypted = $client->encrypt_data($data, { site_id => $site_id });
    is $encrypted->{status}, UID2::Client::XS::EncryptionStatus::SUCCESS;
    $client->refresh_json(t::TestUtils::key_set_to_json($master_key));
    my $decrypted = $client->decrypt_data($encrypted->{encrypted_data});
    is $decrypted->{status}, UID2::Client::XS::DecryptionStatus::NOT_AUTHORIZED_FOR_KEY
};

done_testing;
