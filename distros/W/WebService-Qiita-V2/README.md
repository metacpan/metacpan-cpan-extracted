# NAME

WebService::Qiita::V2 - Qiita API(v2) Client

# SYNOPSIS

    use WebService::Qiita::V2;

    my $client = WebService::Qiita::V2->new;

    $client->get_user_items('qiita'); # qiita's item list
    $client->{token} = 'your access token';
    $client->get_authenticated_user_items({ page => 1, per_page => 10 }); # your recently 10 items

# DESCRIPTION

WebService::Qiita::V2 is a client of Qiita API V2 for Perl.
This module wrapped all Qiita API(not include deprecated).

API document: https://qiita.com/api/v2/docs

# AUTHOR

risou <risou.f@gmail.com>

# LICENSE

Copyright (C) risou

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
