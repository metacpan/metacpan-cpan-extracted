#####################################################################
## ABSTRACT: Convert various epoch times to Time::Moment times.
#####################################################################


package Time::Moment::Epoch;
our $VERSION = '1.004001'; # VERSION

use v5.10;
use strict;
use warnings;
use parent qw(Exporter);
use Hash::MostUtils qw(hashmap);
use Math::BigInt try => 'GMP';
use Math::BigFloat;
use Scalar::Util qw(looks_like_number);
use Time::Moment;

my $SECONDS_PER_DAY = 24 * 60 * 60;
my $NANOSECONDS_PER_DAY = $SECONDS_PER_DAY * 1e9;

# Time::Moment can represent all epoch integers from -62,135,596,800
# to 253,402,300,799; this range suffices to measure times to
# nanosecond precision for any instant that is within
# 0001-01-01T00:00:00Z to 9999-12-31T23:59:59Z.
my $MAX_SECONDS = 253_402_300_799;
my $MIN_SECONDS = -62_135_596_800;

# Here are a few more constants from moment.h that we need.
my $MAX_UNIT_DAYS = 3652425;
my $MIN_UNIT_DAYS = -3652425;
my $MAX_UNIT_MONTHS = 120000;
my $MIN_UNIT_MONTHS = -120000;

our @conversions = qw(
    apfs
    chrome
    cocoa
    dos
    google_calendar
    icq
    java
    mozilla
    ole
    symbian
    unix
    uuid_v1
    windows_date
    windows_file
    windows_system
);
our @to_conversions = map {"to_$_"} @conversions;
our @EXPORT_OK = (@conversions,    @to_conversions,
                  qw(@conversions @to_conversions));
our %EXPORT_TAGS = (all => [@EXPORT_OK]);


# APFS time is in nanoseconds since the Unix epoch.
sub apfs {
    my $num = shift;
    _epoch2time($num, 1_000_000_000);
}
sub to_apfs {
    my $tm = shift;
    _time2epoch($tm, 1_000_000_000);
}



# Chrome time is the number of microseconds since 1601-01-01, which is
# 11,644,473,600 seconds before the Unix epoch.
#
sub chrome {
    my $num = shift;
    _epoch2time($num, 1_000_000, -11_644_473_600);
}
sub to_chrome {
    my $tm = shift;
    _time2epoch($tm, 1_000_000, -11_644_473_600);
}


# Cocoa time is the number of seconds since 2001-01-01, which
# is 978,307,200 seconds after the Unix epoch.
sub cocoa {
    my $num = shift;
    _epoch2time($num, 1, 978_307_200);
}
sub to_cocoa {
    my $tm = shift;
    _time2epoch($tm, 1, 978_307_200);
}


# DOS time uses bit fields to store dates between 1980-01-01 and
# 2107-12-31 (it fails outside that range).
sub dos {
    my $num = shift;

    my $year   = ($num >> 25) & 0b1111111;

    my $month  = ($num >> 21) &    0b1111;
    return if $month < 1 or $month > 12;

    my $day    = ($num >> 16) &   0b11111;
    return if $day < 1 or $day > 31;

    my $hour   = ($num >> 11) &   0b11111;
    return if $hour < 0 or $hour > 23;

    my $minute = ($num >>  5) &  0b111111;
    return if $minute < 0 or $minute > 60;

    my $second = ($num      ) &   0b11111;
    return if $second < 0 or $second > 60;

    Time::Moment->new(
        year   => 1980 + $year,
        month  => $month,
        day    => $day,
        hour   => $hour,
        minute => $minute,
        second => 2 * $second,
    );

}
sub to_dos {
    my $tm = shift;

    if (ref $tm ne 'Time::Moment') {
        $tm = Time::Moment->from_string($tm);
    }

    ($tm->year - 1980  << 25) +
    ($tm->month        << 21) +
    ($tm->day_of_month << 16) +
    ($tm->hour         << 11) +
    ($tm->minute       <<  5) +
    ($tm->second / 2);

}


