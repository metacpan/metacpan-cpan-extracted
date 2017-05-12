# NAME

WWW::Shorten::Naver - Interface to shortening URLs using Naver Shorten URL API

# SYNOPSIS

The traditional way, using the [WWW::Shorten](https://metacpan.org/pod/WWW::Shorten) interface:

    use strict;
    use warnings;
    use WWW::Shorten::Naver;
    # use WWW::Shorten 'Naver';  # or, this way

    my $short = makeashorterlink('http://www.foo.com/some/long/url', {
        client_id     => 'your naver api client id ',
        client_secret => 'your naver api client secret',
        ...
    });

Or, the Object-Oriented way:

    use strict;
    use warnings;
    use Data::Dumper;
    use WWW::Shorten::Naver;

    my $shortener = WWW::Shorten::Naver->new(
        client_id     => 'your naver api client id ',
        client_secret => 'your naver api client secret',
    );

    my $res = $shortener->shorten( url => 'http://google.com/');
    say Dumper $res;

    # {
    #   hash => "GyvykVAu",
    #   orgUrl => "http://me2.do/GyvykVAu",
    #   url => "http://d2.naver.com/helloworld/4874130"
    # }

# DESCRIPTION

A Perl interface to the [Naver Shorten URL API](https://developers.naver.com/docs/utils/shortenurl).
You can either use the traditional (non-OO) interface provided by [WWW::Shorten](https://metacpan.org/pod/WWW::Shorten).
Or, you can use the OO interface that provides you with more functionality.

# FUNCTIONS

In the non-OO form, [WWW::Shorten::Naver](https://metacpan.org/pod/WWW::Shorten::Naver) makes the following functions available.

## makeashorterlink

    my $short_url = makeashorterlink('https://some_long_link.com', {
        client_id     => 'your naver api client id ',
        client_secret => 'your naver api client secret'
    });    

The function `makeashorterlink` will call the Naver Shorten URL API,
passing it your long URL and will return the shorter version.
It requires the use of Client ID and Client Secret to shorten links.

# METHODS

In the OO form, [WWW::Shorten::Naver](https://metacpan.org/pod/WWW::Shorten::Naver) makes the following methods available.

## new

    my $shortenr = WWW::Shorten::Naver->new(
        client_id     => 'your naver api client id ',
        client_secret => 'your naver api client secret',
    );

Any or all of the attributes can be set in your configuration file. If you have
a configuration file and you pass parameters to `new`, the parameters passed
in will take precedence.

## shorten

    my $short = $shortenr->shorten(
        url => "http://www.example.com", # required.
    );
    say $short->{url};

Shorten a URL using [https://developers.naver.com/docs/utils/shortenurl](https://developers.naver.com/docs/utils/shortenurl). Returns a hash reference or dies.

# AUTHOR

Jeen Lee <`jeen@perl.kr`>

# SEE ALSO

[WWW::Shorten](https://metacpan.org/pod/WWW::Shorten), [WWW::Shorten::Bitly](https://metacpan.org/pod/WWW::Shorten::Bitly), [https://developers.naver.com/docs/utils/shortenurl](https://developers.naver.com/docs/utils/shortenurl)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
