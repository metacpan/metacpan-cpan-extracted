package Time::Keeper::Duration;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use Time::Keeper;

use overload
    '+'    => '_add_overload',
    '-'    => '_sub_overload',
    '*'    => '_mul_overload',
    'neg'  => '_neg_overload',
    '<=>'  => '_compare',
    '""'   => 'iso8601',
    'bool' => sub { !$_[0]->is_zero },
    fallback => 1;

1;

__END__

=head1 NAME

Time::Keeper::Duration - an amount of time: months, days, minutes and seconds

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Time::Keeper;

    my $d = Time::Keeper::Duration->new(months => 1, days => 2, hours => 3);
    my $t = Time::Keeper->now->plus($d);
    my $u = Time::Keeper->now + $d;

    my $between = $b - $a;              # a duration
    print $between->days, "\n";
    print "$between\n";                 # P1M2DT3H, ISO 8601

    my $ninety = Time::Keeper::Duration->from_seconds(90);
    print $ninety->total_seconds, "\n"; # 90

=head1 DESCRIPTION

A duration is an amount of time in four units that do not turn into one
another: months, because a month is not a fixed number of days; days,
because a day is not always 24 hours where the clocks change; minutes,
because a minute is not always 60 seconds when there is a leap second;
and seconds, with nanoseconds. Years are kept as months, weeks as days and
hours as minutes.

Each unit has its own sign, so a duration can be a month forward and a day
back. Durations, like L<Time::Keeper> values, never change: every method
that would change one returns a new one.

How a duration is added to a time is described under
L<Time::Keeper/ARITHMETIC>.

=head1 CONSTRUCTORS

=head2 new

    my $d = Time::Keeper::Duration->new(
        years => 1, months => 2, weeks => 3, days => 4,
        hours => 5, minutes => 6, seconds => 7, nanoseconds => 8,
        end_of_month => 'limit',
    );

Every unit is optional and a whole number; nanoseconds past a second are
carried into the seconds exactly. C<end_of_month> is C<wrap>, C<limit> or
C<preserve>, as described under L<Time::Keeper/Months and the end of the
month>.

=head2 from_seconds

    my $d = Time::Keeper::Duration->from_seconds(90);
    my $d = Time::Keeper::Duration->from_seconds('1.000000001');

A duration of seconds alone. A string of digits with up to nine decimal
places is taken exactly; a number with a fraction is rounded to the
microsecond.

=head2 parse

    my $d = Time::Keeper::Duration->parse('P1Y2M3DT4H5M6.5S');

An ISO 8601 duration: C<P>, then years, months, weeks and days, then C<T>
and hours, minutes and seconds, any of them left out, and C<-> before it
for a negative one. The last of the hours, minutes or seconds may have a
fraction: C<PT1.5H> is an hour and 30 minutes. A part may have a sign of
its own, as L</iso8601> writes a duration whose parts differ in sign.

=head1 THE UNITS

As L<DateTime::Duration> gives them: each is the size of its part, never
negative, so a duration of 90 minutes is 1 hour and 30 minutes.

=head2 years

=head2 months

The whole years in the months, and the months left over.

=head2 weeks

=head2 days

The whole weeks in the days, and the days left over.

=head2 hours

=head2 minutes

The whole hours in the minutes, and the minutes left over.

=head2 seconds

=head2 nanoseconds

=head2 in_units

    my ($h, $m) = $d->in_units('hours', 'minutes');

The duration in the units asked for, with signs. Each unit takes what it
can from its own part, the larger units first: years and months from the
months, weeks and days from the days, hours and minutes from the minutes,
seconds and nanoseconds from the seconds. A unit never borrows from
another part, since months, days and minutes do not convert. In scalar
context, the first unit asked for.

=head2 deltas

The five parts as a list of pairs: C<months>, C<days>, C<minutes>,
C<seconds> and C<nanoseconds>.

=head2 end_of_month

C<wrap>, C<limit> or C<preserve>.

=head2 is_positive

=head2 is_negative

=head2 is_zero

True when every part is zero or more and one is more than zero; when every
part is zero or less and one is less; or when every part is zero. A
duration with parts of both signs is neither positive nor negative.

=head2 total_seconds

The duration as a number of seconds, for one with no months or days: those
are not a fixed number of seconds, and a duration with them is an error
here.

=head1 NEW DURATIONS FROM OLD

=head2 inverse

The duration with every part's sign turned over. Its C<end_of_month> is
worked out afresh for its new months unless given:
C<< $d->inverse(end_of_month => 'limit') >>.

=head2 calendar_duration

=head2 clock_duration

The months and days alone, and the minutes and seconds alone.

=head2 plus

=head2 minus

C<< $d->plus($e) >> and C<< $d->minus($e) >>: part by part. C<+> and C<-> are
the same, and C<-$d> is L</inverse>.

=head2 multiply

C<< $d->multiply(3) >>: every part three times, as C<$d * 3>. The factor is a
whole number.

=head1 COMPARING AND PRINTING

=head2 compare

    Time::Keeper::Duration->compare($d, $e);
    Time::Keeper::Duration->compare($d, $e, $start);

-1, 0 or 1 as C<$d> is shorter than, as long as or longer than C<$e>,
measured from C<$start>, or from now. A month is longer from 1 January than
from 1 February, so durations with months or days compare only from a
starting point: C<< <=> >> compares durations without them, and is an error
for those with.

=head2 iso8601

The ISO 8601 form, such as C<P1Y2M3DT4H5M6.5S>, as C<"$d"> gives it. A
duration whose parts have both signs has no ISO 8601 form; each part is
then given with its own sign, as C<P1M-2D>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
