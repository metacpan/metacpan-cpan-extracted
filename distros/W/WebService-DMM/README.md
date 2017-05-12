[![Build Status](https://travis-ci.org/syohex/p5-WebService-DMM.png?branch=master)](https://travis-ci.org/syohex/p5-WebService-DMM)
# NAME

WebService::DMM - DMM webservice module

# SYNOPSIS

    use WebService::DMM;
    use Config::Pit;

    my $config = pit_get('dmm.co.jp', require => {
        affiliate_id => 'DMM affiliate ID',
        api_id       => 'DMM API ID',
    });

    my $dmm = WebService::DMM->new(
        affiliate_id => $config->{affiliate_id},
        api_id       => $config->{api_id},
    );

    my $response = $dmm->search( %params );
    die "Failed to request" unless $response->is_success;

    for my $item (@{$response->items}) {
        ....
    }

# DESCRIPTION

WebService::DMM is DMM webservice module.
DMM[http://www.dmm.com](http://www.dmm.com) is Japanese shopping site.

# INTERFACES

## Class Methods

### `WebService::DMM->new(%args) :WebService::DMM`

Create and return a new WebService::DMM instance with _%args_.

_%args_ must have following parameter:

- affiliate\_id

    Affiliate ID of DMM. Postfix of affliate\_id should be 900-999.

- api\_id

    API ID of DMM. Register your account in DMM and you can get API ID.

## Instance Method

### $dmm->search(%param) : WebService::DMM::Response

_%params_ mandatory parameters are:

- operation :Str = "ItemList"
- version :Str = "2.00"

    Version should be '1.00' or '2.00'.

- timestamp :Str = current time

    Time format should be 'Year-Month-Day Hour:Minute:Second'
    (strftime format is '%Y-%m-%d %T')

- site :Str

    Site, 'DMM.co.jp' or 'DMM.com'.

_%param_ optional parameters are:

- hits :Int = 20

    Number of items

- offset :Int = 1

    Offset of searched results

- sort :Str = "rank"

    Type of sort, 'rank', '+price', '-price', 'date', 'review'.

- service :Str

    See "SERVICE AND FLOOR" section

- floor :Str

    See "SERVICE AND FLOOR" section

- keyword :Str

    Search keyword. You can use DMM search keyword style.
    Keyword should be string(not byte sequence).

### $dmm->last\_response : Furl::Response

Return last response which is a Furl::Response instance.

# SERVICE AND FLOOR

DMM.com services are:

- lod

    akb48, ske48

- digital

    bandai, anime, video, idol, cinema, fight

- monthly

    toei, animate, shochikugeino, idol, cinepara, dgc, fleague

- digital\_book

    comic, novel, photo, otherbooks

- pcsoft

    pcgame, pcsoft

- mono

    dvd, cd, book, game, hobby, kaden, houseware, gourmet

- rental

    rental\_dvd, ppr\_dvd, rental\_cd, ppr\_cd, comic

- nandemo

    fashion\_ladies, fashion\_mems, rental\_iroiro

DMM.co.jp services are:

- digital

    videoa, videoc, nikkatsu, anime, photo

- monthly

    shirouto, nikkatsu, paradisetv, animech, dream, avstation, playgirl, alice,
    crystal, hmp, waap, momotarobb, moodyz, prestige, jukujo, sod, mania, s1, kmp,
    mousouzoku

- ppm

    video, videoc

- pcgame

    pcgame

- doujin

    doujin

- book

    book

- mono

    dvd, good, anime, pcgame, book, doujin

- rental

    rental\_dvd, ppr\_dvd

# CUSTOMIZE USER AGENT

You can specify your own instance of [Furl](https://metacpan.org/pod/Furl) to set $WebService::DMM::UserAgent.

    $WebService::DMM::UserAgent = Furl->new( your_own_paramter );

# EXAMPLES

There are many examples in the "eg/" directory in this distribution.

# AUTHOR

Syohei YOSHIDA <syohex@gmail.com>

# COPYRIGHT

Copyright 2013 - Syohei YOSHIDA

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

Official Guide [https://affiliate.dmm.com/api/guide/](https://affiliate.dmm.com/api/guide/)
