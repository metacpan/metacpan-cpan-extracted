# NAME

Time::Moment::Ext - Extend Time::Moment with strptime and SQL dates support

# SYNOPSIS

        use Time::Moment::Ext;
        
        my $tm = Time::Moment::Ext->from_datetime('2015-01-18');
        
        my $tm2 = Time::Moment::Ext->from_datetime('2015-01-20 10:33:45');

        my $tm3 = Time::Moment::Ext->strptime('2015-01-20 10:33:45', '%Y-%m-%d %H:%M:%S');

        say $tm->to_datetime;

        say $tm2->to_date;

        say $tm3->to_time;

        say $tm->day;
        
        # (you can use all other methods from Time::Moment)

# DESCRIPTION

Time::Moment::Ext - Extend Time::Moment with strptime and SQL dates support

# SUBROUTINES/METHODS

## strptime

The method use all strptime features from [Time::Piece](https://metacpan.org/pod/Time::Piece)

## from\_datetime

Converting SQL data/datetime string to Time::Moment object

## to\_datetime

Converting Time::Moment object to SQL datetime string

## to\_date

Converting Time::Moment object to date string

## to\_time

Converting Time::Moment object to time string

## day

Return the day of month (alias to day\_of\_month)

# CONFIGURATION AND ENVIRONMENT

# DIAGNOSTICS

# INCOMPATIBILITIES

# BUGS AND LIMITATIONS

# DEPENDENCIES

- [Time::Moment](https://metacpan.org/pod/Time::Moment)
- [Time::Piece](https://metacpan.org/pod/Time::Piece)

# VERSION

version 0.04

# AUTHOR

Konstantin Cherednichenko <dshadowukraine@gmail.com>

# LICENSE AND COPYRIGHT

Copyright 2017 (c) Konstantin Cherednichenko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.
