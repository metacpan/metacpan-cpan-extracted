# NAME

WebService::SetlistFM - A simple and fast interface to the [http://www.setlist.fm](http://www.setlist.fm) API

# SYNOPSIS

    use WebService::SetlistFM;

    my $setlistfm = new WebService::SetlistFM;
    my $data = $setlistfm->artist('65f4f0c5-ef9e-490c-aee3-909e7ae6b2ab');
    $data = $setlistfm->search_artists({
        'artistName' => 'Metallica',
        'artistMbid' => '65f4f0c5-ef9e-490c-aee3-909e7ae6b2ab',
    });

# DESCRIPTION

The module provides a simple interface to the [http://www.setlist.fm](http://www.setlist.fm) API.

# METHODS

These methods usage: [http://api.setlist.fm/docs/](http://api.setlist.fm/docs/)

### artist

    my $data = $setlistfm->artist('65f4f0c5-ef9e-490c-aee3-909e7ae6b2ab');

### city

    my $data = $setlistfm->city('5392171');

### search\_artists

    my $data = $setlistfm->search_artists({
        'artistName' => 'Metallica',
        'artistMbid' => '65f4f0c5-ef9e-490c-aee3-909e7ae6b2ab',
    });

### search\_cities

    my $data = $setlistfm->search_cities({ name => 'Shibuya' });

### search\_countries

    my $data = $setlistfm->search_countries();

### search\_setlists

    my $data = $setlistfm->search_setlists({
        artistName => 'Megadeth',
        year => 2014,
    });

### search\_venues

    my $data = $setlistfm->search_venues({name => 'Shibuya'});

### setlist

    my $data = $setlistfm->setlist('3bd6440c');

### user

    my $data = $setlistfm->user('fuzy');

### venue

    my $data = $setlistfm->venue('33d6d4ac');

### artist\_setlists

    my $data = $setlistfm->artist_setlists('65f4f0c5-ef9e-490c-aee3-909e7ae6b2ab');

### setlist\_lastfm

    my $data = $setlistfm->setlist_lastfm('999009');

### setlist\_version

    my $data = $setlistfm->setlist_version('6bd45a36');

### user\_attended

    my $data = $setlistfm->user_attended('fuzy');

### user\_edited

    my $data = $setlistfm->user_edited('fuzy');

### venue\_setlists

    my $data = $setlistfm->venue_setlists('33d6d4ac');

### artist\_tour

    my $data = $setlistfm->artist_tour(
        '65f4f0c5-ef9e-490c-aee3-909e7ae6b2ab', 
        'World Magnetic'
    );

# SEE ALSO

[http://api.setlist.fm/docs/](http://api.setlist.fm/docs/)

# LICENSE

Copyright (C) Hondallica.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hondallica &lt;hondallica@gmail.com>
