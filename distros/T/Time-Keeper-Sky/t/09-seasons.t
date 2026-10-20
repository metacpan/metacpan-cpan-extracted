#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;

# The equinoxes and solstices: example 27.a, the book's VSOP87 table of 1996
# to 2005 (sources/meeus-27-terms.tsv), and USNO's seasons for 34 years
# (t/usno-seasons.tsv).

sub utc { Time::Keeper->new(@_, zone => 'UTC') }
sub near { my ($got, $want, $tol, $name) = @_; cmp_ok(abs($got - $want), '<=', $tol, "$name: $got within $tol of $want") }

near(Time::Keeper::Sun::_season_jde(1962, 1), 2437837.39245, 1e-5, 'example 27.a: the June solstice of 1962, JDE');
{
    my $s = Time::Keeper::Sun->solstice(year => 1962, month => 'june');
    isa_ok($s, 'Time::Keeper');
    # 21:25:08 TD less the 1962 polynomial's Delta T (about 34 s)
    near($s->epoch, utc(year => 1962, month => 6, day => 21, hour => 21, minute => 25, second => 8)->epoch - 34, 3, 'and in UT through Delta T');
    is($s->zone_name, 'UTC', 'UTC unless told');
    is($s->nanosecond, 0, 'to the second');
}

# the book's VSOP87 table, 1996 to 2005, in TD, within a minute (the book says 51 s at most)
{
    my %book = (
        0 => [[1996, 20, 8, 4, 7], [1997, 20, 13, 55, 42], [1998, 20, 19, 55, 35], [1999, 21, 1, 46, 53], [2000, 20, 7, 36, 19],
              [2001, 20, 13, 31, 47], [2002, 20, 19, 17, 13], [2003, 21, 1, 0, 50], [2004, 20, 6, 49, 42], [2005, 20, 12, 34, 29]],
        1 => [[1996, 21, 2, 24, 46], [1997, 21, 8, 20, 59], [1998, 21, 14, 3, 38], [1999, 21, 19, 50, 11], [2000, 21, 1, 48, 46],
              [2001, 21, 7, 38, 48], [2002, 21, 13, 25, 29], [2003, 21, 19, 11, 32], [2004, 21, 0, 57, 57], [2005, 21, 6, 47, 12]],
        2 => [[1996, 22, 18, 1, 8], [1997, 22, 23, 56, 49], [1998, 23, 5, 38, 15], [1999, 23, 11, 32, 34], [2000, 22, 17, 28, 40],
              [2001, 22, 23, 5, 32], [2002, 23, 4, 56, 28], [2003, 23, 10, 47, 53], [2004, 22, 16, 30, 54], [2005, 22, 22, 24, 14]],
        3 => [[1996, 21, 14, 6, 56], [1997, 21, 20, 8, 5], [1998, 22, 1, 57, 31], [1999, 22, 7, 44, 52], [2000, 21, 13, 38, 30],
              [2001, 21, 19, 22, 34], [2002, 22, 1, 15, 26], [2003, 22, 7, 4, 53], [2004, 21, 12, 42, 40], [2005, 21, 18, 36, 1]],
    );
    my %month = (0 => 3, 1 => 6, 2 => 9, 3 => 12);
    my $worst = 0;
    for my $which (0 .. 3) {
        for my $row (@{$book{$which}}) {
            my ($y, $d, $h, $m, $s) = @$row;
            my $td = Time::Keeper::Sun::_jd(utc(year => $y, month => $month{$which}, day => $d, hour => $h, minute => $m, second => $s));
            my $diff = abs(Time::Keeper::Sun::_season_jde($y, $which) - $td) * 86400;
            $worst = $diff if $diff > $worst;
            cmp_ok($diff, '<=', 60, "the book's table: $y season $which within a minute (" . sprintf('%.0f', $diff) . ' s)');
        }
    }
    note("worst against the book's VSOP87 table: " . sprintf('%.1f', $worst) . ' s');
}

