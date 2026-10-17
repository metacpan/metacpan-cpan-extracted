#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Formatting against DateTime. Author only. Every strftime conversion, and
# every CLDR field where Time::Keeper follows DateTime; the fields where it
# follows the CLDR standard instead (YY, c, e, g, ZZZZ, ZZZZZ, X, x, O, the
# zone names, and weeks as the locale counts them, see the POD) are not
# compared. Weeks are compared in German, whose weeks are ISO 8601's, as
# DateTime counts them in every locale. DateTime's locale data is
# CLDR 47 and Time::Keeper's 48; English did not change between them for
# these.
BEGIN {
    eval { require DateTime; 1 } or plan skip_all => 'DateTime is not installed';
}
use Time::Keeper;
use Time::Keeper::Zone;

my $y2026 = 1767225600;
my %changed_from = (
    (map { $_ => $y2026 } qw(America/Winnipeg America/Inuvik America/Edmonton
                             America/Vancouver Africa/Casablanca Africa/El_Aaiun)),
    'Europe/Chisinau' => 1640995200,
);
my %skip = map { $_ => 1 } qw(EST5EDT CST6CDT MST7MDT PST8PDT);
my @zones = grep { !/^Etc\// && !$skip{$_} } Time::Keeper::Zone->names;

my $strf = join '|', map { "%$_" }
    qw(a A b B c C d D e F g G h H I j k l m M n N 3N 6N p P r R s S t T u U V w W x X y Y z Z %),
    '{day_name}';
my @cldr = qw(G GGGG y yy yyyy u Q QQ QQQ QQQQ q qqq qqqq M MM MMM MMMM MMMMM L LLL LLLL LLLLL
              d dd D DDD F E EEE EEEE EEEEE ccc cccc ccccc eee eeee a h hh H HH K KK k kk
              m mm s ss S SSS SSSSSS Z ZZZ);

srand(808);
my (%bad, $n);
for (1 .. 10_000) {
    my $zone = $zones[int rand @zones];
    my $s = int(rand(4_000_000_000)) - 1_000_000_000;    # 1938 to 2096
    next if $changed_from{$zone} && $s >= $changed_from{$zone};
    my $ns = int(rand(1e9));
    my $t = Time::Keeper->from_epoch($s, zone => $zone)->plus(nanoseconds => $ns);
    my $dt = DateTime->from_epoch(epoch => $s, time_zone => $zone)->set_nanosecond($ns);
    $n++;
    my ($mine, $theirs) = ($t->strftime($strf), $dt->strftime($strf));
    $bad{strftime} //= "$zone $s: here '$mine', DateTime '$theirs'" if $mine ne $theirs;
    for my $f (qw(w ww W Y YYYY)) {
        my ($m, $d) = ($t->in_locale('de')->format($f), $dt->format_cldr($f));
        $bad{"cldr $f in German"} //= "$zone $s: here '$m', DateTime '$d'" if $m ne $d;
    }
    for my $f (@cldr) {
        my ($m, $d) = ($t->format($f), $dt->format_cldr($f));
        next if $m eq $d;
        $bad{"cldr $f"} //= "$zone $s: here '$m', DateTime '$d'";
    }
    # DateTime's own A comes from local_rd_secs, which after set_nanosecond
    # on the local day after a UTC day with a leap second, in a zone ahead
    # of UTC, is a second out from its own hour, minute and second
    # (Pacific/Noumea, 1990-01-01T21:15:49.141: A 76550141, the fields
    # 76549141). A is compared with what DateTime's fields give.
    {
        my $want = (($dt->hour * 60 + $dt->minute) * 60 + $dt->second) * 1000 + $dt->millisecond;
        my $got = $t->format('A');
        $bad{'cldr A'} //= "$zone $s: here '$got', DateTime's fields '$want'" if $got ne $want;
    }
    for my $m (qw(ymd mdy dmy hms month_name month_abbr day_name day_abbr era_name era_abbr quarter_name quarter_abbr)) {
        my ($a, $b) = ($t->$m, $dt->$m);
        $bad{$m} //= "$zone $s: here '$a', DateTime '$b'" if $a ne $b;
    }
    for my $len (qw(full long medium short)) {
        my ($a, $b) = ($t->format_date($len), $dt->format_cldr($dt->locale->${\ "date_format_$len"}));
        $bad{"date $len"} //= "$zone $s: here '$a', DateTime '$b'" if $a ne $b;
    }
}
is(scalar keys %bad, 0, "$n random values format as DateTime formats them")
    or diag(join "\n", map { "$_: $bad{$_}" } sort keys %bad);

done_testing;
