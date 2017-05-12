# NAME

WebService::Openaura - A simple and fast interface to the Openaura API

# SYNOPSIS

    use WebService::Openaura;

    my $openaura = new WebService::Openaura(api_key => 'YOUR_API_KEY');
    my $data = $openaura->info_artists_bio(
        '65f4f0c5-ef9e-490c-aee3-909e7ae6b2ab',
        { id_type => 'musicbrainz:gid', }
    );
    $data = $openaura->search_artists({
        q => 'Metallica'
    });

# DESCRIPTION

The module provides a simple interface to the Openaura API. To use this module, you must first sign up at [http://developer.openaura.com/docs/](http://developer.openaura.com/docs/) to receive an API key.

# METHODS

These methods usage: [http://developer.openaura.com/docs/](http://developer.openaura.com/docs/)

### classic\_artists

### classic\_version

### info\_artists

### info\_artists\_bio

### info\_artists\_cover\_photo

### info\_artists\_fact\_card

### info\_artists\_profile\_photo

### info\_artists\_release\_art

### info\_artists\_tags

### info\_version

### particles\_artists

### particles\_particle

### particles\_sources

### particles\_version

### search\_artists

### search\_artists\_all

### search\_version

### source\_artists

### source\_sources

### source\_version

# SEE ALSO

[http://developer.openaura.com/docs/](http://developer.openaura.com/docs/)

# LICENSE

Copyright (C) Hondallica.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hondallica <hondallica@gmail.com>
