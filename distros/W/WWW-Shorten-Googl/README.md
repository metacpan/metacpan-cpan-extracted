# NAME

WWW::Shorten::Googl - Perl interface to [http://goo.gl/](http://goo.gl/)

# SYNOPSIS

    use strict;
    use warnings;

    use WWW::Shorten::Googl; # OR
    # use WWW::Shorten 'Googl';

    # $ENV{GOOGLE_API_KEY} should be set

    my $url = 'http://metacpan.org/pod/WWW::Shorten::Googl';
    my $short_url = makeashorterlink($url);
    my $long_url  = makealongerlink($short_url);

    # Note - this function is specific to the Googl shortener
    my $stats = getlinkstats( $short_url );

# DESCRIPTION

A Perl interface to the [http://goo.gl/](http://goo.gl/) URL shortening service. Googl simply maintains
a database of long URLs, each of which has a unique identifier.

# FUNCTIONS

## makeashorterlink

The function `makeashorterlink` will call the Googl web site passing
it your long URL and will return the shorter Googl version.

If you provide your Google username and password, the link will be added
to your list of shortened URLs at [http://goo.gl/](http://goo.gl/).

See AUTHENTICATION for details.

## makealongerlink

The function `makealongerlink` does the reverse. `makealongerlink`
will accept as an argument either the full URL or just the identifier.

## getlinkstats

Given a [http://goo.gl/](http://goo.gl/) URL, returns a hash ref with statistics about the URL.

See [http://code.google.com/apis/urlshortener/v1/reference.html#resource\_url](http://code.google.com/apis/urlshortener/v1/reference.html#resource_url)
for information on which data can be present in this hash ref.

# AUTHENTICATION

To use this shorten service, you'll first need to setup an
[API Key](https://developers.google.com/url-shortener/v1/getting_started#APIKey).

Once you have that key setup, you will need to set the `GOOGLE_API_KEY` environment
variable to use that key.

# AUTHOR

Magnus Erixzon <`magnus@erixzon.com`>

# CONTRIBUTORS

- Chase Whitener <`capoeirab@cpan.org`>

# LICENSE AND COPYRIGHT

Copyright 2004, Magnus Erixzon <`magnus@erixzon.com`>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[WWW::Shorten](https://metacpan.org/pod/WWW::Shorten), [http://goo.gl/](http://goo.gl/), [API Reference](https://developers.google.com/url-shortener/v1/getting_started)
