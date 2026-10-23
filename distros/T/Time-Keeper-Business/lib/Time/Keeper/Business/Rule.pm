package Time::Keeper::Business::Rule;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.04';

use Time::Keeper::Business ();

1;

__END__

=encoding utf8


=head1 NAME

Time::Keeper::Business::Rule - holidays by rule: fixed dates, nth weekdays, Easter, observed days

=head1 VERSION

Version 0.04

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
only. In another calendar it takes C<calendar> and C<month_code>: see
L</In another calendar>.

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

=head2 weekday_on_or_after

=head2 weekday_on_or_before

    my $first_monday = Time::Keeper::Business::Rule->nth(month => 11, day_of_week => 1, n => 1);
    Time::Keeper::Business::Rule->weekday_on_or_after(rule => $first_monday, day_of_week => 2, days => 1, name => 'Election Day');
    Time::Keeper::Business::Rule->weekday_on_or_after(rule => Time::Keeper::Business::Rule->fixed(month => 6, day => 19), day_of_week => 5, name => 'Midsummer Eve');
    Time::Keeper::Business::Rule->weekday_on_or_before(rule => Time::Keeper::Business::Rule->fixed(month => 5, day => 24), day_of_week => 1, name => 'Victoria Day');

The first C<day_of_week> on or after, or on or before, another rule's date
plus C<days> (0 by default); C<n> (1 to 5, 1 by default) counts on from
there by weeks. The other rule's date is read before its own L</observed>
move, as L</relative> reads it, and may not be a set or a sandwiched day.

=head2 sandwiched

    Time::Keeper::Business::Rule->set(..., Time::Keeper::Business::Rule->sandwiched(name => '休日'), name => 'Japan');

A member of a set: every weekday whose day before and day after are both
holidays of the set, by their own dates before any move, and which is not
one already, becomes one. Japan's citizens' holiday (国民の休日) is this:
22 September 2026, between Respect for the Aged Day and the autumnal
equinox. Alone, outside a set, it gives nothing.

=head2 set
    Time::Keeper::Business::Rule->set($rule, $rule2, ..., name => 'England and Wales', weekend => [6, 7]);

Rules together, with a name and the weekend their observed moves use
(Saturday and Sunday unless given). A set may hold sets. Observed moves
within a set see each other: first every date that stays put takes its
day, then the ones that move look for a free one, in the order given.

=head2 In another calendar

    my $R = 'Time::Keeper::Business::Rule';
    $R->fixed(calendar => 'islamic-umalqura', month_code => 'M10', day => 1, name => 'Eid al-Fitr');
    $R->fixed(calendar => 'islamic-umalqura', month_code => 'M12', day => 10, name => 'Eid al-Adha');
    $R->fixed(calendar => 'hebrew', month_code => 'M07', day => 15, name => 'Passover');
    $R->fixed(calendar => 'hebrew', month_code => 'M06', day => 14, name => 'Purim');
    $R->fixed(calendar => 'chinese', month_code => 'M01', day => 1, name => 'Lunar New Year');
    $R->fixed(calendar => 'persian', month_code => 'M01', day => 1, name => 'Nowruz');
    $R->nth(calendar => 'hebrew', month_code => 'M07', day_of_week => 6, n => 1);

L</fixed> and L</nth> take C<calendar>, any calendar L<Time::Keeper::Calendar>
knows, and give the month by its C<month_code> in place of C<month>: C<M01>
to C<M13>, with an C<L> after it for a leap month (C<M05L> is Adar I, the
month of a leap Hebrew year that a common year lacks; the Chinese and Dangi
calendars have a leap month after any of theirs). The codes are
L<Time::Keeper/month_code>'s, so C<M06> is Adar in a common year and Adar II in
a leap one, and Purim needs nothing more.

The holidays of a year are every day in that Gregorian year whose date in the
calendar matches, so a holiday of a lunar calendar can come twice in one
year: Eid al-Fitr fell on 8 January and 27 December 2000. A month code that a
calendar year lacks gives no holiday that year, and a day past the end of its
month in that year gives none; C<< leap_month => 'common' >> moves a leap
month's holiday, in a year without that month, to its common month (C<M05L>
to C<M06>, C<M04L> to C<M04>), and C<< 'skip' >>, the default, leaves it out.
A year past a calendar's table (the Chinese, Dangi and astronomical Hijri
calendars hold 1000 to 3000) gives no holiday either.

The dates are the calendar's reckoning, as Time::Keeper reckons it. A
holiday that is declared on a sighting of the moon, as Eid is in many
countries, can fall a day either side of a table such as Umm al-Qura's;
C<islamic> and C<islamic-rgsa> are computed, not observed. A schedule for a
country that declares its days lists the declared day as a literal holiday
for that year, beside or in place of the rule.

