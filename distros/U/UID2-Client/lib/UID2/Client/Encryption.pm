package UID2::Client::Encryption;
use strict;
use warnings;

use Carp;
use Crypt::Cipher::AES;
use Crypt::Mode::CBC;
use Crypt::AuthEnc::GCM;
use Crypt::Misc qw(encode_b64 decode_b64 decode_b64u);
use Crypt::PRNG qw(random_bytes);

use UID2::Client::AdvertisingTokenVersion;
use UID2::Client::DecryptionStatus;
use UID2::Client::EncryptionStatus;
use UID2::Client::Timestamp;

sub decrypt_token {
    my $token = shift;
    my @args = @_;
    if (length $token < 4) {
        return _error_response(UID2::Client::DecryptionStatus::INVALID_PAYLOAD);
    }
    my $result = eval {
        my $header = substr $token, 0, 4;
        my $header_bytes;
        if ($header =~ /[\-_]/) {
            $header_bytes = decode_b64u($header);
        } else {
            $header_bytes = decode_b64($header);
        }
        if (!defined $header_bytes or length $header_bytes < 2) {
            return _error_response(UID2::Client::DecryptionStatus::INVALID_PAYLOAD);
        }
        if (ord(substr($header_bytes, 0, 1)) == 2) {
            my $bytes = decode_b64($token);
            return _error_response(UID2::Client::DecryptionStatus::INVALID_PAYLOAD) unless defined $bytes;
            return _decrypt_token_v2($bytes, @args);
        } elsif (ord(substr($header_bytes, 1, 1)) == UID2::Client::AdvertisingTokenVersion::V3) {
            my $bytes = decode_b64($token);
            return _error_response(UID2::Client::DecryptionStatus::INVALID_PAYLOAD) unless defined $bytes;
            return _decrypt_token_v3($bytes, @args);
        } elsif (ord(substr($header_bytes, 1, 1)) == UID2::Client::AdvertisingTokenVersion::V4) {
            # same as V3 but use Base64URL encoding
            my $bytes = decode_b64u($token);
            return _error_response(UID2::Client::DecryptionStatus::INVALID_PAYLOAD) unless defined $bytes;
            return _decrypt_token_v3($bytes, @args);
        } else {
            return _error_response(UID2::Client::DecryptionStatus::VERSION_NOT_SUPPORTED);
        }
    }; if ($@) {
        return _error_response(UID2::Client::DecryptionStatus::INVALID_PAYLOAD);
    }
    $result;
}

sub _decrypt_token_v2 {
    my ($bytes, $now, $keys) = @_;
    if (!$keys) {
        return _error_response(UID2::Client::DecryptionStatus::NOT_INITIALIZED);
    }
    $now //= UID2::Client::Timestamp->now;
    if (!$keys->is_valid($now)) {
        return _error_response(UID2::Client::DecryptionStatus::KEYS_NOT_SYNCED);
    }
    my ($version, $master_key_id, $master_payload_encrypted) = unpack 'a N! a*', $bytes;
    if (ord($version) != 2) {
        return _error_response(UID2::Client::DecryptionStatus::VERSION_NOT_SUPPORTED);
    }
    my $master_key = $keys->get($master_key_id);
    unless ($master_key) {
        return _error_response(UID2::Client::DecryptionStatus::NOT_AUTHORIZED_FOR_KEY);
    }
    my $master_payload = decrypt_cbc($master_payload_encrypted, $master_key->secret);
    unless (defined $master_payload) {
        return _error_response(UID2::Client::DecryptionStatus::INVALID_PAYLOAD);
    }
    my ($expires, $site_key_id, $identity_encrypted) = unpack 'q> N! a*', $master_payload;
    my $site_key = $keys->get($site_key_id);
    unless ($site_key) {
        return _error_response(UID2::Client::DecryptionStatus::NOT_AUTHORIZED_FOR_KEY);
    }
    my $identity = decrypt_cbc($identity_encrypted, $site_key->secret);
    unless (defined $identity) {
        return _error_response(UID2::Client::DecryptionStatus::INVALID_PAYLOAD);
    }
    my ($site_id, $id_len) = unpack 'N! N!', $identity;
    my ($id_str, $established) = unpack "x4 x4 a${id_len} x4 q>", $identity;
    my $result = {
        site_id => $site_id,
        site_key_site_id => $site_key->site_id,
        established => UID2::Client::Timestamp->from_epoch_milli($established),
    };
    if ($expires < $now->get_epoch_milli) {
        $result->{is_success} = undef;
        $result->{status} = UID2::Client::DecryptionStatus::EXPIRED_TOKEN;
    } else {
        $result->{is_success} = 1;
        $result->{status} = UID2::Client::DecryptionStatus::SUCCESS;
        $result->{uid} = $id_str;
    }
    $result;
}

