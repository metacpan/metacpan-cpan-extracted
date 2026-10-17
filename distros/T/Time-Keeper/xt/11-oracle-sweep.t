#!perl
use 5.014;
use strict;
use warnings;
use utf8;
use Test::More;

# Author test: a sweep against DateTime over every zone, and against
# Time::Piece in UTC and local time. For each zone, random instants: every
# accessor; then in each of 20 locales a fixed set of CLDR patterns. Where a
# locale's output differs, it must be because its CLDR data differs between
# DateTime::Locale's release (47) and this one (48): the names or the
# pattern used are compared, and a difference there explains it.
#
#   TK_SWEEP_INSTANTS=n   instants per zone (20; the plan's full sweep is 10000)
#   TK_SWEEP_LOCALES=n    how many of the 20 locales (20)

BEGIN {
    for my $m (qw(DateTime DateTime::Locale Time::Piece)) {
        eval "require $m; 1" or plan skip_all => "$m is not installed";
    }
}
use POSIX ();
use Time::Keeper;
use Time::Keeper::Locale;
use Time::Keeper::Zone;

my $L = 'Time::Keeper::Locale';
my $per_zone = $ENV{TK_SWEEP_INSTANTS} // 20;
my @locales = qw(en fr de es it pt ru ja zh ko ar hi nl sv pl tr he th id vi);
splice @locales, $ENV{TK_SWEEP_LOCALES} if $ENV{TK_SWEEP_LOCALES} && $ENV{TK_SWEEP_LOCALES} < @locales;

# Zones whose rules changed between DateTime::TimeZone's tzdata (2025c) and
# Zone's (2026e), from the instant they changed.
my %changed_from = (
    (map { $_ => 1767225600 } qw(America/Winnipeg America/Inuvik America/Edmonton
                                 America/Vancouver Africa/Casablanca Africa/El_Aaiun)),
    'Europe/Chisinau' => 1640995200,
);
my %skip = map { $_ => 1 } qw(EST5EDT CST6CDT MST7MDT PST8PDT);
my @zones = grep { !m{^Etc/} && !$skip{$_} && eval { DateTime::TimeZone->new(name => $_); 1 } } Time::Keeper::Zone->names;

my @accessors = (
    [year => 'year'], [month => 'month'], [day => 'day'], [hour => 'hour'], [minute => 'minute'],
    [second => 'second'], [nanosecond => 'nanosecond'], [day_of_week => 'day_of_week'],
    [day_of_year => 'day_of_year'], [quarter => 'quarter'], [day_of_quarter => 'day_of_quarter'],
    [offset => 'offset'], [is_dst => 'is_dst'], [epoch => 'epoch'], [zone_abbr => 'time_zone_short_name'],
    [week => 'week_number'], [week_year => 'week_year'], [week_of_month => 'week_of_month'],
    [days_in_month => 'month_length'], [is_leap_year => 'is_leap_year'], [julian_day => 'jd'], [mjd => 'mjd'],
    [ymd => 'ymd'], [hms => 'hms'], [month_name => 'month_name'], [day_name => 'day_name'],
);

# Each pattern, and the locale data it reads, as [Time::Keeper's, DateTime::Locale's] lists.
my @patterns = (
    ['EEEE d MMMM y G', [qw(days wide format)], [qw(months wide format)], [qw(eras abbreviated)]],
    ['ccc LLL MMMMM d QQQQ', [qw(days abbreviated stand-alone)], [qw(months abbreviated stand-alone)],
                             [qw(months narrow format)], [qw(quarters wide format)]],
    ['h:mm:ss a GGGG', [qw(am_pm abbreviated)], [qw(eras wide)]],
);
my %dtl = (
    'days wide format' => 'day_format_wide', 'months wide format' => 'month_format_wide',
    'eras abbreviated' => 'era_abbreviated', 'days abbreviated stand-alone' => 'day_stand_alone_abbreviated',
    'months abbreviated stand-alone' => 'month_stand_alone_abbreviated', 'months narrow format' => 'month_format_narrow',
    'quarters wide format' => 'quarter_format_wide', 'am_pm abbreviated' => 'am_pm_abbreviated', 'eras wide' => 'era_wide',
);
sub data_differs {
    my ($code, @reads) = @_;
    my $loc = DateTime::Locale->load($code);
    for my $r (@reads) {
        my $key = join ' ', @$r;
        my @mine = $L->names($code, @$r);
        my $theirs = $loc->${ \$dtl{$key} };
        return 1 if join("\0", @mine) ne join("\0", @$theirs);
    }
    return 0;
}

