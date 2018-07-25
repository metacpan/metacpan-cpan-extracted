# NAME

Woothee - multi-language user-agent strings parsers (perl implementation)

For Woothee, see [https://github.com/woothee/woothee](https://github.com/woothee/woothee)

# SYNOPSIS

    use Woothee;

    Woothee->parse("Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)");
    # => {'name'=>"Internet Explorer", 'category'=>"pc", 'os'=>"Windows 7", 'version'=>"8.0", 'vendor'=>"Microsoft"}

    Woothee->is_crawler('Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)');
    # => 1

# DESCRIPTION

'Woothee' is user-agent string parser, returns just same result over multi-language by sharing same datasets and testsets over implementations of each languages.

# METHODS

'Woothee' have no instance methods.

## CLASS METHODS

### `Woothee->parse( $useragent ) :HashRef`

Parse user-agent string and returns HashRef with keys 'name', 'category', 'os', 'version' and 'vendor'.

For unknown user-agent (or partially failed to parse), result hashref may have value 'UNKNOWN'.

- 'category' is labels of user terminal type, one of 'pc', 'smartphone', 'mobilephone', 'appliance', 'crawler' or 'misc' (or 'UNKNOWN').
- 'name' is the name of browser, like 'Internet Explorer', 'Firefox', 'GoogleBot'.
- 'version' is version string, like '8.0' for IE, '9.0.1' for Firefix, '0.2.149.27' for Chrome, and so on.
- 'os' is like 'Windows 7', 'Mac OSX', 'iPhone', 'iPad', 'Android'. This field used to indicate cellar phone carrier for category 'mobilephone'.
- 'vendor' is optional field, shows browser vendor.

### `Woothee->is_crawler( $useragent ) :Bool`

Try to see $useragent's category is 'crawler' or not, by casual(fast) method. Minor case of crawler is not tested in this method. To check crawler strictly, use "Woothee->parse()->{category} eq 'crawler'".

# AUTHOR

TAGOMORI Satoshi &lt;tagomoris {at} gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
