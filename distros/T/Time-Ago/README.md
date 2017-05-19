# NAME

Time::Ago - Approximate duration in words

# VERSION

version 1.00

# SYNOPSIS

    use Time::Ago;

    print Time::Ago->in_words(0), "\n";
    # prints "less than a minute"

    print Time::Ago->in_words(3600 * 4.6), "\n";
    # prints "about 5 hours"
    
    print Time::Ago->in_words(86400 * 360 * 2), "\n";
    # prints "almost 2 years"
    
    print Time::Ago->in_words(86400 * 365 * 11.3), "\n";
    # prints "over 11 years"

# DESCRIPTION

Given a duration, in seconds, returns a readable approximation.
This a Perl port of the time\_ago\_in\_words() helper from Rails.

From Rails' docs:

    0 <-> 29 secs
      less than a minute

    30 secs <-> 1 min, 29 secs
      1 minute

    1 min, 30 secs <-> 44 mins, 29 secs
      [2..44] minutes

    44 mins, 30 secs <-> 89 mins, 29 secs
      about 1 hour

    89 mins, 30 secs <-> 23 hrs, 59 mins, 29 secs
      about [2..24] hours

    23 hrs, 59 mins, 30 secs <-> 41 hrs, 59 mins, 29 secs
      1 day

    41 hrs, 59 mins, 30 secs <-> 29 days, 23 hrs, 59 mins, 29 secs
      [2..29] days

    29 days, 23 hrs, 59 mins, 30 secs <-> 44 days, 23 hrs, 59 mins, 29 secs
      about 1 month

    44 days, 23 hrs, 59 mins, 30 secs <-> 59 days, 23 hrs, 59 mins, 29 secs
      about 2 months

    59 days, 23 hrs, 59 mins, 30 secs <-> 1 yr minus 1 sec
      [2..12] months

    1 yr <-> 1 yr, 3 months
      about 1 year

    1 yr, 3 months <-> 1 yr, 9 months
      over 1 year

    1 yr, 9 months <-> 2 yr minus 1 sec
      almost 2 years

    2 yrs <-> max time or date
      (same rules as 1 yr)

# METHODS

- in\_words 

        Time::Ago->in_words(30); # returns "1 minute"
        Time::Ago->in_words(3600 * 24 * 365 * 10); # returns "about 10 years"

    Given a duration, in seconds, returns a readable approximation in words.

    If an include\_seconds parameter is supplied, durations under one minute
    generate more granular phrases:

        foreach (4, 9, 19, 39, 59) {
          print Time::Ago->in_words($_, include_seconds => 1), "\n";
        }

        # less than 5 seconds
        # less than 10 seconds
        # less than 20 seconds
        # half a minute
        # less than a minute

    As a convenience, if the duration is an object with an epoch() interface
    (as provided by Time::Piece or DateTime), the current time minus the
    object's epoch() seconds is used.

    Passing the duration as a DateTime::Duration instance is also supported.

# LOCALIZATION

Locale::TextDomain is used for localization.

Currently Arabic, Dutch, English, French, German, Italian, Japanese, Russian,
and Spanish translations are available. Contact me if you need another
language.

See [Locale::TextDomain](https://metacpan.org/pod/Locale::TextDomain) for how to specify a language.

    #!/usr/bin/env perl
    
    use strict;
    use warnings;
    use open qw/ :std :utf8 /;
    use POSIX ':locale_h';
    use Time::Ago;
    
    my $secs = 86400 * 365 * 10.4;
    
    foreach (qw/ en fr de it ja ru es /) {
      setlocale(LC_ALL, '');
      $ENV{LANGUAGE} = $_;
      print Time::Ago->in_words($secs), "\n";
    }

Output:

    over 10 years
    plus de 10 ans
    vor mehr als 10 Jahren
    oltre 10 anni
    10年以上
    больше 10 лет
    más de 10 años

# BUGS

The rails' implementation includes some logic for leap years that is not
implemented here.

# CREDITS

Ruby on Rails DateHelper
[http://apidock.com/rails/v4.2.1/ActionView/Helpers/DateHelper/distance\_of\_time\_in\_words](http://apidock.com/rails/v4.2.1/ActionView/Helpers/DateHelper/distance_of_time_in_words)

Ruby i18n library
[https://github.com/svenfuchs/i18n](https://github.com/svenfuchs/i18n)

# SEE ALSO

Github repository [https://github.com/mla/time-ago](https://github.com/mla/time-ago)

[Time::Duration](https://metacpan.org/pod/Time::Duration), [DateTime::Format::Human::Duration](https://metacpan.org/pod/DateTime::Format::Human::Duration), [Locale::TextDomain](https://metacpan.org/pod/Locale::TextDomain)

# AUTHOR

Maurice Aubrey <maurice.aubrey@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Maurice Aubrey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

[![Build Status](https://travis-ci.org/mla/time-ago.svg?branch=master)](https://travis-ci.org/mla/time-ago)
