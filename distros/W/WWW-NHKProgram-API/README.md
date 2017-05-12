[![Build Status](https://travis-ci.org/moznion/WWW-NHKProgram-API.png?branch=master)](https://travis-ci.org/moznion/WWW-NHKProgram-API) [![Coverage Status](https://coveralls.io/repos/moznion/WWW-NHKProgram-API/badge.png?branch=master)](https://coveralls.io/r/moznion/WWW-NHKProgram-API?branch=master)
# NAME

WWW::NHKProgram::API - API client for NHK program API

# SYNOPSIS

    use WWW::NHKProgram::API;

    my $client = WWW::NHKProgram::API->new(api_key => '__YOUR_API_KEY__');

    # Get program list
    my $program_list = $client->list({
        area    => 130,
        service => 'g1',
        date    => '2014-02-02',
    });

    # Get program list by genre
    my $program_genre = $client->genre({
        area    => 130,
        service => 'g1',
        genre   => '0000',
        date    => '2014-02-02',
    });

    # Get program information
    my $program_info = $client->info({
        area    => 130,
        service => 'g1',
        id      => '2014020334199',
    });

    # Get information of program that is on air now
    my $program_now = $client->now_on_air({
        area    => 130,
        service => 'g1',
    });

# DESCRIPTION

WWW::NHKProgram::API is the API client for NHK program API.

Please refer [http://api-portal.nhk.or.jp](http://api-portal.nhk.or.jp)
if you want to get information about NHK program API.

# METHODS

- WWW::NHKProgram::API->new();

    Constructor. You must give API\_KEY through this method.

    e.g.

        my $client = WWW::NHKProgram::API->new(
            api_key => '__YOUR_API_KEY__', # <= MUST!
        );

- $client->list()

    Get program list.

        my $program_list = $client->list({
            area    => 130,
            service => 'g1',
            date    => '2014-02-04',
        });

    And following the same;

        my $program_list = $client->list({
            area    => '東京',
            service => 'ＮＨＫ総合１',
            date    => '2014-02-04',
        });

    You can specify Japanese area name and service name as arguments.
    If you want to know more details, please refer to the following;

    [http://api-portal.nhk.or.jp/doc-request](http://api-portal.nhk.or.jp/doc-request)

- $client->genre()

    Get program list by genre.

        my $genre_list = $client->genre({
            area    => 130,
            service => 'g1',
            genre   => '0000',
            date    => '2014-02-04',
        });

    Yes! you can also specify following;

        my $genre_list = $client->genre({
            area    => '東京',
            service => 'ＮＨＫ総合１',
            genre   => '定時・総合',
            date    => '2014-02-04',
        });

- $client->info()

    Get information of program.

        my $program_info = $client->info({
            area    => 130,
            service => 'g1',
            id      => '2014020402027',
        });

    Also;

        my $program_info = $client->info({
            area    => '東京',
            service => 'ＮＨＫ総合１',
            id      => '2014020402027',
        });

- $client->now\_on\_air()

    Get information of program that is on air now.

        my $program_now = $client->now_on_air({
            area    => 130,
            service => 'g1',
        });

    Yes,

        my $program_now = $client->now_on_air({
            area    => '東京',
            service => 'ＮＨＫ総合１',
        });

- $client->list\_raw()
- $client->genre\_raw()
- $client->info\_raw()
- $client->now\_on\_air\_raw()

    Returns raw JSON response of each API.

# FOR DEVELOPERS

Tests which are calling web API directly in `xt/webapi`. If you want to run these tests, please execute like so;

    $ NHK_PROGRAM_API_KEY=__YOUR_API_KEY__ prove xt/webapi

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>
