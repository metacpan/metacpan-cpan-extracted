package Time::Keeper::MonthDay;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.04';

use Time::Keeper;

use overload
    '<=>'  => '_compare',
    'cmp'  => '_compare',
    '""'   => 'iso8601',
    'bool' => sub { 1 },
    fallback => 1;

1;

__END__

=encoding utf8

=head1 NAME

Time::Keeper::MonthDay - a month and a day, in no year

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    use Time::Keeper;

    my $md = Time::Keeper::MonthDay->new(month => 2, day => 29);
    my $md = Time::Keeper::MonthDay->parse('--02-29');
    my $md = $t->to_month_day;

    $md->in_year(2024);                            # a Time::Keeper::Date, 2024-02-29
    $md->in_year(2027, end_of_month => 'limit');   # 2027-02-28
    $md->format('MMMM d');                         # February 29
    "$md";                                         # --02-29

=head1 DESCRIPTION

A month and a day in no year: a birthday, an anniversary, a holiday that
falls on the same date every year. 29 February is one. It has no year, so
no day of the week, no quarter, no arithmetic; L</in_year> gives a
L<Time::Keeper::Date> when a year is chosen.

=head1 CONSTRUCTORS

=head2 new

    Time::Keeper::MonthDay->new(month => 2, day => 29);

Both are required; a day no month has is an error.

=head2 parse

=head2 strptime

=head2 parse_cldr

    Time::Keeper::MonthDay->parse('--02-29');     # also --0229 and 02-29
    Time::Keeper::MonthDay->strptime('29/02', '%d/%m');
    Time::Keeper::MonthDay->parse_cldr('29 February', 'd MMMM');

C<parse> reads ISO 8601's C<--MM-DD> and C<--MMDD>, and C<MM-DD>. Under a
pattern a year the pattern reads is dropped, so 29 February stands
whatever year the text named. Each takes C<locale>.

=head2 try_new

=head2 try_parse

=head2 try_strptime

=head2 try_parse_cldr

As the method without C<try_>, but undef where it would die, with C<$@>
left as it was.

=head1 ACCESSORS

=head2 month

=head2 day

=head2 locale

=head2 month_name

=head2 month_abbr

As L<Time::Keeper::Date>'s.

=head1 NEW VALUES FROM OLD

=head2 with

    $md->with(day => 1);

=head2 in_locale

The same month and day in another locale.

=head2 in_year

    $md->in_year(2024);
    $md->in_year(2027, end_of_month => 'limit');   # 28 February
    $md->in_year(2027, end_of_month => 'wrap');    # 1 March

The date in that year. 29 February in a common year is an error unless
C<end_of_month> says what to do: C<limit> gives the last day of the month,
C<wrap> the day after it.

=head1 COMPARING AND PRINTING

=head2 compare

As L<Time::Keeper::Date/compare>, between months and days only.

=head2 iso8601

=head2 TO_JSON

C<--02-29>; C<"$md"> is the same.

=head1 FORMATTING

=head2 strftime

=head2 format

=head2 format_date

=head2 format_skeleton

    $md->format('MMMM d');
    $md->strftime('%d %B');
    $md->format_date('long');        # February 29, the locale's MMMMd skeleton
    $md->format_skeleton('MMMd');

A letter that needs a year, a day of the week, a time or a zone is an
error naming it. C<format_date> uses the locale's C<MMMMd> (full and
long), C<MMMd> (medium) and C<Md> (short) skeletons.

=head1 SERIALISATION

=head2 STORABLE_freeze

=head2 STORABLE_thaw

=head2 FREEZE

=head2 THAW

As L<Time::Keeper::Date>'s.

=head1 SEE ALSO

L<Time::Keeper>, L<Time::Keeper::Date>, L<Time::Keeper::YearMonth>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
