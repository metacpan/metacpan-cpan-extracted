package Tripletail::DateTime::Format::Generic;
use strict;
use warnings;
use Exporter 'import';
use Tripletail::DateTime::Calendar::Gregorian qw(fromGregorianRollOver);
use Tripletail::DateTime::LocalTime qw(getCurrentTimeZone timeOfDayToTime);
our @EXPORT_OK = qw(
    $RE_GENERIC_TIMEZONE
    parseGenericDateTime
    parseGenericTimeZone
    renderGenericTimeZone
   );

my %TZ_TABLE = (
    gmt  =>   0,       # Greenwich Mean
    ut   =>   0,       # Universal Time
    utc  =>   0,       # Universal Time (Coordinated)
    wet  =>   0,       # Western European
    wat  =>  -1*60,    # West Africa
    at   =>  -2*60,    # Azores
    ast  =>  -4*60,    # Atlantic Standard
    est  =>  -5*60,    # Eastern Standard
    cst  =>  -6*60,    # Central Standard
    mst  =>  -7*60,    # Mountain Standard
    pst  =>  -8*60,    # Pacific Standard
    yst  =>  -9*60,    # Yukon Standard
    hst  => -10*60,    # Hawaii Standard
    cat  => -10*60,    # Central Alaska
    ahst => -10*60,    # Alaska-Hawaii Standard
    nt   => -11*60,    # Nome
    idlw => -12*60,    # International Date Line West
    cet  =>  +1*60,    # Central European
    met  =>  +1*60,    # Middle European
    mewt =>  +1*60,    # Middle European Winter
    swt  =>  +1*60,    # Swedish Winter
    fwt  =>  +1*60,    # French Winter
    eet  =>  +2*60,    # Eastern Europe, USSR Zone 1
    bt   =>  +3*60,    # Baghdad, USSR Zone 2
    zp4  =>  +4*60,    # USSR Zone 3
    zp5  =>  +5*60,    # USSR Zone 4
    ist  =>  +5*60+30, # Indian Standard
    zp6  =>  +6*60,    # USSR Zone 5
    wast =>  +7*60,    # West Australian Standard
    cct  =>  +8*60,    # China Coast, USSR Zone 7
    jst  =>  +9*60,    # Japan Standard, USSR Zone 8
    east => +10*60,    # Eastern Australian Standard
    gst  => +10*60,    # Guam Standard, USSR Zone 9
    nzt  => +12*60,    # New Zealand
    nzst => +12*60,    # New Zealand Standard
    idle => +12*60,    # International Date Line East
   );
my %TZ_TABLE_OFF = reverse(%TZ_TABLE);

my %TZ_TABLE_DST = (
    adt  =>  -3*60,    # Atlantic Daylight
    edt  =>  -4*60,    # Eastern Daylight
    cdt  =>  -5*60,    # Central Daylight
    mdt  =>  -6*60,    # Mountain Daylight
    pdt  =>  -7*60,    # Pacific Daylight
    ydt  =>  -8*60,    # Yukon Daylight
    hdt  =>  -9*60,    # Hawaii Daylight
    bst  =>  +1*60,    # British Summer
    mest =>  +2*60,    # Middle European Summer
    sst  =>  +2*60,    # Swedish Summer
    fst  =>  +2*60,    # French Summer
    wadt =>  +8*60,    # West Australian Daylight
    eadt => +11*60,    # Eastern Australian Daylight
    nzdt => +13*60,    # New Zealand Daylight
   );
my %TZ_TABLE_DST_OFF = reverse(%TZ_TABLE_DST);

sub _a2r_i {
    my $re = join('|', map { quotemeta } @_);
    return qr/$re/i;
}

=encoding utf8

=head1 NAME

Tripletail::DateTime::Format::Generic - 内部用

=begin comment

=head1 DESCRIPTION

This module provides a function to parse generic date and time
strings.

=head1 EXPORT

Nothing by default.

=head1 VARIABLES

=head2 C<< $RE_GENERIC_TIMEZONE >>

A variable containing a compiled regex which matches to generic
time-zone names. You must not modify it.

=cut

our $RE_GENERIC_TIMEZONE = _a2r_i(keys %TZ_TABLE, keys %TZ_TABLE_DST);

=head1 FUNCTIONS

