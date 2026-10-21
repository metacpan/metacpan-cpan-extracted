package Time::Keeper::Time;

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

Time::Keeper::Time - a time of day, on no date

=head1 VERSION

Version 0.11

=head1 SYNOPSIS

    use Time::Keeper;

    my $tm = Time::Keeper::Time->new(hour => 9, minute => 5);
    my $tm = Time::Keeper::Time->parse('09:05:07.25');
    my $tm = Time::Keeper::Time->now(zone => 'Europe/London');
    my $tm = $t->to_time;

    $tm->plus(hours => 1);                    # 10:05:07.250
    Time::Keeper::Time->new(hour => 23, minute => 30)->plus(hours => 1);   # 00:30:00
    $tm->round(to => 'minute', increment => 15);
    $tm->format('h:mm a');                    # 9:05 AM
    $date->at($tm, zone => 'Europe/London');  # a Time::Keeper value
    "$tm";                                    # 09:05:07.250

=head1 DESCRIPTION

A time of day with no date and no zone: an alarm, an opening hour, a
schedule. It is not a L<Time::Keeper> value: it has no year, no day of the
week and no zone, a pattern letter that needs one is an error, and it
compares only with another time of day. Arithmetic wraps at midnight, as
Temporal's PlainTime does: 23:30 plus an hour is 00:30. There is no second
60: a leap second is an instant on one day, and L<Time::Keeper/to_time>
during one gives the last nanosecond before it.

=head1 CONSTRUCTORS

=head2 new

    Time::Keeper::Time->new(hour => 9, minute => 5, second => 7, nanosecond => 250_000_000);
    Time::Keeper::Time->new(hour => 9, locale => 'fr');

Each part defaults to 0; C<second> is 0 to 59.

=head2 now

    Time::Keeper::Time->now;                       # the UTC time of day
    Time::Keeper::Time->now(zone => 'Asia/Tokyo');

The time of day now in the zone, from the clock L<Time::Keeper/TESTING>
describes.

=head2 parse

=head2 strptime

=head2 parse_cldr

    Time::Keeper::Time->parse('09:05:07.25');     # also T09:05, 0905, 09.5
    Time::Keeper::Time->strptime('9:05 PM', '%I:%M %p');
    Time::Keeper::Time->parse_cldr('09 h 05', "HH 'h' mm", locale => 'fr');

C<parse> reads ISO 8601's time forms, extended and basic, with or without a
leading C<T>, with a fraction on the last part given; a C<Z>, an offset, a
zone or C<24:00> is an error. Under a pattern, a date the pattern reads is
dropped. Each takes C<locale>.

=head2 try_new

=head2 try_parse

=head2 try_strptime

=head2 try_parse_cldr

As the method without C<try_>, but undef where it would die, with C<$@>
left as it was.

=head1 ACCESSORS

=head2 hour

=head2 minute

=head2 second

=head2 nanosecond

=head2 millisecond

=head2 microsecond

=head2 hour_12

=head2 am_pm

=head2 locale

As L<Time::Keeper/ACCESSORS>.

=head1 NEW VALUES FROM OLD

=head2 with

    $tm->with(minute => 0, second => 0);

=head2 in_locale

The same time of day in another locale.

=head1 ARITHMETIC

=head2 plus

=head2 minus

    $tm->plus(hours => 1);
    $tm->plus(minutes => 90, seconds => 5);
    $tm->minus($duration);
    $tm->minus($other);                 # a signed duration, never wrapped

Hours, minutes, seconds and smaller, by name or as a
L<Time::Keeper::Duration>, wrapping at midnight either way. Days and
months are an error: a time of day has no calendar. C<minus> with another
time gives the duration from it to this one, negative when it is earlier.
C<+> and C<-> do the same.

=head2 truncate

=head2 round

=head2 end_of

    $tm->truncate(to => 'hour');
    $tm->round(to => 'minute', increment => 15, mode => 'floor');

To an hour, minute, second, millisecond, microsecond or nanosecond, as
L<Time::Keeper/truncate> and L<Time::Keeper/round>; a round past 23:59:59
wraps to 00:00:00.

=head1 COMPARING AND PRINTING

=head2 compare

As L<Time::Keeper::Date/compare>, between times of day only.

=head2 iso8601

=head2 TO_JSON

=head2 hms

=head2 time

    $tm->iso8601;                   # 09:05:07.250: 3, 6 or 9 digits, or none
    $tm->iso8601(precision => 0);   # 09:05:07
    $tm->hms;  $tm->hms('.');  $tm->time;

C<"$tm"> and L</TO_JSON> are L</iso8601>. L</hms> and L</time> never write the
fraction.

=head1 FORMATTING

=head2 strftime

=head2 format

=head2 format_time

=head2 format_skeleton

    $tm->format('h:mm a');
    $tm->strftime('%I:%M %p');
    $tm->format_time('short');       # 9:05 AM
    $tm->format_skeleton('Hms');

A letter that needs a date, a day of the week or a zone is an error naming
it; so C<format_time('full')> and C<'long'> are, since the locale's full
and long time formats name the zone.

=head1 SERIALISATION

=head2 STORABLE_freeze

=head2 STORABLE_thaw

=head2 FREEZE

=head2 THAW

As L<Time::Keeper::Date>'s.

=head1 SEE ALSO

L<Time::Keeper>, L<Time::Keeper::Date>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
