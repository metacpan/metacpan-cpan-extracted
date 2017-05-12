[![Build Status](https://travis-ci.org/takebayashi/p5-WebService-Instapaper.svg?branch=master)](https://travis-ci.org/takebayashi/p5-WebService-Instapaper)
# NAME

WebService::Instapaper - A client for the Instapaper Full API

# SYNOPSIS

    use WebService::Instapaper;

    my $client = WebService::Instapaper->new(consumer_key => '...', consumer_secret => '...');

    $client->auth('username', 'password');

    # or
    $client->token('access_token', 'access_token_secret');

    # get bookmark list
    my @bookmarks = $client->bookmarks;

    # archive bookmarks
    my $bookmark = shift @bookmarks;
    $client->archive_bookmark($bookmark->{bookmark_id});

# DESCRIPTION

WebService::Instapaper is a client for the Instapepr Full API (https://www.instapaper.com/api)

- new(\\%options)

    Create new instance of this module. `%options` should contain following keys: `consumer_key` and `consumer_secret`.

- auth($username, $password)

    Authenticate with given `$username` and `$password`.

- token($access\_token, $access\_secret)

    Set existing access token to the instance.

- bookmarks(\\%options)

    Return bookmark list. By default, it returns 25 bookmark items.

    `%options` may contain `limit` to specify the number of results.

        my @many_bookmarks = $client->bookmarks(limit => 100);

- add\_bookmark($url, \\%options)

    Add new bookmark to Instapaper.

        $client->add_bookmark('http://www.example.org/');

        # with details
        $client->add_bookmark('http://www.example.org/', title => 'Example Article', description => 'This is an example.');

- delete\_bookmark($bookmark\_id)

    Delete the bookmark.

- archive\_bookmark($bookmark\_id)

    Archive the bookmark.

- unarchive\_bookmark($bookmark\_id)

    Unarchive the bookmark.

# LICENSE

Copyright (C) Shun Takebayashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Shun Takebayashi <shun@takebayashi.asia>
