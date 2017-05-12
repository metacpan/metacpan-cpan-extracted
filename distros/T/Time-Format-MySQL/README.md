# NAME

Time::Format::MySQL - provides from\_unixtime() and unix\_timestamp()

# SYNOPSIS

    use Time::Format::MySQL qw(from_unixtime unix_timestamp)

    print from_unixtime(time); #=> 2013-01-11 12:03:28
    print unix_timestamp('2013-01-11 12:03:28'); #=> 1357873408

# DESCRIPTION

Time::Format::MySQL provides mysql-like functions, from\_unixtime() and unix\_timestamp().

# FUNCTIONS

- from\_unixtime($unixtime \[, $format\])

    unix timestamp -> date time

- unix\_timestamp($datetime \[, $format\])

    date time -> unix timestamp

# SEE ALSO

- [DateTime::Format::MySQL](http://search.cpan.org/perldoc?DateTime::Format::MySQL)
- [Time::Piece::MySQL](http://search.cpan.org/perldoc?Time::Piece::MySQL)

# LICENSE

Copyright (C) Hiroki Honda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroki Honda <cside.story@gmail.com>
