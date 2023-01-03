# NAME

Time::HiRes::Sleep::Until - Provides common ways to sleep until...

# SYNOPSIS

    use Time::HiRes::Sleep::Until;
    my $su    = Time::HiRes::Sleep::Until->new;
    my $slept = $su->epoch($epoch); # epoch is a calculated time + $seconds
    my $slept = $su->mark(20);      # sleep until 20 second mark of the clock :00, :20, or :40
    my $slept = $su->second(45);    # sleep until 45 seconds after the minute

# DESCRIPTION

Sleep Until provides sleep wrappers for sleep functions that I commonly need.  These methods are simply wrappers around [Time::HiRes](https://metacpan.org/pod/Time::HiRes) and [Math::Round](https://metacpan.org/pod/Math::Round).

We use this package to make measurements at the same time within the minute for integration with RRDtool.

# USAGE

    use strict;
    use warnings;
    use DateTime;
    use Time::HiRes::Sleep::Until;
    my $su = Time::HiRes::Sleep::Until->new;
    do {
      print DateTime->now, "\n"; #make a measurment three times a minute
    } while ($su->mark(20));

Perl One liner

    perl -MTime::HiRes::Sleep::Until -e 'printf "Slept: %s\n", Time::HiRes::Sleep::Until->new->top'

# CONSTRUCTOR

## new

    use Time::HiRes::Sleep::Until;
    my $su = Time::HiRes::Sleep::Until->new;

# METHODS

## epoch

Sleep until provided epoch in float seconds.

    while ($CONTINUE) {
      my $sleep_epoch = $su->time + 60/8;
      do_work();                #run process that needs to run back to back but not more than 8 times per minute
      $su->epoch($sleep_epoch); #sleep(7.5 - runtime). if runtime > 7.5 seconds does not sleep
    }

## mark

Sleep until next second mark;

    my $slept = $su->mark(20); # 20 second mark, i.e.  3 times a minute on the 20s
    my $slept = $su->mark(10); # 10 second mark, i.e.  6 times a minute on the 10s
    my $slept = $su->mark(6);  #  6 second mark, i.e. 10 times a minute on 0,6,12,...

## second

Sleep until the provided seconds after the minute

    my $slept = $su->second(0);  #sleep until top of minute
    my $slept = $su->second(30); #sleep until bottom of minute

## top

Sleep until the top of the minute

    my $slept = $su->top; #alias for $su->second(0);

## time

Method to access Time::HiRes time without another import.

## sleep

Method to access Time::HiRes sleep without another import.

# LIMITATIONS

The mathematics add a small amount of delay for which we do not account.  Testing routinely passes with 100th of a second accuracy and typically with millisecond accuracy.

# BUGS

Please log on GitHub

# AUTHOR

    Michael R. Davis

# COPYRIGHT

MIT License

Copyright (c) 2023 Michael R. Davis

# SEE ALSO

[Time::HiRes](https://metacpan.org/pod/Time::HiRes), [Math::Round](https://metacpan.org/pod/Math::Round)
