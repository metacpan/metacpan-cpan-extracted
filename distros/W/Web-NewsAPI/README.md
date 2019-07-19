[![Build Status](https://travis-ci.com/jmacdotorg/newsapi-perl.svg?branch=master)](https://travis-ci.com/jmacdotorg/newsapi-perl)
# Web::NewsAPI

This Perl module provides a simple, object-oriented interface to
[the News API](https://newsapi.org), version 2. It supports that API's
three public endpoints, allowing your code to fetch and search current
news headlines and sources.

# Example

    use Web::NewsAPI;
    use v5.10;

    # To use this module, you need to get a free API key from
    # https://newsapi.org. (The following is a bogus example key that will
    # not actually work. Try it with your own key instead!)
    my $api_key = 'deadbeef1234567890f001f001deadbeef';

    my $newsapi = Web::NewsAPI->new(
       api_key => $api_key,
    );

    say "Here are the top ten headlines from American news sources...";
    my @headlines = $newsapi->top_headlines( country => 'us', pageSize => 10 );
    for my $article ( @headlines ) {
       # Each is a Web::NewsAPI::Article object.
       say $article->title;
    }

    say "Here are the top ten headlines worldwide containing 'chicken'...";
    my @chicken_heds = $newsapi->everything( q => 'chicken', pageSize => 10 );
    for my $article ( @chicken_heds ) {
       # Each is a Web::NewsAPI::Article object.
       say $article->title;
    }

    say "Here are some sources for English-language technology news...";
    my @sources = $newsapi->sources(
       category => 'technology', language => 'en' 
    );
    for my $source ( @sources ) {
       # Each is a Web::NewsAPI::Source object.
       say $source->name;
    }

# Installation

This module's most recent release [is on CPAN](https://metacpan.org/pod/Web::NewsAPI)! Your best
bet is to install it via the CPAN installation tool of your choice. (My
favorite is [cpanm](https://metacpan.org/pod/App::cpanminus).)

To instead install it from source, run these commands:

    perl Build.PL
    perl Build build
    perl Build install # run under sudo to install at system-level

# Documentation

For full programmer documentation, see [Web::NewsAPI](https://metacpan.org/pod/Web::NewsAPI).

# Notes

This is this module's first release (or nearly so). It works for the
author's own use-cases, but it's probably buggy beyond that. Please
report issues at [the module's GitHub
site](https://github.com/jmacdotorg/newsapi-perl). Code and documentation
pull requests are very welcome!

# Author

Jason McIntosh (jmac@jmac.org)

# Copyright and licence

This software is Copyright (c) 2019 by Jason McIntosh.

This is free software, licensed under:

    The MIT (X11) License

# A personal request

My ability to share and maintain free, open-source software like this
depends upon my living in a society that allows me the free time and
personal liberty to create work benefiting people other than just myself
or my immediate family. I recognize that I got a head start on this due
to an accident of birth, and I strive to convert some of my unclaimed
time and attention into work that, I hope, gives back to society in some
small way.

Worryingly, I find myself today living in a country experiencing a
profound and unwelcome political upheaval, with its already flawed
democracy under grave threat from powerful authoritarian elements. These
powers wish to undermine this society, remolding it according to their
deeply cynical and strictly zero-sum philosophies, where nobody can gain
without someone else losing.

Free and open-source software has no place in such a world. As such,
these autocrats' further ascension would have a deleterious effect on my
ability to continue working for the public good.

Therefore, if you would like to financially support my work, I would ask
you to consider a donation to one of the following causes. It would mean
a lot to me if you did. (You can tell me about it if you'd like to, but
you don't have to.)

- [The American Civil Liberties Union](https://aclu.org)
- [The Democratic National Committee](https://democrats.org)
- [Earthjustice](https://earthjustice.org)
