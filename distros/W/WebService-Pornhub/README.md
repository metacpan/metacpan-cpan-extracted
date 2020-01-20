# NAME

WebService::Pornhub - Perl interface to the Pornhub.com API.

# SYNOPSIS

    use WebService::Pornhub;
    
    my $pornhub = WebService::Pornhub->new;
    
    # Search videos from Pornhub API
    my $videos = $pornhub->search(
        search => 'hard',
        'tags[]' => ['asian', 'young'],
        thumbsizes => 'medium',
    );
    
    # Response is Array reference, Perl data structures
    for my $video (@$videos) {
        say $video->{title};
        say $video->{url};
    }

# DESCRIPTION

WebService::Pornhub provides bindings for the Pornhub.com API. This module build with  role [WebService::Client](https://metacpan.org/pod/WebService::Client).

# METHODS

## new

    my $pornhub = WebService::Pornhub->new(
        timeout => 20, # optional, defaults to 10
        logger => Log::Fast->new(...), # optinal, defaults to none
        log_method => 'DEBUG', #  optional, default to 'DEBUG'
    );

Prameters:

- timeout: (Optional) Integer. Defaults to `10`
- retries: (Optional) Integer. Defaults to `0`
- logger: (Optional) Log module instance, such modules as [Log::Tiny](https://metacpan.org/pod/Log::Tiny), [Log::Fast](https://metacpan.org/pod/Log::Fast), etc.
- log\_method: (Optional) Text. Defaults to `DEBUG`

## search

    my $videos = $pornhub->search(
        search => 'hard',
        'tags[]' => ['asian', 'young'],
        thumbsizes => 'medium',
    );

Parameters:

- category: (Optional)
- page: (Optional) Integer
- search: (Optional) Text
- phrase\[\]: (Optional) Array. Used as pornstars filter.
- tags\[\]: (Optional) Array
- ordering: (Optional) Text. Possible values are featured, newest, mostviewed and rating
- period: (Optional) Text. Only works with ordering parameter. Possible values are weekly, monthly, and alltime
- thumbsize: (Required). Possible values are small,medium,large,small\_hd,medium\_hd,large\_hd

## get\_video

    my $video = $pornhub->get_video(
        id => '44bc40f3bc04f65b7a35',
        thumbsize => 'medium',
    );

Parameters:

- id: (Required) Integer
- thumbsize: (Optional) If set, provides additional thumbnails in different formats. Possible values are small,medium,large,small\_hd,medium\_hd,large\_hd

## get\_embed\_code

    my $embed = $pornhub->get_embed_code(
        id => '44bc40f3bc04f65b7a35',
    );

Parameters:

- id: (Required) Integer

## get\_deleted\_videos

    my $videos = $pornhub->get_deleted_videos(
        page => 3,
    );

Parameters:

- page: (Required) Integer

## is\_video\_active

    my $active = $pornhub->is_video_active(
        is => '44bc40f3bc04f65b7a35',
    );

Parameters:

- id: (Required) Integer

## get\_categories

    my $categories = $pornhub->get_categories();

There are no parameters for this method.

## get\_tags

    my $tags = $pornhub->get_tags(
        list => 'a',
    );

Parameters:

- list: a-z for tag starting letter, 0 for other.

## get\_stars

    my $stars = $pornhub->get_stars();

There are no parameters for this method.

## get\_stars\_detailed

    my $stars = $pornhub->get_stars_detailed();

There are no parameters for this method.

# SEE ALSO

- [WebService::Client](https://metacpan.org/pod/WebService::Client)
- [pornhub-api - npm](https://www.npmjs.com/package/pornhub-api)

# LICENSE

Copyright (C) Yusuke Wada.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yusuke Wada <yusuke@kamawada.com>
