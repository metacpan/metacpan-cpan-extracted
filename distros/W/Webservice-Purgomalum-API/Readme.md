# NAME

Webservice::Purgomalum::API - Filter and removes profanity and unwanted text from input using PurgoMalum.com's free API

# SYNOPSIS
```perl
    use Webservice::Purgomalum::API;

    my $api = Webservice::Purgomalum::API->new();

    print $api->contains_profanity(
            text => "what the hell?",
        )."\n";

    print $api->get(
        text => "what the heck dude?", #required
        add => "heck",             #optional
        fill_text => "[explicit]"  #optional
        fill_char => '-',          #optional (overridden by fill_text param)
    )."\n";

    # output debugging data to STDERR
    $api->debug(1);
    print $api->get(
        text => "what the heck dude?",
        add => "heck",
    )."\n";
```
# DESCRIPTION

This module provides an object oriented interface to the PurgoMalum free API endpoint provided by [https://Purgomalum.com/](https://Purgomalum.com/).

# METHODS

All methods have the same available parameters. Only the "text" parameter is required.

- **text** _Required_ Input text to be processed.
- **add** _Optional_ Comma separated list of words to be added to the profanity list. Accepts letters, numbers, underscores (\_) and commas (,). Accepts up to 10 words (or 200 maximum characters in length). The PurgoMalum filter is case-insensitive, so the case of your entry is not important.
- **fill\_text** _Optional_ Text used to replace any words matching the profanity list. Accepts letters, numbers, underscores (\_) tildes (~), exclamation points (!), dashes/hyphens (-), equal signs (=), pipes (|), single quotes ('), double quotes ("), asterisks (\*), open and closed curly brackets ({ }), square brackets (\[ \]) and parentheses (). Maximum length of 20 characters. When not used, the default is an asterisk (\*) fill.
- **fill\_char** _Optional_ Single character used to replace any words matching the profanity list. Fills designated character to length of word replaced. Accepts underscore (\_) tilde (~), dash/hyphen (-), equal sign (=), pipe (|) and asterisk (\*). When not used, the default is an asterisk (\*) fill.

## contains\_profanity()

Returns either "true" if profanity is detected or "false" otherwise.

## get()

Returns the string with all profanities replaced with either the fill\_text or fill\_char

# SEE ALSO

- Call for API implementations on PerlMonks: [https://perlmonks.org/?node\_id=11161472](https://perlmonks.org/?node_id=11161472)
- Listed at  freepublicapis.com: [https://www.freepublicapis.com/profanity-filter-api](https://www.freepublicapis.com/profanity-filter-api)
- Official api webpage: [https://www.purgomalum.com/](https://www.purgomalum.com/)

# AUTHOR

Joshua Day, <hax@cpan.org>

# SOURCECODE

Source code is available on Github.com : [https://github.com/haxmeister/perl-purgomalum](https://github.com/haxmeister/perl-purgomalum)

# COPYRIGHT AND LICENSE

Copyright (C) 2024 by Joshua Day

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
