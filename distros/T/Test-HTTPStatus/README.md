# NAME

Test::HTTPStatus - check an HTTP status

# SYNOPSIS

        use Test::HTTPStatus tests => 2;

        http_ok( 'https://www.perl.org', HTTP_OK );

        http_ok( $url, $status );

# DESCRIPTION

Check the HTTP status for a resource.

# FUNCTIONS

## http\_ok( URL \[, HTTP\_STATUS \] )

    http_ok( $url, $expected_status );

Tests the HTTP status of the specified URL and reports whether it matches the expected status.

### Parameters

- `URL` (Required)

    The URL to be tested.
    This must be a valid URL string.
    If the URL is invalid or undefined, the test will fail, and an appropriate diagnostic message will be displayed.

- `HTTP_STATUS` (Optional)

    The expected HTTP status code.
    Defaults to `HTTP_OK` (200) if not provided.
    This parameter should be one of the HTTP status constants exported by the module (e.g., `HTTP_OK`, `HTTP_NOT_FOUND`).

### Diagnostics

On success, the test will pass with a message in the following format:

    Expected [<expected_status>], got [<actual_status>] for [<url>]

On failure, the test will fail with one of the following messages:

- `[$url] does not appear to be anything`

    Indicates that the URL was undefined or missing.

- `[$url] does not appear to be a valid URL`

    Indicates that the URL string provided was invalid or malformed.

- `Mysterious failure for [$url] with status [$status]`

    Indicates that the request failed for an unexpected reason or returned a status not matching the expected value.

### Examples

- Basic test with default expected status:

        http_ok('https://www.perl.org');

    This checks that the URL `https://www.perl.org` returns an HTTP status of `HTTP_OK` (200).

- Test with a custom expected status:

        http_ok('https://www.example.com/404', HTTP_NOT_FOUND);

    This checks that the URL `https://www.example.com/404` returns an HTTP status of `HTTP_NOT_FOUND` (404).

### Return Value

The routine does not return any value.
Instead, it reports success or failure using the underlying test builder's `ok` method.

## \_check\_link

Verify the accessibility of a given URL by checking its HTTP status code using [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent).
It first attempts to send a HEAD request to the provided link,
which is useful for quickly checking if the resource exists without downloading its content.
If the response indicates no error (i.e., status code is below 400),
the function proceeds with a GET request to ensure a proper response is received.
The function then validates whether a valid HTTP response was obtained and returns the corresponding status code.
If the link is undefined or if no valid response is received, the function returns `undef`.

It is taken from the old module HTTP::SimpleLinkChecker.

## user\_agent

Returns the user agent being used

# SEE ALSO

[HTTP::SimpleLinkChecker](https://metacpan.org/pod/HTTP%3A%3ASimpleLinkChecker), [Mojo::URL](https://metacpan.org/pod/Mojo%3A%3AURL)

# AUTHORS

brian d foy, `<bdfoy@cpan.org>`

Maintained by Nigel Horne, `<njh at bandsman.co.uk>`

# SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc Test::HTTPStatus

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Test-HTTPStatus](https://metacpan.org/release/Test-HTTPStatus)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-HTTPStatus](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-HTTPStatus)

- CPANTS

    [http://cpants.cpanauthors.org/dist/Test-HTTPStatus](http://cpants.cpanauthors.org/dist/Test-HTTPStatus)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Test-HTTPStatus](http://matrix.cpantesters.org/?dist=Test-HTTPStatus)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Test::HTTPStatus](http://deps.cpantesters.org/?module=Test::HTTPStatus)

# LICENSE AND COPYRIGHT

This program is released under the following licence: GPL2
Copyright © 2002-2019, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.
