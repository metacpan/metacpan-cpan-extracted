[![Actions Status](https://github.com/spiritloose/uid2-client-perlxs/workflows/test/badge.svg)](https://github.com/spiritloose/uid2-client-perlxs/actions) [![MetaCPAN Release](https://badge.fury.io/pl/UID2-Client-XS.svg)](https://metacpan.org/release/UID2-Client-XS)
# NAME

UID2::Client::XS - Unified ID 2.0 Client for Perl (binding to the UID2 C++ library)

# SYNOPSIS

    use UID2::Client::XS;

    my $client = UID2::Client::XS->new({
        endpoint => '...',
        auth_key => '...',
        secret_key => '...',
    });
    my $result = $client->refresh();
    die $result->{reason} unless $result->{is_success};
    my $decrypted = $client->decrypt($uid2_token);
    if ($result->{is_success}) {
        say $result->{uid};
    }

# DESCRIPTION

This module provides an interface to Unified ID 2.0 API.

# CONSTRUCTOR METHODS

## new

    my $client = UID2::Client::XS->new(\%options);

Creates and returns a new UID2 client with a hashref of options.

Valid options are:

- endpoint

    The UID2 Endpoint (required).

    Please note that not to specify a trailing slash.

- auth\_key

    A bearer token in the request's authorization header (required).

- secret\_key

    A secret key for encrypting/decrypting the request/response body (required).

- identity\_scope

    UID2 or EUID. Defaults to UID2.

## new\_euid

    my $client = UID2::Client::XS->new_euid(\%options);

Calls _new()_ with EUID identity\_scope.

# METHODS

## refresh

    my $result = $client->refresh();

Fetch the latest keys and returns a hashref containing the response. The hashref will have the following keys:

- is\_success

    Boolean indicating whether the operation succeeded.

- reason

    Returns reason for failure if _is\_success_ is false.

## refresh\_json

    my $result = $client->refresh_json($json);

Updates keys with the JSON string and returns a hashref containing the response. The hashref will have same keys of _refresh_.

## decrypt

    my $result = $client->decrypt($token);
    # or
    my $result = $client->decrypt($token, $timestamp);

Decrypts an advertising token and returns a hashref containing the response. The hashref will have the following keys:

- is\_success

    Boolean indicating whether the operation succeeded.

- status

    Returns failed status if is\_success is false.

    See [UID2::Client::XS::DecryptionStatus](https://metacpan.org/pod/UID2%3A%3AClient%3A%3AXS%3A%3ADecryptionStatus) for more details.

- uid

    The UID2 string.

- site\_id
- site\_key\_site\_id
- established

## encrypt\_data

    my $result = $client->encrypt_data($data, \%request);

Encrypts arbitrary data with a hashref of requests.

Valid options are:

- advertising\_token

    Specify the UID2 Token.

- site\_id
- initialization\_vector
- now

One of _advertising\_token_ or _site\_id_ must be passed.

Returns a hashref containing the response. The hashref will have the following keys:

- is\_success

    Boolean indicating whether the operation succeeded.

- status

    Returns failed status if is\_success is false.

    See [UID2::Client::XS::EncryptionStatus](https://metacpan.org/pod/UID2%3A%3AClient%3A%3AXS%3A%3AEncryptionStatus) for more details.

- encrypted\_data

## decrypt\_data

    my $result = $client->decrypt_data($encrypted_data);

Decrypts data encrypted with _encrypt\_data()_. Returns a hashref containing the response. The hashref will have the following keys:

- is\_success
- status
- decrypted\_data
- encrypted\_at

# SEE ALSO

[https://github.com/IABTechLab/uid2-client-cpp11](https://github.com/IABTechLab/uid2-client-cpp11)

# AUTHOR

Jiro Nishiguchi <jiro@cpan.org>
