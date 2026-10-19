package Time::Keeper::Business::Rule;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use Time::Keeper::Business ();

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::Business::Rule - holidays by rule: fixed dates, nth weekdays, Easter, observed days

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Time::Keeper::Business;

    my $rule = Time::Keeper::Business::Rule->set(
        Time::Keeper::Business::Rule->fixed(month => 1, day => 1, name => "New Year's Day")->observed('next_business_day'),
        Time::Keeper::Business::Rule->easter(offset => -2, name => 'Good Friday'),
        Time::Keeper::Business::Rule->nth(month => 5, day_of_week => 1, n => -1, name => 'Spring bank holiday'),
        Time::Keeper::Business::Rule->fixed(month => 12, day => 25, name => 'Christmas Day')->observed('next_business_day'),
        name => 'mine',
    );
    $rule->holidays(year => 2027);          # ([Date, name], ...)

    my $b = Time::Keeper::Business->new(holidays => Time::Keeper::Business::Rule->uk);

=head1 DESCRIPTION

Most public holidays are a handful of rules: a fixed date, the nth weekday
of a month, the last one, a day counted from Easter, and what happens when
one lands on a weekend. A rule answers C<< holidays(year => $y) >> as a
L<Time::Keeper::Business> source does, so a rule, or a set of them, goes
straight into a schedule's C<holidays>, and a country is written in a
dozen lines for every year, published or not.

Rules never change: L</observed>, L</between> and L</only_if> give a new
rule and leave the old as it was.

=head1 RULES

Every constructor takes its arguments by key and C<< name => >> for the
holiday's name.

=head2 fixed

    Time::Keeper::Business::Rule->fixed(month => 12, day => 25, name => 'Christmas Day');

The same date every year. C<< day => 29 >> of February falls in leap years
only.

=head2 nth

    Time::Keeper::Business::Rule->nth(month => 11, day_of_week => 4, n => 4, name => 'Thanksgiving Day');
    Time::Keeper::Business::Rule->nth(month => 5, day_of_week => 1, n => -1, name => 'Spring bank holiday');

The nth weekday of a month, 1 for Monday to 7 for Sunday; C<n> is 1 to 5,
or -1 for the last. A fifth that a year does not have is no holiday that
year.

=head2 easter

    Time::Keeper::Business::Rule->easter(offset => -2, name => 'Good Friday');
    Time::Keeper::Business::Rule->easter(offset => 1, name => 'Easter Monday', orthodox => 1);

Easter Sunday plus C<offset> days (0 by default). The Gregorian computus,
or with C<< orthodox => 1 >> the Julian one, giving the Gregorian date of
the Orthodox Easter.

=head2 relative

    my $christmas = Time::Keeper::Business::Rule->fixed(month => 12, day => 25, name => 'Christmas Day');
    Time::Keeper::Business::Rule->relative(rule => $christmas, days => 1, name => 'Boxing Day');

A day counted from another rule's date, before that rule's own L</observed>
move.

=head2 set

    Time::Keeper::Business::Rule->set($rule, $rule2, ..., name => 'England and Wales', weekend => [6, 7]);

Rules together, with a name and the weekend their observed moves use
(Saturday and Sunday unless given). A set may hold sets. Observed moves
within a set see each other: first every date that stays put takes its
day, then the ones that move look for a free one, in the order given.

=head1 CHANGING A RULE

=head2 observed

    $rule->observed('next_business_day');
    $rule->observed('nearest_business_day');
    $rule->observed('next_monday');
    $rule->observed(sub { my $date = shift; ... });
    $rule->observed('none');
    $rule->observed('next_business_day', weekend => [5, 6]);

What happens when the date falls on a weekend day. C<next_business_day>
moves to the next weekday that is not already a holiday in the same set:
the United Kingdom's substitute day, so Christmas on a Saturday is kept on
the Monday and Boxing Day on the Tuesday after it. C<nearest_business_day>
moves a Saturday back to the Friday and a Sunday on to the Monday, the
United States federal rule, so New Year's Day on a Saturday is kept on
31 December of the year before. C<next_monday> moves either to the Monday
after. A code ref is called with the date for every year, weekend or not,
and gives the date to keep, or undef for none. C<none> is the default. The
weekend is Saturday and Sunday unless the rule or its set is given one.

=head2 between

    $rule->between(from => 2024);
    $rule->between(from => 1971, to => 2020);

The years the rule holds, either end open.

=head2 only_if

    $rule->only_if(sub { my $year = shift; $year % 4 == 1 });

A rule that holds in the years the code ref says.

=head1 ASKING

=head2 holidays

    my @pairs = $rule->holidays(year => 2027);

The rule's dates in the year, in date order, each a pair C<[$date, $name]>
of a L<Time::Keeper::Date> and the name. A date that an observed move
carries into another year is listed under that year.

=head2 name

The name given.

=head2 STORABLE_freeze

=head2 FREEZE

A rule is not serialised: it may hold code refs, and is cheap to build
again from its constructors. Freezing one dies with that reason.

=head1 THREE COUNTRIES

Shipped as examples of what a dozen rules say, and used by the tests
against the published lists; not a promise to track every decree. Each
holds from the year it says.

=head2 uk

The bank holidays of England and Wales from 2024 on: New Year's Day, Good
Friday, Easter Monday, the early May, spring and summer bank holidays,
Christmas Day and Boxing Day, with substitute days as gov.uk applies them.
Extra days by proclamation, and the years before 2024 when May's holidays
moved, are not included.

=head2 us_federal

The United States federal holidays from 1971 on, observed as the Office of
Personnel Management observes them: New Year's Day, the Birthday of Martin
Luther King, Jr. (from 1986), Washington's Birthday, Memorial Day,
Juneteenth National Independence Day (from 2021), Independence Day, Labor
Day, Columbus Day, Veterans Day, Thanksgiving Day and Christmas Day.
Inauguration Day, a holiday in the District of Columbia alone, is not
included.

=head2 target2

The days the euro's TARGET2 settlement system closes: New Year's Day,
Good Friday, Easter Monday, 1 May, Christmas Day and 26 December.

=head1 WRITING YOUR OWN

    my $r = 'Time::Keeper::Business::Rule';
    my $france = $r->set(
        $r->fixed(month => 1, day => 1, name => 'Jour de l\'an'),
        $r->easter(offset => 1, name => 'Lundi de Pâques'),
        $r->fixed(month => 5, day => 1, name => 'Fête du Travail'),
        $r->fixed(month => 5, day => 8, name => 'Victoire 1945'),
        $r->easter(offset => 39, name => 'Ascension'),
        $r->easter(offset => 50, name => 'Lundi de Pentecôte'),
        $r->fixed(month => 7, day => 14, name => 'Fête nationale'),
        $r->fixed(month => 8, day => 15, name => 'Assomption'),
        $r->fixed(month => 11, day => 1, name => 'Toussaint'),
        $r->fixed(month => 11, day => 11, name => 'Armistice 1918'),
        $r->fixed(month => 12, day => 25, name => 'Noël'),
        name => 'France',
    );
    my $b = Time::Keeper::Business->new(holidays => $france, zone => 'Europe/Paris');

A holiday that moves when it falls on a weekend takes L</observed>; one
that began or ended takes L</between>; one that holds in some years takes
L</only_if>. A literal date for a one-off goes beside the rule in the
schedule's C<holidays> list.

=head1 SEE ALSO

L<Time::Keeper::Business>, L<Time::Keeper::Date>, L<Date::Holidays>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
