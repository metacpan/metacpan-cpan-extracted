[![Build Status](https://travis-ci.org/researchpanelasia/p5-WebService-SOP-Auth-V1_1.svg?branch=master)](https://travis-ci.org/researchpanelasia/p5-WebService-SOP-Auth-V1_1)
# NAME

WebService::DS::SOP::Auth::V1\_1 - SOP version 1.1 authentication module

# SYNOPSIS

    use WebService::DS::SOP::Auth::V1_1;

To create an instance:

    my $auth = WebService::DS::SOP::Auth::V1_1->new({
        app_id => '1',
        app_secret => 'hogehoge',
    });

When making a GET request to API:

    my $req = $auth->create_request(
        GET => 'https://<API_HOST>/path/to/endpoint' => {
            hoge => 'hoge',
            fuga => 'fuga',
        },
    );

    my $res = LWP::UserAgent->new->request($req);

When making a POST request with JSON data to API:

    my $req = $auth->create_request(
        POST_JSON => 'http://<API_HOST>/path/to/endpoint' => {
            hoge => 'hoge',
            fuga => 'fuga',
        },
    );

    my $res = LWP::UserAgent->new->request($req);

When embedding JavaScript URL in page:

    <script src="<: $req.uri.as_string :>"></script>

# DESCRIPTION

WebService::DS::SOP::Auth::V1\_1 is an authentication module
for [SOP](http://console.partners.surveyon.com/) version 1.1
by [Research Panel Asia, Inc](http://www.researchpanelasia.com/).

# METHODS

## new( \\%options ) returns WebService::DS::SOP::Auth::V1\_1

Creates a new instance.

Possible options:

- `app_id`

    (Required) Your `app_id`.

- `app_secret`

    (Required) Your `app_secret`.

- `time`

    (Optional) POSIX time.

## app\_id() returns Int

Returns `app_id` configured to instance.

## app\_secret() returns Str

Returns `app_secret` configured to instance.

## time returns Int

Returns `time` configured to instance.

## create\_request( Str $type, Any $uri, Hash $params ) returns HTTP::Request

Returns a new [HTTP::Request](https://metacpan.org/pod/HTTP%3A%3ARequest) object for API request while adding `app_id` to parameters by default.

_$type_ can be one of followings:

- `GET`

    For HTTP GET request to SOP endpoint with signature in query string as parameter
    **sig**.

- `POST`

    For HTTP POST request to SOP endpoint with signature in query string as
    parameter **sig** of request content type `application/x-www-form-urlencoded`.

- `POST_JSON`

    For HTTP POST request to SOP endpoint with signature as request header
    `X-Sop-Sig` of request content type `application/json`.

- `PUT`

    For HTTP PUT request to SOP endpoint with signature in query string as
    parameter **sig** of request content type `application/x-www-form-urlencoded`.

- `PUT_JSON`

    For HTTP PUT request to SOP endpoint with signature as request header
    `X-Sop-Sig` of request content type `application/json`.

- `DELETE`

    For HTTP DELETE request to SOP endpoint with signature in query string as parameter
    **sig**.

## verify\_signature( Str $sig, Hash $params ) return Int

Verifies and returns if request signature is valid.

# SEE ALSO

[WebService::DS::SOP::Auth::V1\_1::Request::DELETE](https://metacpan.org/pod/WebService%3A%3ADS%3A%3ASOP%3A%3AAuth%3A%3AV1_1%3A%3ARequest%3A%3ADELETE),
[WebService::DS::SOP::Auth::V1\_1::Request::GET](https://metacpan.org/pod/WebService%3A%3ADS%3A%3ASOP%3A%3AAuth%3A%3AV1_1%3A%3ARequest%3A%3AGET),
[WebService::DS::SOP::Auth::V1\_1::Request::POST](https://metacpan.org/pod/WebService%3A%3ADS%3A%3ASOP%3A%3AAuth%3A%3AV1_1%3A%3ARequest%3A%3APOST),
[WebService::DS::SOP::Auth::V1\_1::Request::POST\_JSON](https://metacpan.org/pod/WebService%3A%3ADS%3A%3ASOP%3A%3AAuth%3A%3AV1_1%3A%3ARequest%3A%3APOST_JSON),
[WebService::DS::SOP::Auth::V1\_1::Request::PUT](https://metacpan.org/pod/WebService%3A%3ADS%3A%3ASOP%3A%3AAuth%3A%3AV1_1%3A%3ARequest%3A%3APUT),
[WebService::DS::SOP::Auth::V1\_1::Request::PUT\_JSON](https://metacpan.org/pod/WebService%3A%3ADS%3A%3ASOP%3A%3AAuth%3A%3AV1_1%3A%3ARequest%3A%3APUT_JSON),
[WebService::DS::SOP::Auth::V1\_1::Util](https://metacpan.org/pod/WebService%3A%3ADS%3A%3ASOP%3A%3AAuth%3A%3AV1_1%3A%3AUtil)

# LICENSE

Copyright (C) dataSpring, Inc.
Copyright (C) Research Panel Asia, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

yowcow &lt;yoko.oyama \[ at \] d8aspring.com>
