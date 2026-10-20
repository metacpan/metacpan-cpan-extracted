#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
use Encode ();

use Time::Keeper;

# The C ABI: the table has a stable address and version, and the self-test
# calls every entry through that address, as another extension would, with
# every answer checked. The value it makes is one Perl can use.

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $p = Time::Keeper::_abi_ptr();
ok($p, '_abi_ptr gives an address');
is($p, Time::Keeper::_abi_ptr(), 'the same one every call');
like($p, qr/^\d+$/, 'as an unsigned integer');
is(Time::Keeper::_abi_version(), 3, 'the table is version 3');

my ($step, $t) = Time::Keeper::_abi_selftest($p);
is($step, 0, 'every entry answered as the header says')
    or diag("check $step in include/tk/tk_abi_selftest.h failed");
SKIP: {
    skip 'the self-test did not finish', 6 if $step;
    isa_ok($t, 'Time::Keeper', 'the value C made');
    is($t->rfc9557, '2025-10-09T17:53:20.250+09:00[Asia/Tokyo]', 'with the instant and zone C gave it');
    is($t->locale, 'fr', 'and the locale');
    is($t->format_date('full'), 'jeudi 9 octobre 2025', 'and Perl can use it');
    is($t->plus(days => 1)->day, 10, 'as any value');
    is(Time::Keeper->compare($t, Time::Keeper->from_epoch('1760000000.25')), 0, 'the same instant as Perl makes');
}
for (1 .. 200) { my ($s) = Time::Keeper::_abi_selftest($p); }
is((Time::Keeper::_abi_selftest($p))[0], 0, 'and again after two hundred runs');
{
    local $@ = 'left alone';
    Time::Keeper::_abi_selftest($p);
    is($@, 'left alone', 'parse through the table leaves $@ as it was');
}

