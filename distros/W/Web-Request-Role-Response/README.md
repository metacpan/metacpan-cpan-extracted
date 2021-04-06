# NAME

Web::Request::Role::Response - Generate various HTTP responses from a Web::Request

# VERSION

version 1.008

# SYNOPSIS

    # Create a request handler
    package My::App::Request;
    use Moose;
    extends 'Web::Request';
    with 'Web::Request::Role::Response';

    # Make sure your app uses your request handler, e.g. using OX:
    package My::App::OX;
    sub request_class {'My::App::Request'}

    # in some controller action:

    # redirect
    $req->redirect('/');
    $req->permanent_redirect('/foo');

    # return 204 no content
    $req->no_content_response;

    # return a transparent 1x1 gif (eg as a tracking pixle)
    $req->transparent_gif_response;

    # file download
    $req->file_download_response( 'text/csv', $data, 'your_export.csv' );

# DESCRIPTION

`Web::Request::Role::JSON` provides a few methods that make generating HTTP responses easier when using [Web::Request](https://metacpan.org/pod/Web%3A%3ARequest).

Please note that all methods return a [Web::Response](https://metacpan.org/pod/Web%3A%3AResponse) object.
Depending on the framework you use (or lack thereof), you might have
to call `finalize` on the response object to turn it into a valid
PSGI response.

## METHODS

### redirect

    $req->redirect( '/some/location' );
    $req->redirect( $ref_uri_for );
    $req->redirect( 'http://example.com', 307 );

Redirect to the given location. The location can be a string
representing an absolute or relative URL. You can also pass a ref,
which will be resolved by calling `uri_for` on the request object -
so be sure that your request object has this method (extra points if
the method also returns something meaningful)!

You can pass a HTTP status code as a second parameter. It's probably
smart to use one that makes sense in a redirecting context...

### permanent\_redirect

    $req->permanent_redirect( 'http://we.moved.here' );

Similar to `redirect`, but will issue a permanent redirect (who would
have thought!) using HTTP status code `301`.

### file\_download\_response

    $req->file_download_response( $content-type, $data, $filename );

Generate a "Download-File" response. Useful if your app returns a
CSV/Spreadsheet/MP3 etc. You have to provide the correct content-type,
the data in the correct encoding and a meaningful filename.

### no\_content\_response

    $req->no_content_response

Returns `204 No Content`.

### transparent\_gif\_response

    $req->transparent_gif_response

Returns a transparent 1x1 pixel GIF. Useful as the response of a
tracking URL.

# THANKS

Thanks to

- [validad.com](https://www.validad.com/) for supporting Open Source.
- [choroba](https://github.com/choroba) for improvements to the test suite.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
