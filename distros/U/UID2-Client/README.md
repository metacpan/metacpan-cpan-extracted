[![Actions Status](https://github.com/spiritloose/uid2-client-perl/workflows/test/badge.svg)](https://github.com/spiritloose/uid2-client-perl/actions) [![MetaCPAN Release](https://badge.fury.io/pl/UID2-Client.svg)](https://metacpan.org/release/UID2-Client)
# NAME

UID2::Client - Unified ID 2.0 Perl Client

# SYNOPSIS

    use UID2::Client;

    my $client = UID2::Client->new({
        endpoint => 'https://prod.uidapi.com',
        auth_key => 'your_auth_key',
        secret_key => 'your_secret_key',
    });
    my $result = $client->refresh;
    die $result->{reason} unless $result->{is_success};
    my $decrypted = $client->decrypt($uid2_token);
    if ($decrypted->{is_success}) {
        say $result->{uid};
    }

# DESCRIPTION

This module provides an interface to Unified ID 2.0 API.

# CONSTRUCTOR METHODS

## new

    my $client = UID2::Client->new(\%options);

Creates and returns a new UID2 client with a hashref of options.

Valid options are:

- endpoint

    The UID2 Endpoint (required).

- auth\_key

    A bearer token in the request's authorization header (required).

- secret\_key

    A secret key for encrypting/decrypting the request/response body (required).

- identity\_scope

    UID2 or EUID. Defaults to UID2.

- http\_options

    Options to pass to the [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) constructor.

- http

    The [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny) instance.

    Only one of _http\_options_ or _http_ can be specified.

## new\_euid

    my $client = UID2::Client->new_euid(\%options);

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

    $client->refresh_json($json);

Updates keys with the JSON string and returns a hashref containing the response. The hashref will have same keys of _refresh()_.

## get\_latest\_keys

    my $json = $client->get_latest_keys();

Gets latest keys from UID2 API and returns the JSON string.

Dies on errors, e.g. HTTP errors.

## decrypt

    my $result = $client->decrypt($uid2_token);
    # or
    my $result = $client->decrypt($uid2_token, $timestamp);

Decrypts an advertising token and returns a hashref containing the response. The hashref will have the following keys:

- is\_success

    Boolean indicating whether the operation succeeded.

- status

    Returns failed status if is\_success is false.

    See [UID2::Client::DecryptionStatus](https://metacpan.org/pod/UID2%3A%3AClient%3A%3ADecryptionStatus) for more details.

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
- key

One of _advertising\_token_ or _site\_id_ must be passed.

Returns a hashref containing the response. The hashref will have the following keys:

- is\_success

    Boolean indicating whether the operation succeeded.

- status

    Returns failed status if is\_success is false.

    See [UID2::Client::EncryptionStatus](https://metacpan.org/pod/UID2%3A%3AClient%3A%3AEncryptionStatus) for more details.

- encrypted\_data

## decrypt\_data

    my $result = $client->decrypt_data($encrypted_data);

Decrypts data encrypted with _encrypt\_data()_. Returns a hashref containing the response. The hashref will have the following keys:

- is\_success
- status
- decrypted\_data
- encrypted\_at

# SEE ALSO

[https://github.com/UnifiedID2/uid2docs](https://github.com/UnifiedID2/uid2docs)

# LICENSE

Copyright (C) Jiro Nishiguchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jiro Nishiguchi <jiro@cpan.org>
