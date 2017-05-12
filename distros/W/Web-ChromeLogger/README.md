# NAME

Web::ChromeLogger - ChromeLogger for Perl

# SYNOPSIS

    use Web::ChromeLogger;

    get '/', sub {
        my $logger = Web::ChromeLogger->new();
        $logger->info('hey!');
        $logger->infof('Hello, %s!', 'John');

        my $html = render_html();

        return [
            200,
            ['X-ChromeLogger-Data' => $logger->finalize()],
            $html,
        ];
    };

# DESCRIPTION

Web::ChromeLogger is a ChromeLogger library for Perl5.

Chrome Logger is a Google Chrome extension for debugging server side applications in the Chrome console.

# HOW IT WORKS

This module generates the string for ChromeLogger. You can send the string in 'X-ChromeLogger-Data' header in HTTP response.

For more details, please see [ChromeLogger's Technical Specification](http://craig.is/writing/chrome-logger/techspecs)

# LARGE RESPONSE HEADER

## NGINX PROXY

If you are using nginx as reverse proxy, you may need to set following parameters in your configuration file:

    proxy_buffer_size   128k;
    proxy_buffers   4 256k;
    proxy_busy_buffers_size   256k;

## Maximum Data Size

Chrome has a limit of `250kb` across all headers for a single request so that is the maximum amount of encoded data you can send.

# METHODS

- `my $logger = Web::ChromeLogger->new(%args)`

    Create new instance with following parameters:

    - json\_encoder (Default: `JSON::XS->new()->ascii(1)->convert_blessed` )

        JSON encoder object. You can use JSON::XS or JSON::PP for this.

        I guess you don't need to set this parameter.

- `$logger->group($title: Str)`
- `$logger->groupf($format: Str, @list)`

    Push `group`.

- `$logger->group_end($title: Str)`
- `$logger->group_endf($format: Str, @list)`

    Push `groupEnd`.

- `$logger->group_collapsed($title: Str)`
- `$logger->group_collapsedf($format: Str, @list)`

    Push `groupCollapsed`.

- `$logger->info($title: Str)`
- `$logger->infof($format: Str, @list)`

    Push `info`.

- `$logger->warn($title: Str)`
- `$logger->warnf($format: Str, @list)`

    Push `warn`.

- `$logger->error($title: Str)`
- `$logger->errorf($format: Str, @list)`

    Push `error`.

- `$logger->wrap_by_group($title: Str)`
- `$logger->wrap_by_groupf($format: Str, @list)`

    Wrap current logging data by `$title` group.

- `$logger->finalize()`

    Generate header string.

# LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tokuhiro Matsuno &lt;tokuhirom@gmail.com>

moznion

# SEE ALSO

[ChromeLogger](http://craig.is/writing/chrome-logger)