sub _decrypt_token_v3 {
    my ($bytes, $now, $keys, $identity_scope) = @_;
    if (!$keys) {
        return _error_response(UID2::Client::DecryptionStatus::NOT_INITIALIZED);
    }
    $now //= UID2::Client::Timestamp->now;
    if (!$keys->is_valid($now)) {
        return _error_response(UID2::Client::DecryptionStatus::KEYS_NOT_SYNCED);
    }
    my ($prefix, $master_key_id, $master_payload_encrypted) = unpack 'a x N! a*', $bytes;
    if (_decode_identity_scope($prefix) != $identity_scope) {
        return _error_response(UID2::Client::DecryptionStatus::INVALID_IDENTITY_SCOPE);
    }
    my $master_key = $keys->get($master_key_id);
    unless ($master_key) {
        return _error_response(UID2::Client::DecryptionStatus::NOT_AUTHORIZED_FOR_KEY);
    }
    if (length($master_payload_encrypted) > 256) {
        return _error_response(UID2::Client::DecryptionStatus::INVALID_PAYLOAD);
    }
    my $master_payload = decrypt_gcm($master_payload_encrypted, $master_key->secret);
    unless (defined $master_payload) {
        return _error_response(UID2::Client::DecryptionStatus::INVALID_PAYLOAD);
    }
    my ($expires, $site_key_id, $site_payload_encrypted) = unpack 'q> x8 x4 x x4 x4 N! a*', $master_payload;
    my $site_key = $keys->get($site_key_id);
    unless ($site_key) {
        return _error_response(UID2::Client::DecryptionStatus::NOT_AUTHORIZED_FOR_KEY);
    }
    my $site_payload = decrypt_gcm($site_payload_encrypted, $site_key->secret);
    unless (defined $site_payload) {
        return _error_response(UID2::Client::DecryptionStatus::INVALID_PAYLOAD);
    }
    my ($site_id, $established, $identity_bytes) = unpack 'N! x8 x4 x4 q> x8 a*', $site_payload;
    my $result = {
        site_id => $site_id,
        site_key_site_id => $site_key->site_id,
        established => UID2::Client::Timestamp->from_epoch_milli($established),
    };
    if ($expires < $now->get_epoch_milli) {
        $result->{is_success} = undef;
        $result->{status} = UID2::Client::DecryptionStatus::EXPIRED_TOKEN;
    } else {
        $result->{is_success} = 1;
        $result->{status} = UID2::Client::DecryptionStatus::SUCCESS;
        $result->{uid} = encode_b64($identity_bytes);
    }
    $result;
}

my $EncryptedDataType = 128;

my $EncryptedDataVersion = 1;

my $EncryptedDataTypeV3 = 96;

my $EncryptedDataVersionV3 = 112;

my $CBC_IV_LEN = 16;

my $GCM_IV_LEN = 12;

my $GCM_AUTHTAG_LEN = 16;

sub encrypt_data {
    my $result = eval {
        _encrypt_data_v3(@_);
    }; if ($@) {
        return _error_response(UID2::Client::EncryptionStatus::ENCRYPTION_FAILURE);
    }
    $result;
}

sub _encrypt_data_v3 {
    my ($data, $request) = @_;
    my $keys = $request->{keys};
    my $key = $request->{key};
    if ($keys && $key) {
        croak 'only one of keys and key can be specified';
    }
    my $now = $request->{now} // UID2::Client::Timestamp->now;
    my $site_id;
    if (!$key) {
        if (!$keys) {
            return _error_response(UID2::Client::EncryptionStatus::NOT_INITIALIZED);
        }
        if (!$keys->is_valid($now)) {
            return _error_response(UID2::Client::EncryptionStatus::KEYS_NOT_SYNCED);
        }
        my $site_key_site_id;
        if (defined $request->{site_id} && length $request->{advertising_token}) {
            croak 'only one of siteId or advertisingToken can be specified';
        } elsif (defined $request->{site_id}) {
            $site_id = $request->{site_id};
            $site_key_site_id = $site_id;
        } else {
            my $decrypted = decrypt_token($request->{advertising_token}, $now, $keys, $request->{identity_scope});
            if (!$decrypted->{is_success}) {
                return _error_response(UID2::Client::EncryptionStatus::TOKEN_DECRYPT_FAILURE);
            }
            $site_id = $decrypted->{site_id};
            $site_key_site_id = $decrypted->{site_key_site_id};
        }
        $key = $keys->get_active_site_key($site_key_site_id, $now);
        unless ($key) {
            return _error_response(UID2::Client::EncryptionStatus::NOT_AUTHORIZED_FOR_KEY);
        }
    } elsif (!$key->is_active($now)) {
        return _error_response(UID2::Client::EncryptionStatus::KEY_INACTIVE);
    } else {
        $site_id = $key->site_id;
    }

    my $iv = $request->{initialization_vector};
    if (defined $iv && length($iv) != $GCM_IV_LEN) {
        croak "initialization vector size must be $GCM_IV_LEN";
    }

    my $payload = pack 'q> N! a*', $now->get_epoch_milli, $site_id, $data;
    my $identity = $EncryptedDataTypeV3 | ($request->{identity_scope} << 4) | 0xB;
    my $version = $EncryptedDataVersionV3;
    my $res = pack 'C C N! a*', $identity, $version, $key->id, encrypt_gcm($payload, $key->secret, $iv);
    +{
        is_success => 1,
        status => UID2::Client::EncryptionStatus::SUCCESS,
        encrypted_data => encode_b64($res),
    };
}