# Google Calendar time seems to count 32-day months from the day
# before the Unix epoch. @noppers worked out how to do this.
sub google_calendar {
    my $n = shift;

    return unless looks_like_number $n;

    my $b = Math::BigInt->new($n);
    my($total_days, $seconds) = $b->bdiv($SECONDS_PER_DAY);
    my($months, $days) = $total_days->bdiv(32);

    return if $months < $MIN_UNIT_MONTHS
        or $months > $MAX_UNIT_MONTHS;

    Time::Moment
          ->from_epoch(-$SECONDS_PER_DAY)
          ->plus_days($days)
          ->plus_months($months)
          ->plus_seconds($seconds);
}
sub to_google_calendar {
    my $tm = shift;

    if (ref $tm ne 'Time::Moment') {
        $tm = Time::Moment->from_string($tm);
    }

    ((((($tm->year - 1970 )*12
      + ($tm->month -   1))*32
      +  $tm->day_of_month)*24
      +  $tm->hour        )*60
      +  $tm->minute      )*60
      +  $tm->second;
}


#  ICQ time is the number of days since 1899-12-30, which is
#  2,209,161,600 seconds before the Unix epoch. Days can have a
#  fractional part.
sub icq {
    my $days = shift // return;

    return unless looks_like_number $days;

    my $t = Time::Moment->from_epoch(-2_209_161_600);

    my $intdays = int($days);

    return if $intdays < $MIN_UNIT_DAYS
        or $intdays > $MAX_UNIT_DAYS;

    # Want the fractional part of the day in nanoseconds.
    my $fracday = int(($days - $intdays) * $NANOSECONDS_PER_DAY);

    return $t->plus_days($intdays)->plus_nanoseconds($fracday);
}
sub to_icq {
    my $tm = shift;

    if (ref $tm ne 'Time::Moment') {
        $tm = Time::Moment->from_string($tm);
    }

    my $t2 = Time::Moment->from_epoch(-2_209_161_600);

    $t2->delta_nanoseconds($tm) / $NANOSECONDS_PER_DAY;
}


# Java time is in milliseconds since the Unix epoch.
sub java {
    my $num = shift;
    _epoch2time($num, 1000);
}
sub to_java {
    my $tm = shift;
    _time2epoch($tm, 1000);
}


# Mozilla time is in microseconds since the Unix epoch.
sub mozilla {
    my $num = shift;
    _epoch2time($num, 1_000_000);
}
sub to_mozilla {
    my $tm = shift;
    _time2epoch($tm, 1_000_000);
}


#  OLE time is the number of days since 1899-12-30, which is
#  2,209,161,600 seconds before the Unix epoch.
sub ole {
    my $bytes = shift // return;

    my $d_days = unpack('d', $bytes) or return;

    return if $d_days eq '-nan';

    return icq $d_days;
}
sub to_ole {
    my $t = shift // return;

    my $icq = to_icq($t);

    my $epoch = pack('d', $icq) or return;

    return $epoch;
}


# Symbian time is the number of microseconds since the year 0, which
# is 62,167,219,200 seconds before the Unix epoch.
sub symbian {
    my $num = shift;
    _epoch2time($num, 1_000_000, -62_167_219_200);
}
sub to_symbian {
    my $tm = shift;
    _time2epoch($tm, 1_000_000, -62_167_219_200);
}


# Unix time is the number of seconds since 1970-01-01.
sub unix {
    my $num = shift;
    _epoch2time($num);
}
sub to_unix {
    my $tm = shift;
    _time2epoch($tm);
}


# UUID version 1 time (RFC 4122) is the number of hectonanoseconds
# (100 ns) since 1582-10-15, which is 12,219,292,800 seconds before
# the Unix epoch.
sub uuid_v1 {
    my $num = shift;
    _epoch2time($num, 10_000_000, -12_219_292_800);
}
sub to_uuid_v1 {
    my $tm = shift;
    _time2epoch($tm, 10_000_000, -12_219_292_800);
}


