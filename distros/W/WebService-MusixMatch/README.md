# NAME

WebService::MusixMatch - A simple and fast interface to the Musixmatch API

# SYNOPSIS

    use WebService::MusixMatch;

    my $mxm = new WebService::MusixMatch(apikey => 'YOUR_API_KEY');

    my $data = $mxm->chart_artist_get( country => 'JP' );
    $data = $mxm->track_search( q => 'One', f_artist_id => 64 );
    $data = $mxm->matcher_track_get(
        q_artist => 'Metallica',
        q_album => 'Master of Puppets',
        q_track => 'One',
    );
    $data = $mxm->artist_search(q_artist => 'Metallica');

# DESCRIPTION

The module provides a simple interface to the MusixMatch API. To use this module, you must first sign up at [https://developer.musixmatch.com](https://developer.musixmatch.com) to receive an API key.

# METHODS

These methods usage: [https://developer.musixmatch.com/documentation/api-methods](https://developer.musixmatch.com/documentation/api-methods)

### chart\_artists\_get

### chart\_tracks\_get

### track\_search

### track\_get

### track\_subtitle\_get

### track\_lyrics\_get

### track\_snippet\_get

### track\_lyrics\_post

### track\_lyrics\_feedback\_post

### matcher\_lyrics\_get

### matcher\_track\_get

### matcher\_subtitle\_get

### artist\_get

### artist\_search

### artist\_albums\_get

### artist\_related\_get

### album\_get

### album\_tracks\_get

### tracking\_url\_get

### catalogue\_dump\_get

# SEE ALSO

[https://developer.musixmatch.com](https://developer.musixmatch.com)

# LICENSE

Copyright (C) Hondallica.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hondallica <hondallica@gmail.com>
