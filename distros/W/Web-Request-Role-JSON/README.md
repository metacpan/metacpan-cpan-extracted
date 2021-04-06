# NAME

Web::Request::Role::JSON - Make handling JSON easier in Web::Request

# VERSION

version 1.008

# SYNOPSIS

    # Create a request handler
    package My::App::Request;
    use Moose;
    extends 'Web::Request';
    with 'Web::Request::Role::JSON';

    # Make sure your app uses your request handler, e.g. using OX:
    package My::App::OX;
    sub request_class {'My::App::Request'}

    # Finally, in some controller action
    sub create_POST {
        my ($self, $req) = @_;

        my $data    = $req->json_payload;
        my $created = $self->model->create($data);
        return $self->json_response($created, undef, 201);
    }

# DESCRIPTION

`Web::Request::Role::JSON` provides a few methods that make handling
JSON in [Web::Request](https://metacpan.org/pod/Web%3A%3ARequest) a bit easier.

Please note that all methods return a [Web::Response](https://metacpan.org/pod/Web%3A%3AResponse) object.
Depending on the framework you use (or lack thereof), you might have
to call `finalize` on the response object to turn it into a valid
PSGI response.

## METHODS

### json\_payload

    my $perl_hash = $req->json_payload;

Extracts and decodes a JSON payload from the request.

### json\_response

    $req->json_response( $data );
    $req->json_response( $data, $header_ref );
    $req->json_response( $data, $header_ref, $http_status );

Convert your data to JSON and generate a new response with correct HTTP headers.

You can pass in more headers as the second argument (either hashref or
arrayref). These headers will be passed straight on to
`HTTP::Headers->new()`.

You can also pass a HTTP status code as the third parameter. If none
is provided, we default to `200`.

### json\_error

    $req->json_response( 'something is wrong' );
    $req->json_response( $error_data );
    $req->json_response( $error, $status );

Generate a JSON object out of your error message, if the message is a
plain string. But you can also pass in a data structure that will be
converted to JSON.

Per default, HTTP status is set to `400`, but you can pass any other
status as a second argument. (Yes, there is no checking if you pass a
valid status code or not. You're old enough to not do stupid things..)

## PARAMETERS

An optional `content_type` parameter can be added on role application to
restore previous behaviour. Browsers tend to like the 'charset=utf-8' better,
but you might have your reasons.

    package MyRequest;
    extends 'OX::Request';
    with (
        'Web::Request::Role::JSON' => { content_type => 'application/json' },
    );

# THANKS

Thanks to

- [validad.com](https://www.validad.com/) for supporting Open Source.

# AUTHORS

- Thomas Klausner <domm@plix.at>
- Klaus Ita <koki@itascraft.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