# Windows date time (e.g., .NET) is the number of hectonanoseconds
# (100 ns) since 0001-01-01, which is 62,135,596,800 seconds before
# the Unix epoch.
sub windows_date {
    my $num = shift;
    _epoch2time($num, 10_000_000, -62_135_596_800);
}
sub to_windows_date {
    my $tm = shift;
    _time2epoch($tm, 10_000_000, -62_135_596_800);
}


# Windows file time (e.g., NTFS) is the number of hectonanoseconds
# (100 ns) since 1601-01-01, which is 11,644,473,600 seconds before
# the Unix epoch.
sub windows_file {
    my $num = shift;
    _epoch2time($num, 10_000_000, -11_644_473_600);
}
sub to_windows_file {
    my $tm = shift;
    _time2epoch($tm, 10_000_000, -11_644_473_600);
}


sub windows_system {
    my $num = shift;

    if ($num =~ /^[0-9a-fA-F]{32}$/) {
        $num = "0x$num";
    }

    my $bigint = Math::BigInt->new($num);
    return if $bigint eq 'NaN';

    my $hex = substr $bigint->as_hex, 2;

    return if length $hex > 32;
    return if length $hex < 0;
    $hex = "0$hex" while length $hex < 32;

    my @bytes = ($hex =~ /../g);
    my @keys = qw(year month day_of_week day hour minute second milliseconds);
    my @values = hashmap {hex "$b$a"} @bytes;

    my %wst;
    @wst{@keys} = @values;

    return unless
        $wst{year}         >= 1601 and $wst{year}         <= 30827 and
        $wst{month}        >=    1 and $wst{month}        <=    12 and
        $wst{day_of_week}  >=    0 and $wst{day_of_week}  <=     6 and
        $wst{day}          >=    1 and $wst{day}          <=    31 and
        $wst{hour}         >=    0 and $wst{hour}         <=    23 and
        $wst{minute}       >=    0 and $wst{minute}       <=    59 and
        $wst{second}       >=    0 and $wst{second}       <=    59 and
        $wst{milliseconds} >=    0 and $wst{milliseconds} <=   999;

    return Time::Moment->new(
        year       => $wst{year},
        month      => $wst{month},
        day        => $wst{day},
        hour       => $wst{hour},
        minute     => $wst{minute},
        second     => $wst{second},
        nanosecond => $wst{milliseconds} * 1e6);
}

sub to_windows_system {
    my $tm = shift;
    $tm = Time::Moment->from_string($tm);
    
    return unless
        $tm->year         >= 1601 and $tm->year         <= 30827 and
        $tm->month        >=    1 and $tm->month        <=    12 and
        $tm->day_of_week  >=    1 and $tm->day_of_week  <=     7 and
        $tm->day_of_month >=    1 and $tm->day_of_month <=    31 and
        $tm->hour         >=    0 and $tm->hour         <=    23 and
        $tm->minute       >=    0 and $tm->minute       <=    59 and
        $tm->second       >=    0 and $tm->second       <=    59 and
        $tm->millisecond  >=    0 and $tm->millisecond  <=   999;

    my $hex = sprintf "%04x%04x%04x%04x%04x%04x%04x%04x",
        $tm->year,
        $tm->month,
        $tm->day_of_week % 7,
        $tm->day_of_month,
        $tm->hour,
        $tm->minute,
        $tm->second,
        $tm->millisecond;

    # Change endian-ness.
    join '', hashmap {"$b$a"} ($hex =~ /../g);
}

sub _epoch2time {
    my $num = shift // return;
    my $q = shift // 1;
    my $s = shift // 0;

    return unless looks_like_number $num;

    my($z, $m) = Math::BigInt->new($num)->bdiv($q);
    my $seconds = $z + $s;

    return if $seconds < $MIN_SECONDS or $seconds > $MAX_SECONDS;

    my $nanoseconds = ($m * 1e9)->bdiv($q);

    Time::Moment->from_epoch($seconds, $nanoseconds);
}