srand(1111);
my ($n, $formats, $explained, %bad) = (0, 0, 0);
for my $zone (@zones) {
    for (1 .. $per_zone) {
        my $e = int(rand(4_000_000_000)) - 1_000_000_000;
        next if $changed_from{$zone} && $e >= $changed_from{$zone};
        my $ns = int rand 1e9;
        my $dt = DateTime->from_epoch(epoch => $e, time_zone => 'UTC')->set_nanosecond($ns)->set_time_zone($zone);
        my $t = Time::Keeper->from_epoch($e)->plus(nanoseconds => $ns)->in_zone($zone);
        $n++;
        for my $a (@accessors) {
            my ($mine, $theirs) = ($t->${ \$a->[0] }, $dt->${ \$a->[1] });
            $_ = $_ ? 1 : 0 for grep { $a->[0] =~ /^is_/ } $mine, $theirs;
            next if $mine eq $theirs || ($a->[0] =~ /julian_day|mjd/ && abs($mine - $theirs) < 1e-6);
            $bad{"accessor $a->[0]"} //= "$zone $e: '$mine', DateTime '$theirs'";
        }
        for my $code (@locales) {
            my $tl = $t->in_locale($code);
            my $dl = $dt->clone->set_locale($code);
            for my $p (@patterns) {
                my ($pat, @reads) = @$p;
                my ($mine, $theirs) = ($tl->format($pat), $dl->format_cldr($pat));
                $formats++;
                next if $mine eq $theirs;
                if (data_differs($code, @reads)) { $explained++; next }
                $bad{"$code '$pat'"} //= "$zone $e: '$mine', DateTime '$theirs'";
            }
            for my $len (qw(full long medium short)) {
                my ($mine, $theirs) = ($tl->format_date($len), $dl->format_cldr($dl->locale->${ \"date_format_$len" }));
                $formats++;
                next if $mine eq $theirs;
                my $same_pattern = ($L->formats($code, 'date'))[{ full => 0, long => 1, medium => 2, short => 3 }->{$len}]
                                   eq $dl->locale->${ \"date_format_$len" };
                if (!$same_pattern || data_differs($code, [qw(months wide format)], [qw(months abbreviated format)],
                                                          [qw(days wide format)], [qw(days abbreviated format)])) {
                    $explained++;
                    next;
                }
                $bad{"$code date $len"} //= "$zone $e: '$mine', DateTime '$theirs'";
            }
        }
    }
}
is(scalar keys %bad, 0, "$n instants in " . scalar(@zones) . " zones agree with DateTime: "
   . scalar(@accessors) . " accessors each, and $formats formats in " . scalar(@locales) . " locales"
   . " ($explained explained by CLDR 47 and 48)")
    or diag(join "\n", map { "$_: $bad{$_}" } sort keys %bad);

# Time::Piece, in UTC and in local time.
my %tp_bad;
my $tp_n = 0;
for my $tzname ('UTC', 'America/New_York', 'Europe/London', 'Australia/Lord_Howe', 'Asia/Kolkata') {
    local $ENV{TZ} = $tzname;
    POSIX::tzset();
    for (1 .. $per_zone * 50) {
        my $e = int(rand(4_000_000_000)) - 1_000_000_000;
        my $tp = $tzname eq 'UTC' ? scalar Time::Piece::gmtime($e) : scalar Time::Piece::localtime($e);
        my $t = Time::Keeper->from_epoch($e, zone => $tzname eq 'UTC' ? 'UTC' : 'local');
        $tp_n++;
        my %pairs = (
            year => [$t->year, $tp->year], mon => [$t->month, $tp->mon], mday => [$t->day, $tp->mday],
            hour => [$t->hour, $tp->hour], min => [$t->minute, $tp->min], sec => [$t->second, $tp->sec],
            wday => [$t->day_of_week % 7 + 1, $tp->wday], yday => [$t->day_of_year - 1, $tp->yday],
            isdst => [$t->is_dst ? 1 : 0, $tp->isdst ? 1 : 0], tzoffset => [$t->offset, 0 + $tp->tzoffset],
            epoch => [$t->epoch, $tp->epoch], week => [$t->week, $tp->week],
            strftime => [$t->strftime('%Y-%m-%d %H:%M:%S %a %b %j %U %W %u %w %y %e'),
                         $tp->strftime('%Y-%m-%d %H:%M:%S %a %b %j %U %W %u %w %y %e')],
        );
        for my $k (sort keys %pairs) {
            next if $pairs{$k}[0] eq $pairs{$k}[1];
            $tp_bad{"$tzname $k"} //= "$e: '$pairs{$k}[0]', Time::Piece '$pairs{$k}[1]'";
        }
    }
}
is(scalar keys %tp_bad, 0, "$tp_n instants agree with Time::Piece in UTC and four local zones")
    or diag(join "\n", map { "$_: $tp_bad{$_}" } sort keys %tp_bad);

done_testing;