=head2 C<< parseGenericDateTime >>

    my ($localDay, $localDayTime, $timeZone)
      = parseGenericDateTime('2000/1/2 3:4:5');

Try to parse the given string as a generic date and time
format. Return a triple of local MJD, local day time, and time-zone on
success, nothing otherwise.

=cut

my $RE_4YEAR  = qr/\d{4}/;

my $RE_2MONTH = qr/0[1-9]|1[0-2]/;
my $RE_1MONTH = qr/0?[1-9]|1[0-2]/;

my $RE_2DAY   = qr/0[1-9]|[12][0-9]|3[01]/;
my $RE_1DAY   = qr/0?[1-9]|[12][0-9]|3[01]/;

my $RE_2H     = qr/2[0-3]|[0-1][0-9]/; # 00 .. 23
my $RE_2M     = qr/[0-5][0-9]/;        # 00 .. 59
my $RE_2S     = qr/60|$RE_2M/;         # 00 .. 60

my $RE_1H     = qr/2[0-3]|1[0-9]|0?[0-9]/; # 0 .. 23
my $RE_1M     = qr/[1-5][0-9]|0?[0-9]/;    # 0 .. 59
my $RE_1S     = qr/60|$RE_1M/;             # 0 .. 60

my $RE_DELIM  = qr/[ !\@#\$%^&*\-_+=|\\~`:;"',.\?\/]/;

my $RE_GENERIC_YMD          = qr/($RE_4YEAR)$RE_DELIM?($RE_2MONTH)$RE_DELIM?($RE_2DAY)/;
my $RE_GENERIC_HMS          = qr/($RE_2H)$RE_DELIM?($RE_2M)(?:$RE_DELIM?($RE_2S))?/;
my $RE_GENERIC_YMDHMS       = qr/$RE_GENERIC_YMD\s*$RE_GENERIC_HMS/;

my $RE_GENERIC_FUZZY_YMD    = qr/($RE_4YEAR)$RE_DELIM($RE_1MONTH)$RE_DELIM($RE_1DAY)/;
my $RE_GENERIC_FUZZY_HMS    = qr/($RE_1H)$RE_DELIM($RE_1M)(?:$RE_DELIM($RE_1S))?/;
my $RE_GENERIC_FUZZY_YMDHMS = qr/$RE_GENERIC_FUZZY_YMD\s*$RE_GENERIC_FUZZY_HMS/;

sub parseGenericDateTime {
    my $str = shift;

    if ($str =~ m/^$RE_GENERIC_YMDHMS$/o or $str =~ m/^$RE_GENERIC_FUZZY_YMDHMS$/o) {
        return (
            fromGregorianRollOver($1, $2, $3),
            timeOfDayToTime($4, $5, defined $6 ? $6 : 0),
            getCurrentTimeZone()
           );
    }
    elsif ($str =~ m/^$RE_GENERIC_YMD$/o or $str =~ m/^$RE_GENERIC_FUZZY_YMD$/o) {
        return (
            fromGregorianRollOver($1, $2, $3),
            0,
            getCurrentTimeZone()
           );
    }
    else {
        return;
    }
}

=head2 C<< parseGenericTimeZone >>

    my $tz = parseGenericTimeZone('JST');

Try to parse a given string as a generic time-zone. Return the number
of minutes offset from UTC on success, nothing otherwise.

=cut

sub parseGenericTimeZone {
    my $name = lc shift;

    if (defined(my $tz = $TZ_TABLE{$name})) {
        return $tz;
    }
    elsif (defined($tz = $TZ_TABLE_DST{$name})) {
        return $tz;
    }
    else {
        return;
    }
}

=head2 C<< renderGenericTimeZone >>

    my $str = renderGenericTimeZone($tz);

Try to render the number of minutes offset from UTC into a string
representing a generic time-zone. Return nothing on failure.

=cut

sub renderGenericTimeZone {
    my $tz = shift;

    if (defined(my $name = $TZ_TABLE_OFF{$tz})) {
        return $name;
    }
    elsif (defined($name = $TZ_TABLE_DST_OFF{$tz})) {
        return $name;
    }
    else {
        return;
    }
}

=end comment

=head1 SEE ALSO

L<Tripletail::DateTime>

=head1 AUTHOR INFORMATION

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

Official web site: http://tripletail.jp/

=cut

1;