# Version 3: each entry against the method of its name, on random values in
# five zones, four locales and three calendars, as another extension calls
# it. A result is the same instant; a failure is the same reason.
{
    my $K = 'Time::Keeper';
    srand(20261019);
    my @zones = ('UTC', 'Europe/London', 'America/New_York', 'Asia/Kolkata', 'Australia/Lord_Howe');
    my @locales = qw(en-GB en-US ar-EG fr);
    my @cals = qw(gregory hebrew islamic-umalqura);
    my @units = qw(year quarter month week day hour minute second millisecond microsecond nanosecond);
    my $reason = sub { my $e = shift; return undef unless defined $e; $e =~ s/^\S+->\S+: //; $e =~ s/ at \S+ line \d+\.?\n?\z//; $e };
    my $same = sub {
        my ($what, $code, $made, $err, $perl) = @_;
        my $got = eval { $perl->() };
        my $want_err = $reason->($@);
        if (defined $got) {
            return "$what: the table failed ($code, " . ($err // '') . "), the method gave $got" unless $code == 0 && $made;
            return "$what: the table gave $made, the method $got" unless $made->epoch_string eq $got->epoch_string && "$made" eq "$got";
            return '';
        }
        return "$what: the table gave $made, the method died: $want_err" if $code == 0;
        return "$what: the table's reason '" . ($err // '') . "', the method's '$want_err'" unless defined $err && $err eq $want_err;
        return '';
    };
    my (@bad, %asks);
    for my $i (1 .. 1000) {
        my $v = $K->from_epoch(int(rand(6e9)) - 2e9 + int(rand(1e9)) / 1e9, zone => $zones[$i % 5], locale => $locales[$i % 4]);
        $v = $v->in_calendar($cals[$i % 3]) if $i % 3;
        my $u = int rand 11;
        my $ws = int rand 8;
        my %plus = (years => int(rand(7)) - 3, months => int(rand(27)) - 13, days => int(rand(61)) - 30,
                    hours => int(rand(49)) - 24, minutes => int(rand(121)) - 60, seconds => int(rand(121)) - 60,
                    nanoseconds => int(rand(2e9)) - 1e9);
        delete $plus{$_} for grep { rand() < 0.4 } keys %plus;
        my @p = map { $plus{$_} // 0 } qw(years months weeks days hours minutes seconds nanoseconds);
        push @bad, $same->("plus @{[ %plus ]} on $v", Time::Keeper::_abi_v3('plus', $v, @p, 0, 1, 1),
                           sub { $v->plus(%plus, gap => 'forward', overlap => 'earlier') });
        push @bad, $same->("truncate $units[$u] $ws on $v", Time::Keeper::_abi_v3('truncate', $v, $u, $ws),
                           sub { $v->truncate(to => $units[$u], week_start => $ws || 'locale') });
        push @bad, $same->("end_of $units[$u] $ws on $v", Time::Keeper::_abi_v3('end_of', $v, $u, $ws),
                           sub { $v->end_of(to => $units[$u], week_start => $ws || 'locale') });
        my ($dow, $dir, $or_same) = (1 + int rand 7, rand() < 0.5 ? 1 : -1, int rand 2);
        push @bad, $same->("adjust $dow $dir $or_same on $v", Time::Keeper::_abi_v3('adjust_dow', $v, $dow, $dir, $or_same, 1, 1),
                           sub { my $m = $dir > 0 ? 'next' : 'previous'; $v->$m(day_of_week => $dow, or_same => $or_same, gap => 'forward') });
        my $n = (-1, 1 .. 5)[int rand 6];
        push @bad, $same->("nth $dow $n on $v", Time::Keeper::_abi_v3('nth_in_month', $v, $dow, $n, 1, 1),
                           sub { $v->nth_in_month(day_of_week => $dow, n => $n, gap => 'forward') });
        my ($h, $mi, $sec, $ns, $gap) = (int rand 24, int rand 60, int rand 60, int rand 1e9, int rand 3);
        push @bad, $same->("with $h:$mi:$sec gap $gap on $v", Time::Keeper::_abi_v3('with_time', $v, $h, $mi, $sec, $ns, $gap, 1),
                           sub { $v->with(hour => $h, minute => $mi, second => $sec, nanosecond => $ns,
                                          gap => (qw(croak forward backward))[$gap]) });
        $asks{$_}++ for qw(plus truncate end_of adjust_dow nth_in_month with_time);
    }
    @bad = grep { length } @bad;
    ok(!@bad, 'plus, truncate, end_of, adjust_dow, nth_in_month and with_time agree with their methods (' . join(', ', map { "$asks{$_} $_" } sort keys %asks) . ')')
        or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);

    my @texts;
    for my $i (1 .. 300) {
        my $loc = $locales[$i % 4];
        my $v = $K->from_epoch(int(rand(4e9)) - 1e9, zone => 'Europe/London', locale => $loc);
        for my $pat ('EEEE d MMMM y', 'd MMM y HH:mm', 'y-MM-dd', 'h:mm a', 'd MMMM y') {
            push @texts, [ $v->format($pat), $pat, $loc ];
        }
        push @texts, [ 'xyz', 'd MMMM y', $loc ], [ $v->plus(days => 1)->format('EEEE') . ' ' . $v->format('d MMMM y'), 'EEEE d MMMM y', $loc ];
    }
    @bad = ();
    for my $t (@texts) {
        my ($text, $pat, $loc) = @$t;
        push @bad, $same->("parse_cldr '$text' '$pat' $loc",
                           Time::Keeper::_abi_v3('parse_cldr', $text, $pat, 0, 'Europe/London', $loc, 'gregory', 1, 1),
                           sub { $K->parse_cldr($text, $pat, locale => $loc, zone => 'Europe/London', gap => 'forward') });
    }
    @bad = grep { length } @bad;
    ok(!@bad, 'parse_cldr agrees with the method on ' . scalar(@texts) . ' texts, the misses and the wrong weekdays among them')
        or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);

    my @r = Time::Keeper::_abi_v3('parse_cldr', '3:30 PM', 'h:mm a', 2, undef, 'en', 'gregory', 1, 1);
    is_deeply([ @r[0, 1] ], [ 0, '1970-01-01 15:30:00.000000000' ], 'parse_cldr of a time of day gives its clock');
    @r = Time::Keeper::_abi_v3('parse_cldr', '15 October 2026', 'd MMMM y', 1, undef, 'en', 'gregory', 1, 1);
    is_deeply([ @r[0, 1] ], [ 0, '2026-10-15 00:00:00.000000000' ], 'and of a date its day');
    @r = Time::Keeper::_abi_v3('parse_cldr', '4 Heshvan 5787', 'd MMMM y', 0, 'UTC', 'en', 'hebrew', 1, 1);
    is("$r[1]", '2026-10-15T00:00:00Z', 'and of a Hebrew date, read in its calendar');
    @r = Time::Keeper::_abi_v3('duration', 1, 2, 1, 3, 1, 30, 5, 7, 2);
    is("$r[1]", '' . Time::Keeper::Duration->new(years => 1, months => 2, weeks => 1, days => 3, hours => 1, minutes => 30,
                                                  seconds => 5, nanoseconds => 7, end_of_month => 'limit'), 'new_duration_sv as Duration->new');
    @r = Time::Keeper::_abi_v3('duration_from_sv', $r[1]);
    is($r[1], '14 10 90 5 7 2', 'and duration_from_sv reads its parts back');
    is((Time::Keeper::_abi_v3('duration', 1e17, 0, 0, 0, 0, 0, 0, 0, 0))[0], -3, 'a duration out of range is refused, as Duration->new refuses it');
    is((Time::Keeper::_abi_v3('locale_code', Time::Keeper::Locale::_id('fr_ca') // 0))[1] // '', 'fr-CA', 'locale_code gives the canonical code')
        if Time::Keeper::Locale->can('_id');
    is((Time::Keeper::_abi_v3('locale_code', 0))[1], 'en', 'locale_code of id 0 is en');
    is((Time::Keeper::_abi_v3('locale_code', -1))[0], -1, 'and a bad id is refused');
    is((Time::Keeper::_abi_v3('truncate', $K->now, 11, 0))[0], -1, 'a unit that is not one is refused');

    @bad = ();
    my %class = (1 => 'Time::Keeper::Date', 3 => 'Time::Keeper::YearMonth', 4 => 'Time::Keeper::MonthDay');
    for my $i (1 .. 600) {
        my $days = $i % 50 ? int(rand(2e6)) - 1e6 : int(rand(2e11)) - 1e11;
        my $loc = $locales[$i % 4];
        my $kind = (1, 3, 4)[$i % 3];
        my $d = Time::Keeper::Date->from_epoch_days($days, locale => $loc);
        my $want = $kind == 1 ? $d
                 : $kind == 3 ? Time::Keeper::YearMonth->new(year => $d->year, month => $d->month, locale => $loc)
                 :              Time::Keeper::MonthDay->new(month => $d->month, day => $d->day, locale => $loc);
        my @m = Time::Keeper::_abi_v3('new_date_sv', $kind, $days, $loc);
        push @bad, "new_date_sv $kind $days $loc: " . ($m[1] // 'undef') . ", the method $want"
            unless $m[0] == 0 && ref $m[1] eq $class{$kind} && "$m[1]" eq "$want" && $m[1]->locale eq $want->locale;
        my $first = $kind == 1 ? $days : $kind == 3 ? $days - $d->day + 1
                  : Time::Keeper::Date->new(year => 1972, month => $d->month, day => $d->day)->epoch_days;
        my @r = Time::Keeper::_abi_v3('date_from_sv', $want);
        push @bad, "date_from_sv $want: " . ($r[1] // 'undef') . ", wanted $kind $first $loc"
            unless $r[0] == 0 && $r[1] eq "$kind $first " . $want->locale;
    }
    ok(!@bad, 'new_date_sv and date_from_sv agree with Date, YearMonth and MonthDay on 600 days')
        or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
    {
        package My::Date;
        our @ISA = ('Time::Keeper::Date');
    }
    @r = Time::Keeper::_abi_v3('new_date_sv', 1, 20745, 'en-GB', 'My::Date');
    is(ref $r[1], 'My::Date', 'new_date_sv blesses into the stash it is given');
    is((Time::Keeper::_abi_v3('date_from_sv', $r[1]))[1], '1 20745 en-GB', 'and date_from_sv reads a subclass');
    is((Time::Keeper::_abi_v3('date_from_sv', $K->now))[0], -1, 'date_from_sv refuses a Time::Keeper value');
    is((Time::Keeper::_abi_v3('date_from_sv', Time::Keeper::Time->new(hour => 9)))[0], -1, 'and a time of day');
    is((Time::Keeper::_abi_v3('date_from_sv', 'Time::Keeper::Date'))[0], -1, 'and a class name');
    is((Time::Keeper::_abi_v3('new_date_sv', 2, 0, 'en'))[0], -1, 'new_date_sv refuses a time of day');
    is((Time::Keeper::_abi_v3('new_date_sv', 1, 1e15, 'en'))[0], -1, 'and a day out of range');
    is((Time::Keeper::_abi_v3('new_date_sv', 1, 0, 'xx-nowhere'))[0], -1, 'and a locale that is not one');

    @bad = ();
    my @codes = Time::Keeper::Locale->codes;
    for my $c (@codes) {
        my $want = Time::Keeper::Locale->weekend_start($c) . ' ' . Time::Keeper::Locale->weekend_end($c);
        my @w = Time::Keeper::_abi_v3('locale_weekend', $c);
        push @bad, "locale_weekend $c: " . ($w[1] // $w[2] // 'undef') . ", the methods $want" unless $w[0] == 0 && $w[1] eq $want;
    }
    ok(@codes > 100 && !@bad, 'locale_weekend agrees with weekend_start and weekend_end in all ' . scalar(@codes) . ' locales')
        or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
    is((Time::Keeper::_abi_v3('locale_weekend', 'ar-EG'))[1], '5 6', 'Friday and Saturday in Egypt');
    is((Time::Keeper::_abi_v3('locale_weekend', 'xx-nowhere'))[0], -1, 'and a locale that is not one is refused');

    @bad = ();
    my $n = 0;
    for my $i (1 .. 1000) {
        my $v = $K->from_epoch(int(rand(6e9)) - 2e9 + int(rand(1e9)) / 1e9, zone => $zones[$i % 5], locale => $locales[$i % 4]);
        $v = $v->in_calendar($cals[$i % 3]) if $i % 3;
        my $want = $v->next_transition;
        my @c = Time::Keeper::_abi_v3('next_change', $v);
        if (!defined $want) {
            push @bad, "next_change on $v: $c[0], the method none" unless $c[0] == -3;
            next;
        }
        $n++;
        my $sides = $want->plus(seconds => -1)->offset . ' ' . $want->offset;
        push @bad, "next_change on $v: " . ($c[1] // $c[0]) . " ($c[2]), the method $want ($sides)"
            unless $c[0] == 0 && "$c[1]" eq "$want" && $c[1]->epoch_string eq $want->epoch_string && $c[2] eq $sides;
    }
    ok($n > 300 && !@bad, "next_change agrees with next_transition on 1000 values, $n with a change ahead")
        or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
    for my $z ('UTC', '+05:30', 'floating') {
        is((Time::Keeper::_abi_v3('next_change', $K->now->in_zone($z)))[0], -3, "next_change finds none in $z");
    }
    local $@ = 'left alone';
    Time::Keeper::_abi_v3('with_time', $K->new(year => 2027, month => 3, day => 28, zone => 'Europe/London'), 1, 30, 0, 0, 0, 1);
    Time::Keeper::_abi_v3('parse_cldr', 'Tuesday 15 October 2026', 'EEEE d MMMM y', 0, 'UTC', 'en', 'gregory', 1, 1);
    is($@, 'left alone', 'an entry that fails leaves $@ as it was');
}

# A failure's reason is cut short to the caller's buffer, at a character's
# start, as the table promises; 0.07 died with my_snprintf's panic instead.
{
    my $long = "\x{11103}" x 200;
    my @r = eval { Time::Keeper::_abi_v3('parse_cldr', "15 $long", 'd MMMM y', 0, 'UTC', 'en', 'gregory', 1, 1) };
    is($r[0], -4, 'a long text that does not parse fails, and does not panic') or diag($@);
    ok(defined $r[2] && length($r[2]) < 256, 'its reason fits the 256-byte buffer');
    my $why = eval { Encode::decode('UTF-8', $r[2] // '', Encode::FB_CROAK()) };
    like($why // 'not UTF-8', qr/^cannot parse '15 \x{11103}+\z/, 'cut short, at whole characters');
}

done_testing;