# the shape
{
    my @s = Time::Keeper::Sun->seasons(year => 2026);
    is(scalar @s, 4, 'four seasons');
    like("$s[0]", qr/^2026-03-20T14:4[5-7]:\d\dZ$/, 'the March equinox 2026 at 14:46 (USNO)');
    like("$s[1]", qr/^2026-06-21T08:2[3-5]:\d\dZ$/, 'the June solstice at 08:24');
    like("$s[2]", qr/^2026-09-23T00:0[4-6]:\d\dZ$/, 'the September equinox at 00:05');
    like("$s[3]", qr/^2026-12-21T20:4[9]|^2026-12-21T20:5[01]/, 'the December solstice at 20:50');
    ok($s[0] < $s[1] && $s[1] < $s[2] && $s[2] < $s[3], 'in order');
    for my $i (1 .. 3) {
        my $days = ($s[$i]->epoch - $s[$i - 1]->epoch) / 86400;
        ok($days > 89 && $days < 94, "about $days days apart");
    }
    is("${\ Time::Keeper::Sun->equinox(year => 2026, month => 'march') }", "$s[0]", 'equinox march is the first');
    is("${\ Time::Keeper::Sun->solstice(year => 2026, month => 'june') }", "$s[1]", 'solstice june the second');
    is("${\ Time::Keeper::Sun->equinox(year => 2026, month => 'september') }", "$s[2]", 'equinox september the third');
    is("${\ Time::Keeper::Sun->solstice(year => 2026, month => 'december') }", "$s[3]", 'solstice december the fourth');
    my $tokyo = Time::Keeper::Sun->solstice(year => 2026, month => 'june', zone => 'Asia/Tokyo', locale => 'ja');
    is($tokyo->epoch, $s[1]->epoch, 'the same instant in Tokyo');
    is($tokyo->zone_name, 'Asia/Tokyo', 'in that zone');
    is($tokyo->locale, 'ja', 'and locale');
    is((Time::Keeper::Sun->seasons(year => 2026, zone => 'Asia/Tokyo'))[1]->zone_name, 'Asia/Tokyo', 'seasons too');
}

# deaths
for my $bad (
    [['equinox', year => 2026, month => 'june'], qr/there is no equinox in june; solstice takes it/],
    [['solstice', year => 2026, month => 'march'], qr/there is no solstice in march; equinox takes it/],
    [['equinox', year => 2026, month => 'spring'], qr/no season turns in 'spring' \(march, june, september or december\)/],
    [['equinox', year => 2026], qr/needs month => march or september/],
    [['solstice', year => 2026], qr/needs month => june or december/],
    [['equinox', month => 'march'], qr/needs year/],
    [['equinox', year => 'next', month => 'march'], qr/year must be a number/],
    [['equinox', year => 3001, month => 'march'], qr/the year 3001 is outside the years Time::Keeper::Sun computes \(-1999 to 3000\)/],
    [['solstice', year => -2000, month => 'june'], qr/the year -2000 is outside/],
    [['equinox', year => 2026, month => 'march', colour => 'red'], qr/unknown argument 'colour'/],
    [['equinox', year => 2026, month => 'march', zone => 'floating'], qr/the floating zone has no day/],
    [['seasons'], qr/needs year/],
    [['seasons', year => 3001], qr/the year 3001 is outside/],
    [['seasons', 2026], qr/takes name and value pairs/],
) {
    my ($args, $re) = @$bad;
    my $method = shift @$args;
    ok(!eval { Time::Keeper::Sun->$method(@$args); 1 }, "$method(@$args) dies");
    like($@, $re, 'by name');
}
ok(Time::Keeper::Sun->seasons(year => 3000), 'the year 3000 computes');
ok(Time::Keeper::Sun->seasons(year => -1999), 'and -1999, by extrapolation');
{
    my @s = Time::Keeper::Sun->seasons(year => 500);
    is($s[0]->year, 500, 'the year 500 uses the first table');
    my @u = Time::Keeper::Sun->seasons(year => 1000);
    is($u[0]->year, 1000, 'and 1000 the second');
    ok(Time::Keeper::Sun->solstice(year => 999, month => 'december')->epoch < $u[0]->epoch, 'the tables join in order');
}

# ---- USNO's seasons -----------------------------------------------------------------

{
    my $file = -e 't/usno-seasons.tsv' ? 't/usno-seasons.tsv' : 'usno-seasons.tsv';
    open my $fh, '<', $file or BAIL_OUT("$file: $!");
    my %which = ('Equinox' => { 3 => 0, 9 => 2 }, 'Solstice' => { 6 => 1, 12 => 3 });
    my ($n, $worst, $worst_name) = (0, 0, '');
    while (<$fh>) {
        next if /^#/;
        chomp;
        my ($y, $m, $d, $time, $phenom) = split /\t/;
        next unless defined $phenom;
        my ($h, $mi) = split /:/, $time;
        my $w = $which{$phenom}{$m};
        my $usno = utc(year => $y, month => $m, day => $d, hour => $h, minute => $mi)->epoch;
        my $ours = (Time::Keeper::Sun->seasons(year => $y))[$w];
        my $minutes = int(($ours->epoch - $ours->epoch % 60) / 60) - int($usno / 60);
        cmp_ok(abs($minutes), '<=', 1, "$y $phenom " . $ours->strftime('%m-%d %H:%M:%S') . " is USNO's minute ($time) or an adjacent one");
        my $diff = abs($ours->epoch - $usno);
        ($worst, $worst_name) = ($diff, "$y $phenom") if $diff > $worst;
        $n++;
    }
    close $fh;
    cmp_ok($n, '>=', 130, "$n seasons against USNO");
    note("the largest difference from USNO's minute was $worst s ($worst_name)");
}

done_testing;
