# NAME

WebService::WsScreenshot - API client For ws-screenshot

# DESCRIPTION

WebService::WsScreenshot is an api client for [https://github.com/elestio/ws-screenshot/](https://github.com/elestio/ws-screenshot/). It
makes it simple to get URLs, or download screenshots in a Perl application, using the backend
provided by [Elesstio](https://github.com/elestio/ws-screenshot/).

# SYNOPSIS

```perl
#!/usr/bin/env perl
use warnings;
use strict;
use WebService::WsScreenshot;

# Run the backend with....
#   $ docker run --name ws-screenshot -d --restart always -p 3000:3000 -it elestio/ws-screenshot.slim

my $screenshot = WebService::WsScreenshot->new(
    base_url => 'http://127.0.0.1:3000',
);

$screenshot->store_screenshot(
    url      => 'https://modfoss.com/',
    out_file => 'modfoss.jpg',
);
```

# CONSTRUCTOR

The following options may be passed to the constructor.

## base\_url

This is the URL that ws-screenshot is running at.  It is required.

## res\_x

The horizontal pixel size for the screenshot.

Default: 1280.

## res\_y

The vertical pixel size for the screenshot.

Default: 900

## out\_format

The output format.  

Valid options are: jpg png pdf

Default: jpg

## is\_full\_page

If the screenshot should include the full page

Valid options are: true false

Default: false

## wait\_time

How long to wait before capuring the screenshot, in ms.

Default: 100

# METHODS

## create\_screenshot\_url

This method will return the full URL to the screen shot.  It could be used
for embedding the screenshot, for example.

You must pass `url` with the URL to be used for the screenshot.

    my $img_url = $screenshot->create_screenshot_url(
        url => 'http://modfoss.com',
    );

## fetch\_screenshot

This method will construct the URL for the screenshot, and then
fetch the screenshot, making the API call to the ws-screenshot
server.

It will return the HTTP::Response object from the API call.

If there is any error, it will die.

You must pass `url` with the URL to be used for the screenshot.

    my $res = $screenshot->fetch_screenshot(
        url => 'http://modfoss.com',
    );

## store\_screenshot

This method is the same as fetch\_screenshot, however the screenshot
itself will be written to disk.

You must pass `url` with the URL to be used for the screenshot, as
well as `out_file` for the path the file is to be written to.

    my $res = $screenshot->fetch_screenshot(
        url      => 'http://modfoss.com',
        out_file => 'modfoss-screenshot.jpg',
    );

# AUTHOR

Kaitlyn Parkhurst (SymKat) _<symkat@symkat.com>_ ( Blog: [http://symkat.com/](http://symkat.com/) )

# COPYRIGHT

Copyright (c) 2021 the WebService::WsScreenshot ["AUTHOR"](#author), ["CONTRIBUTORS"](#contributors), and ["SPONSORS"](#sponsors) as listed above.

# LICENSE

This library is free software and may be distributed under the same terms as perl itself.

# AVAILABILITY

The most current version of App::dec can be found at [https://github.com/symkat/WebService-WsScreenshot](https://github.com/symkat/WebService-WsScreenshot)