sub _time2epoch {
    my $t = shift // return;
    my $m = shift // 1;
    my $s = shift // 0;

    if (ref $t ne 'Time::Moment') {
        $t = Time::Moment->from_string($t);
    }

    my $bf = Math::BigFloat->new($t->nanosecond)->bdiv(1e9);
    int $m*($t->epoch + $bf - $s);
}

1;

__END__

=pod

=for :stopwords Tim Heaney Alexandr Ciornii Ehlers Mary iopuckoi

=head1 NAME

Time::Moment::Epoch - Convert various epoch times to Time::Moment times.

=head1 NAME

Time::Moment::Epoch

=head1 DESCRIPTION

Convert various epoch times to and from datetimes using L<Time::Moment>.

=head1 SYNOPSIS

    use Time::Moment::Epoch qw(:all);

    say unix(1234567890);                           # 2009-02-13T23:31:30Z
    say to_unix('2009-02-13T23:31:30Z');            # 1234567890

    say chrome(12879041490654321);                  # 2009-02-13T23:31:30.654321Z
    say to_chrome('2009-02-13T23:31:30.654321Z');   # 12879041490654321

=head1 CONVERSIONS

The following functions convert an epoch of the specified type to a
Time::Moment object.

They each have a corresponding C<to_$type> function which accepts a
datetime string (in any format accepted by the C<from_string> method
of L<Time::Moment>) and returns the corresponding epoch.

=head2 apfs

APFS time is the number of nanoseconds since the Unix epoch. Cf., APFS
filesystem format (https://blog.cugu.eu/post/apfs/).

=head2 chrome

Chrome time is the number of microseconds since S<1601-01-01>.

=head2 cocoa

Cocoa time is the number of seconds since S<2001-01-01>.

=head2 dos

DOS time stores dates since S<1980-01-01> in bitfields.

=head2 google_calendar

Google Calendar time is 32-day months from the day before the Unix epoch.

=head2 icq

ICQ time is the number of days (with an allowed fractional part) since
S<1899-12-30>.

=head2 java

Java time is the number of milliseconds since the Unix epoch.

=head2 mozilla

Mozilla time is the number of microseconds since the Unix epoch.

=head2 ole

OLE time is the number of days since S<1899-12-30>, packed as a
double-precision float in native format.

=head2 symbian

Symbian time is the number of microseconds since the year 0.

=head2 unix

Unix time is the number of seconds since S<1970-01-01>.

=head2 uuid_v1

UUID version 1 time (RFC 4122) is the number of hectonanoseconds
S<(100 ns)> since S<1582-10-15>.

=head2 windows_date

Windows date time (e.g., .NET) is the number of hectonanoseconds
S<(100 ns)> since S<0001-01-01>.

=head2 windows_file

Windows file time (e.g., NTFS) is the number of hectonanoseconds
S<(100 ns)> since S<1601-01-01>.

=head2 windows_system

Windows system time is a sixteen byte representation of Windows file
time. It's in eight sixteen-bit segments...sort of like a ctime.

year         1601..30827
month        1..12       (January..December)
day_of_week  0..6        (Sunday..Saturday)
day          1..31
hour         0..23
minute       0..59
second       0..59
milliseconds 0..999

Note that Time::Moment day_of_week is one-based and starts on Monday
(so Sunday is 7 instead of 0).

=head1 SEE ALSO

=over

=item L<Time::Moment>

=back

=head1 VERSION

version 1.004001

=head1 AUTHOR

Tim Heaney <heaney@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Alexandr Ciornii Mary Ehlers Tim Heaney iopuckoi

=over 4

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

Mary Ehlers <regina.verb.ae@gmail.com>

=item *

Tim Heaney <oylenshpeegul@proton.me>

=item *

iopuckoi <iopuckoi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tim Heaney.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
