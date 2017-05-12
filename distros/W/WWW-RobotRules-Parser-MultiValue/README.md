[![Build Status](https://travis-ci.org/tarao/perl5-WWW-RobotRules-Parser-MultiValue.svg?branch=master)](https://travis-ci.org/tarao/perl5-WWW-RobotRules-Parser-MultiValue)
# NAME

WWW::RobotRules::Parser::MultiValue - Parse robots.txt

# SYNOPSIS

    use WWW::RobotRules::Parser::MultiValue;
    use LWP::Simple qw(get);

    my $url = 'http://example.com/robots.txt';
    my $robots_txt = get $url;

    my $rules = WWW::RobotRules::Parser::MultiValue->new(
        agent => 'TestBot/1.0',
    );
    $rules->parse($url, $robots_txt);

    if ($rules->allows('http://example.com/some/path')) {
        my $delay = $rules->delay_for('http://example.com/');
        sleep $delay;
        ...
    }

    my $hash = $rules->rules_for('http://example.com/');
    my @list_of_allowed_paths = $hash->get_all('allow');
    my @list_of_custom_rule_value = $hash->get_all('some-rule');

# DESCRIPTION

`WWW::RobotRules::Parser::MultiValue` is a parser for `robots.txt`.

Parsed rules for the specified user agent is stored as a
[Hash::MultiValue](https://metacpan.org/pod/Hash::MultiValue), where the key is a lower case rule name.

`Request-rate` rule is handled specially.  It is normalized to
`Crawl-delay` rule.

# METHODS

- new

        $rules = WWW::RobotRules::Parser::MultiValue->new(
            aget => $user_agent
        );
        $rules = WWW::RobotRules::Parser::MultiValue->new(
            aget => $user_agent,
            ignore_default => 1,
        );

    Creates a new object to handle rules in `robots.txt`.  The object
    parses rules match with `$user_agent`.  The rules of `User-agent: *`
    always match and have a lower precedence than the rules explicitly
    matched with `$user_agent`.  If `ignore_default` option is
    specified, rules of `User-agent: *` are simply ignored.

- parse

        $rules->parse($uri, $text);

    Parses a text content `$text` whose URI is `$uri`.

- match\_ua

        $rules->match_ua($pattern);

    Test if the user agent matches with `$pattern`.

- rules\_for

        $hash = $rules->rules_for($uri);

    Returns a `Hash::MultiValue`, which describes the rules of the domain
    of `$uri`.

- allows

        $test = $rules->allows($uri);

    Tests if the user agent is allowed to visit `$uri`.  If there is
    'Allow' rule for the path of `$uri`, then the `$uri` is allowed to
    visit.  If there is 'Disallow' rule for the path of `$uri`, then the
    `$uri` is not allowed to visit.  Otherwise, the `$uri` is allowed to
    visit.

- delay\_for

        $delay = $rules->delay_for($uri);
        $delay_in_milliseconds = $rules->delay_for($uri, 1000);

    Calculate a crawl delay for the specified `$uri`.  The value is
    determined by 'Crawl-delay' rule or 'Request-rate' rule.  The second
    argument specifies the base of the return value.

# SEE ALSO

[Hash::MultiValue](https://metacpan.org/pod/Hash::MultiValue)

# LICENSE

Copyright (C) INA Lintaro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

INA Lintaro <tarao.gnn@gmail.com>
