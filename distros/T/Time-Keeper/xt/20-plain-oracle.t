#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use utf8;
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# The plain date classes against DateTime truncated to the day in floating
# time: the accessors, the string forms, strftime's and format_cldr's date
# letters, single-unit arithmetic, the differences and the names in three
# locales. Author only.
BEGIN {
    eval { require DateTime; 1 } or plan skip_all => 'DateTime is not installed';
}
use Time::Keeper;

my $N = $ENV{TK_ORACLE_N} || 5000;
my $D = 'Time::Keeper::Date';
my @strf = qw(%Y %C %y %m %B %b %d %e %j %u %w %a %A %U %W %V %G %g %F %D);
my @cldr = ('yyyy-MM-dd', 'EEEE d MMMM y', 'QQQ y', 'LLL', 'EEE, MMM d, y', 'D', 'F', 'GGGG y', 'u');
my (%bad, $checks);
sub check {
    my ($what, $mine, $theirs, $where) = @_;
    $checks++;
    return if $mine eq $theirs;
    $bad{$what}++;
    diag("$where: $what: ours '$mine', DateTime '$theirs'") if $bad{$what} <= 3;
}

srand(20261018);
for my $i (1 .. $N) {
    my $epoch = int(rand(4_000_000_000)) - 1_000_000_000;
    my $d = Time::Keeper->from_epoch($epoch)->to_date;
    my $dt = DateTime->from_epoch(epoch => $epoch)->set_time_zone('floating')->truncate(to => 'day');
    my $where = "$d";
    for my $m (qw(year month day day_of_week day_of_year quarter day_of_quarter week week_year is_leap_year)) {
        my $theirs = $m eq 'week' ? ($dt->week)[1] : $m eq 'week_year' ? ($dt->week)[0] : $dt->$m;
        check($m, $d->$m, $theirs, $where);
    }
    check('days_in_month', $d->days_in_month, DateTime->last_day_of_month(year => $dt->year, month => $dt->month)->day, $where);
    check('ymd', $d->ymd, $dt->ymd, $where);
    check('mdy', $d->mdy('/'), $dt->mdy('/'), $where);
    check('dmy', $d->dmy('.'), $dt->dmy('.'), $where);
    check('iso8601', "$d", $dt->ymd, $where);
    check('epoch_days', $d->epoch_days, int(($dt->epoch) / 86400), $where);
    for my $p (@strf) {
        check("strftime $p", $d->strftime($p), $dt->strftime($p), $where);
    }
    for my $p (@cldr) {
        check("format $p", $d->format($p), $dt->format_cldr($p), $where);
    }
    my $months = int(rand(60)) - 30;
    my $days = int(rand(2000)) - 1000;
    check("plus months $months (limit)", $d->plus(months => $months, end_of_month => 'limit') . '', $dt->clone->add(months => $months, end_of_month => 'limit')->ymd, $where);
    check("plus days $days", $d->plus(days => $days) . '', $dt->clone->add(days => $days)->ymd, $where);
    my $e = $d->plus(days => $days);
    my $dte = $dt->clone->add(days => $days);
    check('delta_days', $d->delta_days($e)->in_units('days'), abs($dt->delta_days($dte)->delta_days), $where);
    check('delta_days sign-free', $e->delta_days($d)->in_units('days'), abs($dt->delta_days($dte)->delta_days), $where);
    check('to_year_month', $d->to_year_month . '', $dt->strftime('%Y-%m'), $where) if $dt->year >= 0 && $dt->year <= 9999;
    check('to_month_day', $d->to_month_day . '', $dt->strftime('--%m-%d'), $where);
    if ($i % 10 == 0) {
        for my $loc (qw(fr de ja)) {
            my $dl = $d->in_locale($loc);
            my $dtl = $dt->clone->set_locale($loc);
            check("month_name $loc", $dl->month_name, $dtl->month_name, $where);
            check("day_name $loc", $dl->day_name, $dtl->day_name, $where);
            check("month_abbr $loc", $dl->month_abbr, $dtl->month_abbr, $where);
            check("format EEEE d MMMM y $loc", $dl->format('EEEE d MMMM y'), $dtl->format_cldr('EEEE d MMMM y'), $where);
        }
    }
}
# Times of day against DateTime on 1970-01-01, floating: the accessors, the
# string forms, the time letters, and clock arithmetic within the day.
my @tstrf = qw(%H %I %k %l %M %S %p %T %R %r %N);
my @tcldr = (q{HH:mm:ss}, q{h:mm a}, q{H}, q{K:mm}, q{k}, q{hh a}, q{mm}, q{ss.SSS});
for my $i (1 .. int($N / 2)) {
    my $sod = int(rand(86400));
    my $ns = int(rand(1_000_000_000));
    my $tm = Time::Keeper::Time->new(hour => int($sod / 3600), minute => int($sod / 60) % 60, second => $sod % 60, nanosecond => $ns);
    my $dt = DateTime->new(year => 1970, month => 1, day => 1, hour => int($sod / 3600), minute => int($sod / 60) % 60, second => $sod % 60, nanosecond => $ns, time_zone => q{floating});
    my $where = "$tm";
    for my $m (qw(hour minute second nanosecond millisecond microsecond hour_12)) {
        check($m, $tm->$m, $dt->$m, $where);
    }
    check(q{hms}, $tm->hms, $dt->hms, $where);
    for my $p (@tstrf) {
        check("strftime $p", $tm->strftime($p), $dt->strftime($p), $where);
    }
    for my $p (@tcldr) {
        check("format $p", $tm->format($p), $dt->format_cldr($p), $where);
    }
    my $mins = int(rand(1440)) - 720;
    my $dta = $dt->clone->add(minutes => $mins);
    check("plus minutes $mins", $tm->plus(minutes => $mins)->hms, $dta->hms, $where) if $dta->day == 1;
    my $secs = int(rand(7200)) - 3600;
    my $dts = $dt->clone->add(seconds => $secs);
    check("plus seconds $secs", $tm->plus(seconds => $secs)->hms, $dts->hms, $where) if $dts->day == 1;
    if ($dts->day == 1) {
        my $e = $tm->plus(seconds => $secs);
        check(q{difference}, ($e - $tm)->total_seconds, $dts->subtract_datetime_absolute($dt)->in_units(q{seconds}), $where);
    }
}

my $failed = 0;
$failed += $bad{$_} for keys %bad;
is($failed, 0, "$checks checks on $N dates and times agree with DateTime") or diag(join "\n", map { "$_: $bad{$_}" } sort keys %bad);

done_testing;
