# NAME

Time::Crontab - parser for crontab date and time field

# SYNOPSIS

    use Time::Crontab;

    my $time_cron = Time::Crontab->new('0 0 1 * *');
    if ( $time_cron->match(time()) ) {
        do_cron_job();
    }

# DESCRIPTION

Time::Crontab is a parser for crontab date and time field. And 
it provides simple matcher.

# METHOD

- new($crontab:Str)

    Returns Time::Crontab object. If incorrect crontab string was given, Time::Crontab dies.

- match($unix\_timestamp:Num)

    Returns whether or not the given unix timestamp matches the crontab
    Timestamps are truncated to minute resolution.

# SUPPORTED SPECS

    Field name   Allowed values  Allowed special characters
    Minutes      0-59            * / , -
    Hours        0-23            * / , -
    Day of month 1-31            * / , -
    Month        1-12 or JAN-DEC * / , -
    Day of week  0-6 or SUN-SAT  * / , -

Predefined scheduling definitions are not supported. 
In month and day\_of\_week fields, Able to use the first three letters of day or month. But 
does not support range or list of the names.

# RELATED MODULES

- [DateTime::Event::Cron](https://metacpan.org/pod/DateTime::Event::Cron)

    DateTime::Event::Cron that depends on DateTime. 
    Time::Crontab does not require DateTime or Time::Piece.

- [Algorithm::Cron](https://metacpan.org/pod/Algorithm::Cron)

    Algorithm::Cron also does not require DateTime. 
    It's provides \`next\_time\` method, Time::Crontab provides \`match\` method.

# LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>
