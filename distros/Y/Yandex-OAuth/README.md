# NAME

Yandex::OAuth - module for get access token to Yandex.API

# SYNOPSIS

    use Yandex::OAuth;

    my $oauth = Yandex::OAuth->new(
        client_id     => '76df1cf****************fb31d0289',
        client_secret => 'e3a2855****************4de3c2afc',
    );
    
    # return link for open in browser
    say $oauth->get_code();

    # return JSON with access_token
    say Dumper $oauth->get_token( code => 3557461 );

# DESCRIPTION

Yandex::OAuth is a module for get access token for Yandex.API
See more at https://tech.yandex.ru/oauth/doc/dg/concepts/ya-oauth-intro-docpage/

# METHODS

- **get\_code()**

    return a link for open in browser

        $oauth->get_code();

- **get\_token()**

    return a json with access\_token or error if code has expired

        $oauth->get_token( code => XXXXXX );

# LICENSE

Copyright (C) Andrey Kuzmin.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Andrey Kuzmin <chipsoid@cpan.org>
