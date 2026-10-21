package Time::Keeper::YearMonth;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.11';

use Time::Keeper;

use overload
    '<=>'  => '_compare',
    'cmp'  => '_compare',
    '""'   => 'iso8601',
    '+'    => '_add_overload',
    '-'    => '_sub_overload',
    'bool' => sub { 1 },
    fallback => 1;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::YearMonth - a year and a month

=head1 VERSION

Version 0.11

=head1 SYNOPSIS

    use Time::Keeper;

    my $ym = Time::Keeper::YearMonth->new(year => 2026, month => 10);
    my $ym = Time::Keeper::YearMonth->parse('2026-10');
    my $ym = $t->to_year_month;

    $ym->days_in_month;             # 31
    $ym->plus(months => 3);         # 2027-01
    $ym->on(15);                    # a Time::Keeper::Date, 2026-10-15
    $ym->last_day;                  # 2026-10-31
    $ym->format('MMMM y');          # October 2026
    "$ym";                          # 2026-10

=head1 DESCRIPTION

A year and a month: a billing period, a statement, a month in a report. It
has no day, so nothing that needs one: no day of the week, no week, no
date formats that write a day. L</on> and L</last_day> give a
L<Time::Keeper::Date> when a day is chosen.

=head1 CONSTRUCTORS

=head2 new

    Time::Keeper::YearMonth->new(year => 2026, month => 10);
    Time::Keeper::YearMonth->new(year => 2026, month => 10, locale => 'fr');

Both are required.

=head2 parse

=head2 strptime

=head2 parse_cldr

    Time::Keeper::YearMonth->parse('2026-10');
    Time::Keeper::YearMonth->strptime('10/2026', '%m/%Y');
    Time::Keeper::YearMonth->parse_cldr('octobre 2026', 'MMMM y', locale => 'fr');

C<parse> reads C<YYYY-MM> and refuses a day, a week, a time or a zone in
the text, and a year alone. Under a pattern a day the pattern reads is
dropped. Each takes C<locale>.

=head2 try_new

=head2 try_parse

=head2 try_strptime

=head2 try_parse_cldr

As the method without C<try_>, but undef where it would die, with C<$@>
left as it was.

=head1 ACCESSORS

=head2 year

=head2 month

=head2 quarter

=head2 is_leap_year

=head2 days_in_month

=head2 days_in_year

=head2 days_in_quarter

=head2 locale

=head2 month_name

=head2 month_abbr

=head2 era_name

=head2 era_abbr

=head2 quarter_name

=head2 quarter_abbr

As L<Time::Keeper::Date>'s.

=head1 NEW VALUES FROM OLD

=head2 with

    $ym->with(month => 12);
    $ym->with(year => 2027);

=head2 in_locale

The same year and month in another locale.

=head2 on

=head2 last_day

    $ym->on(15);          # a Time::Keeper::Date
    $ym->on('last');
    $ym->last_day;        # the same

The date of that day of the month; a day the month does not have is an
error.

=head1 ARITHMETIC

=head2 plus

=head2 minus

    $ym->plus(months => 11);
    $ym->plus(years => 1);
    $ym->minus($other);          # a duration of months

Years and months, by name or as a L<Time::Keeper::Duration>; days and
smaller are an error. C<+> and C<-> do the same.

=head2 truncate

=head2 round

=head2 end_of

To a year or a quarter: the first month of it, the nearest, the last.

=head1 COMPARING AND PRINTING

=head2 compare

As L<Time::Keeper::Date/compare>, between years and months only.

=head2 iso8601

=head2 TO_JSON

C<2026-10>; C<"$ym"> is the same.

=head1 FORMATTING

=head2 strftime

=head2 format

=head2 format_date

=head2 format_skeleton

    $ym->format('MMMM y');
    $ym->strftime('%B %Y');
    $ym->format_date('medium');      # Oct 2026, the locale's yMMM skeleton
    $ym->format_skeleton('yMMM');

A letter that needs a day, a time or a zone is an error naming it.
C<format_date> uses the locale's C<yMMMM> (full and long), C<yMMM>
(medium) and C<yM> (short) skeletons.

=head1 SERIALISATION

=head2 STORABLE_freeze

=head2 STORABLE_thaw

=head2 FREEZE

=head2 THAW

As L<Time::Keeper::Date>'s.

=head1 SEE ALSO

L<Time::Keeper>, L<Time::Keeper::Date>, L<Time::Keeper::MonthDay>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
