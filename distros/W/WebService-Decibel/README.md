# NAME

WebService::Decibel - A simple and fast interface to the Decibel API

# SYNOPSIS

    use WebService::Decibel;

    my $decibel = new WebService::Decibel(
        app_id  => 'YOUR_APPLICATION_ID',
        app_key => 'YOUR_APPLICATION_KEY',
    );

    my $album = $decibel->album(id => '9e7eb16c-358f-e311-be87-ac220b82800d');
    my $albums = $decibel->albums(artistName => 'Metallica');
    my $artist = $decibel->artist(id => '09ff7ede-318f-e311-be87-ac220b82800d');
    my $artists = $decibel->artists(name => 'Metallica');
    my $disctags = $decibel->disctags(id => '9e7eb16c-358f-e311-be87-ac220b82800d');
    my $recording = $decibel->recording(id => '01f034fc-b76c-11e3-be98-ac220b82800d');
    my $recordings = $decibel->recordings(artist => 'Metallica', title => 'Battery');

# DESCRIPTION

The module provides a simple interface to the www.decibel.net API. To use this module, you must first sign up at [https://developer.decibel.net](https://developer.decibel.net) to receive an Application ID and Key.

# METHODS

These methods usage: [https://developer.decibel.net/our-api](https://developer.decibel.net/our-api)

### album

    my $album = $decibel->album(id => '9e7eb16c-358f-e311-be87-ac220b82800d');

### albums

    my $albums = $decibel->albums(artistName => 'Metallica');

### artist

    my $artist = $decibel->artist(id => '09ff7ede-318f-e311-be87-ac220b82800d');

### artists

    my $artists = $decibel->artists(name => 'Metallica');

### disctags

    my $disctags = $decibel->disctags(id => '9e7eb16c-358f-e311-be87-ac220b82800d');

### recording

    my $recording = $decibel->recording(id => '01f034fc-b76c-11e3-be98-ac220b82800d');

### recordings

    my $recordings = $decibel->recordings(artist => 'Metallica', title => 'Battery');

# SEE ALSO

[https://developer.decibel.net](https://developer.decibel.net)

# LICENSE

Copyright (C) Hondallica.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hondallica <hondallica@gmail.com>
