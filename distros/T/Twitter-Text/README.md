[![Actions Status](https://github.com/utgwkk/Twitter-Text/workflows/CI/badge.svg)](https://github.com/utgwkk/Twitter-Text/actions)
# NAME

Twitter::Text - Perl implementation of the twitter-text parsing library

# SYNOPSIS

    use Twitter::Text;

    $result = parse_tweet('Hello world こんにちは世界');
    print $result->{valid} ? 'valid tweet' : 'invalid tweet';

# DESCRIPTION

Twitter::Text is a Perl implementation of the twitter-text parsing library.

## WARNING

This library does not implement auto-linking and hit highlighting.

Please refer [Implementation status](https://github.com/utgwkk/Twitter-Text/issues/5) for latest status.

# FUNCTIONS

All functions below are exported by default.

## Extraction

### extract\_hashtags

    $hashtags = extract_hashtags($text);

Returns an array reference of extracted hashtag string from `$text`.

### extract\_hashtags\_with\_indices

    $hashtags_with_indices = extract_hashtags_with_indices($text, [\%options]);

Returns an array reference of hash reference of extracted hashtag from `$text`.

Each hash reference consists of `hashtag` (hashtag string) and `indices` (range of hashtag).

### extract\_mentioned\_screen\_names

    $screen_names = extract_mentioned_screen_names($text);

Returns an array reference of exctacted screen name string from `$text`.

### extract\_mentioned\_screen\_names\_with\_indices

    $screen_names_with_indices = extract_mentioned_screen_names_with_indices($text);

Returns an array reference of hash reference of extracted screen name or list from `$text`.

Each hash reference consists of `screen_name` (screen name string) and `indices` (range of screen name).

### extract\_mentions\_or\_lists\_with\_indices

    $mentions_or_lists_with_indices = extract_mentions_or_lists_with_indices($text);

Returns an array reference of hash reference of extracted screen name from `$text`.

Each hash reference consists of `screen_name` (screen name string) and `indices` (range of screen name or list). If it is a list, the hash reference also contains `list_slug` item.

### extract\_urls

    $urls = extract_urls($text);

Returns an array reference of extracted URL string from `$text`.

### extract\_urls\_with\_indices

    $urls = extract_urls_with_indices($text, [\%options]);

Returns an array reference of hash reference of extracted URL from `$text`.

Each hash reference consists of `url` (URL string) and `indices` (range of screen name).

## Validation

### parse\_tweet

    $parse_result = parse_tweet($text, [\%options]);

The `parse_tweet` function takes a `$text` string and optional `\%options` parameter and returns a hash reference with following values:

- `weighted_length`

    The overall length of the tweet with code points weighted per the ranges defined in the configuration file.

- `permillage`

    Indicates the proportion (per thousand) of the weighted length in comparison to the max weighted length. A value > 1000 indicates input text that is longer than the allowable maximum.

- `valid`

    Indicates if input text length corresponds to a valid result.

- `display_range_start`, `display_range_end`

    An array of two unicode code point indices identifying the inclusive start and exclusive end of the displayable content of the Tweet.

- `valid_range_start`, `valid_range_end`

    An array of two unicode code point indices identifying the inclusive start and exclusive end of the valid content of the Tweet.

#### EXAMPLES

    use Data::Dumper;
    use Twitter::Text;

    $result = parse_tweet('Hello world こんにちは世界');
    print Dumper($result);
    # $VAR1 = {
    #       'weighted_length' => 33
    #       'permillage' => 117,
    #       'valid' => 1,
    #       'display_range_start' => 0,
    #       'display_range_end' => 32,
    #       'valid_range_start' => 0,
    #       'valid_range_end' => 32,
    #     };

### is\_valid\_hashtag

    $valid = is_valid_hashtag($hashtag);

Validate `$hashtag` is a valid hashtag and returns a boolean value that indicates if given argument is valid.

### is\_valid\_list

    $valid = is_valid_list($username_list);

Validate `$username_list` is a valid @username/list and returns a boolean value that indicates if given argument corresponds to a valid result.

### is\_valid\_url

    $valid = is_valid_url($url, [unicode_domains => 1, require_protocol => 1]);

Validate `$url` is a valid URL and returns a boolean value that indicates if given argument is valid.

If `unicode_domains` argument is a truthy value, validate `$url` is a valid URL with Unicode characters. (default: true)

If `require_protocol` argument is a truthy value, validation requires a protocol of URL. (default: true)

### is\_valid\_username

    $valid = is_valid_username($username);

Validate `$username` is a valid username for Twitter and returns a boolean value that indicates if given argument is valid.

# SEE ALSO

[twitter-text](https://github.com/twitter/twitter-text). Implementation of Twitter::Text (this library) is heavily based on [Ruby implementation of twitter-text](https://github.com/twitter/twitter-text/tree/master/rb).

[https://developer.twitter.com/en/docs/counting-characters](https://developer.twitter.com/en/docs/counting-characters)

# COPYRIGHT & LICENSE

Copyright (C) Twitter, Inc and other contributors

Copyright (C) utgwkk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

utgwkk <utagawakiki@gmail.com>