=head1 CHANGING A RULE

=head2 observed

    $rule->observed('next_business_day');
    $rule->observed('nearest_business_day');
    $rule->observed('next_monday');
    $rule->observed(sub { my $date = shift; ... });
    $rule->observed('none');
    $rule->observed('next_business_day', weekend => [5, 6]);
    $rule->observed('previous_business_day');
    $rule->observed('next_business_day_if_sunday', keep => 1);

What happens when the date falls on a weekend day. C<next_business_day>
moves to the next weekday that is not already a holiday in the same set:
the United Kingdom's substitute day, so Christmas on a Saturday is kept on
the Monday and Boxing Day on the Tuesday after it. C<nearest_business_day>
moves a Saturday back to the Friday and a Sunday on to the Monday, the
United States federal rule, so New Year's Day on a Saturday is kept on
31 December of the year before. C<next_monday> moves either to the Monday
after. C<previous_business_day> moves to the last weekday before that is not
already a holiday. C<next_business_day_if_sunday> moves a Sunday alone, to the
next weekday that is not already a holiday. With C<< keep => 1 >> the date
itself stays a holiday as well and the moved day is added beside it, as
Japan's substitute holiday (振替休日) is a day added, not a day moved;
without it the date is no longer a holiday, as with the United Kingdom's
substitute days. A code ref is called with the date for every year, weekend or not,
and gives the date to keep, or undef for none. C<none> is the default. The
weekend is Saturday and Sunday unless the rule or its set is given one.

=head2 except

=head2 also

    $rule->except(years => [2020]);
    $rule->also(dates => ['2020-05-08']);
    $rule->except(years => [2020])->also(dates => ['2020-05-08']);   # the 2020 early May bank holiday

Years the rule does not hold, and dates it adds, named as the rule is.
An C<also> date is added whatever the rule's own years say, so the two
together move a holiday for one year, and it never moves: it is a holiday
on that day. Each adds to what an earlier call gave.

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


=head1 SERIALISATION

=head2 TO_JSON

    my $data = Time::Keeper::Business::Rule->uk->TO_JSON;
    # { kind => 'set', name => 'England and Wales', from => 2024, members => [ { kind => 'fixed', ... }, ... ] }

The rule as plain data: a hash of its C<kind> and what its constructor and
changes were given (C<members> for a set, C<rule> for a rule counted from
another, C<observed>, C<keep>, C<weekend>, C<from>, C<to>, C<except>, C<also>
with its dates as strings), each key absent when it was not given. A rule
with a code ref in it, as C<observed> or C<only_if> anywhere in it, has no
data form and dies saying so.

=head2 from_spec

    my $rule = Time::Keeper::Business::Rule->from_spec($data);

The rule again from its data, through the same constructors and changes, so
every check they make is made again: damaged data dies with the
constructor's own message, and a kind this release does not know dies
naming it.

=head2 STORABLE_freeze

=head2 STORABLE_thaw

=head2 FREEZE

=head2 THAW

L<Storable>, and L<Sereal> and L<CBOR::XS> through C<FREEZE> and C<THAW>,
carry the data form, so a thawed rule is the same rule, in the same class.

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

Sweden, whose movable days are a weekday between two dates:

    my $sweden = $r->set(
        $r->fixed(month => 1, day => 1, name => 'Nyårsdagen'),
        $r->fixed(month => 1, day => 6, name => 'Trettondedag jul'),
        $r->easter(offset => -2, name => 'Långfredagen'),
        $r->easter(offset => 1, name => 'Annandag påsk'),
        $r->fixed(month => 5, day => 1, name => 'Första maj'),
        $r->easter(offset => 39, name => 'Kristi himmelsfärdsdag'),
        $r->fixed(month => 6, day => 6, name => 'Sveriges nationaldag'),
        $r->weekday_on_or_after(rule => $r->fixed(month => 6, day => 19), day_of_week => 5, name => 'Midsommarafton'),
        $r->fixed(month => 12, day => 24, name => 'Julafton'),
        $r->fixed(month => 12, day => 25, name => 'Juldagen'),
        $r->fixed(month => 12, day => 26, name => 'Annandag jul'),
        $r->fixed(month => 12, day => 31, name => 'Nyårsafton'),
        name => 'Sverige',
    );

Midsummer Eve and New Year's and Christmas Eves are not public holidays in
the law but are closed as if they were, which is what a schedule wants.
The days that always fall on a Saturday or a Sunday are left out, since
they close no business day. F<eg/sweden.pl> adds them (Easter Day,
Whitsunday, Midsummer Day, All Saints' Day) for the year's full list. The
F<eg/japan.pl> script writes Japan out, from the equinoxes by formula to
the special days of 2019 to 2021 as rules of one year.

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
