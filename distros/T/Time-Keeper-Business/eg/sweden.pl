#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Time::Keeper;
use Time::Keeper::Business;

# Sweden's public holidays as the Public Holidays Act (Lag om allmänna
# helgdagar, 1989:253) lists them, with three of its movable days a weekday
# between two dates, and the three eves that are closed as if they were
# holidays though the act does not name them.

sub sweden {
    my $R = 'Time::Keeper::Business::Rule';
    return $R->set(
        $R->fixed(month => 1, day => 1, name => 'Nyårsdagen'),
        $R->fixed(month => 1, day => 6, name => 'Trettondedag jul'),
        $R->easter(offset => -2, name => 'Långfredagen'),
        $R->easter(offset => 0, name => 'Påskdagen'),
        $R->easter(offset => 1, name => 'Annandag påsk'),
        $R->fixed(month => 5, day => 1, name => 'Första maj'),
        $R->easter(offset => 39, name => 'Kristi himmelsfärdsdag'),
        $R->easter(offset => 49, name => 'Pingstdagen'),
        $R->fixed(month => 6, day => 6, name => 'Sveriges nationaldag'),
        $R->weekday_on_or_after(rule => $R->fixed(month => 6, day => 19), day_of_week => 5, name => 'Midsommarafton'),
        $R->weekday_on_or_after(rule => $R->fixed(month => 6, day => 20), day_of_week => 6, name => 'Midsommardagen'),
        $R->weekday_on_or_after(rule => $R->fixed(month => 10, day => 31), day_of_week => 6, name => 'Alla helgons dag'),
        $R->fixed(month => 12, day => 24, name => 'Julafton'),
        $R->fixed(month => 12, day => 25, name => 'Juldagen'),
        $R->fixed(month => 12, day => 26, name => 'Annandag jul'),
        $R->fixed(month => 12, day => 31, name => 'Nyårsafton'),
        name => 'Sverige',
    );
}

unless (caller) {
    binmode STDOUT, ':encoding(UTF-8)';
    my $year = shift // Time::Keeper->today->year;
    my $b = Time::Keeper::Business->new(holidays => sweden(), weekend => 'sv-SE', zone => 'Europe/Stockholm', name => 'Sverige');
    print "$b, $year\n";
    printf "  %s  %s  %s\n", $_->[0], $_->[0]->in_locale('sv')->format('EEEE'), $_->[1] for $b->holidays(year => $year);
    my $day = Time::Keeper::Date->new(year => $year, month => 12, day => 20);
    print "the ten business days after $day:\n";
    printf "  %s  %s\n", $day = $b->next_business_day($day), $day->format('EEEE') for 1 .. 10;
}

1;