sub decrypt_data {
    my $encrypted_data = shift;
    my $result = eval {
        my $bytes = decode_b64($encrypted_data);
        unless (defined $bytes) {
            return _error_response(UID2::Client::DecryptionStatus::INVALID_PAYLOAD);
        }
        if ((ord(substr($bytes, 0, 1)) & 224) == $EncryptedDataTypeV3) {
            _decrypt_data_v3($bytes, @_);
        } else {
            _decrypt_data_v2($bytes, @_);
        }
    }; if ($@) {
        return _error_response(UID2::Client::DecryptionStatus::INVALID_PAYLOAD);
    }
    $result;
}

sub _decrypt_data_v2 {
    my ($encrypted_bytes, $keys) = @_;
    my ($type, $version, $encrypted_at, $site_id, $key_id, $bytes) = unpack 'a a q> N! N! a*', $encrypted_bytes;
    if (ord($type) != $EncryptedDataType) {
        return _error_response(UID2::Client::DecryptionStatus::INVALID_PAYLOAD_TYPE);
    }
    if (ord($version) != $EncryptedDataVersion) {
        return _error_response(UID2::Client::DecryptionStatus::VERSION_NOT_SUPPORTED);
    }
    my $key = $keys->get($key_id);
    unless ($key) {
        return _error_response(UID2::Client::DecryptionStatus::NOT_AUTHORIZED_FOR_KEY);
    }
    my $data = decrypt_cbc($bytes, $key->secret);
    +{
        is_success => 1,
        status => UID2::Client::DecryptionStatus::SUCCESS,
        decrypted_data => $data,
        encrypted_at => UID2::Client::Timestamp->from_epoch_milli($encrypted_at),
    };
}

sub _decrypt_data_v3 {
    my ($encrypted_bytes, $keys, $identity_scope) = @_;
    my ($identity, $version, $key_id, $bytes) = unpack 'a a N! a*', $encrypted_bytes;
    if (_decode_identity_scope($identity) != $identity_scope) {
        return _error_response(UID2::Client::DecryptionStatus::INVALID_IDENTITY_SCOPE);
    }
    if (ord($version) != $EncryptedDataVersionV3) {
        return _error_response(UID2::Client::DecryptionStatus::VERSION_NOT_SUPPORTED);
    }
    my $key = $keys->get($key_id);
    unless ($key) {
        return _error_response(UID2::Client::DecryptionStatus::NOT_AUTHORIZED_FOR_KEY);
    }
    my $payload = decrypt_gcm($bytes, $key->secret);
    unless (defined $payload) {
        return _error_response(UID2::Client::DecryptionStatus::INVALID_PAYLOAD);
    }
    my ($encrypted_at, $data) = unpack 'q> x4 a*', $payload;
    +{
        is_success => 1,
        status => UID2::Client::DecryptionStatus::SUCCESS,
        decrypted_data => $data,
        encrypted_at => UID2::Client::Timestamp->from_epoch_milli($encrypted_at),
    };
}

sub _error_response {
    +{
        is_success => undef,
        status => $_[0],
    };
}

sub _decode_identity_scope {
    (ord($_[0]) >> 4) & 1;
}

sub encrypt_cbc {
    my ($data, $secret, $iv) = @_;
    my $cipher = Crypt::Mode::CBC->new('AES');
    $iv //= random_bytes($CBC_IV_LEN);
    $iv . $cipher->encrypt($data, $secret, $iv);
}

sub decrypt_cbc {
    my ($data, $secret) = @_;
    my $iv = substr $data, 0, $CBC_IV_LEN;
    my $cipher = Crypt::Mode::CBC->new('AES');
    my $payload = substr $data, $CBC_IV_LEN;
    $cipher->decrypt($payload, $secret, $iv);
}

sub encrypt_gcm {
    my ($data, $secret, $iv) = @_;
    $iv //= random_bytes($GCM_IV_LEN);
    my $ae = Crypt::AuthEnc::GCM->new('AES', $secret, $iv);
    my $ciphertext = $ae->encrypt_add($data);
    $iv . $ciphertext . $ae->encrypt_done();
}

sub decrypt_gcm {
    my ($data, $secret) = @_;
    my $iv = substr $data, 0, $GCM_IV_LEN;
    my $ae = Crypt::AuthEnc::GCM->new('AES', $secret, $iv);
    my $payload = substr $data, $GCM_IV_LEN, -$GCM_AUTHTAG_LEN;
    my $plaintext = $ae->decrypt_add($payload);
    my $authtag = substr $data, -$GCM_AUTHTAG_LEN, $GCM_AUTHTAG_LEN;
    $ae->decrypt_done($authtag) or croak 'auth data check failed';
    $plaintext;
}

1;
__END__
