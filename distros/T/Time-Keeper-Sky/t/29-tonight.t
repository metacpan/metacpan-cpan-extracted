#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sky;
use Time::Keeper::Star;

# Tonight against one-minute tracks, as plan_time_keeper_sky/09 set it:
# London, Sydney and Tromso on the 15th of every month of 2026. Each body
# listed has its best moment where a one-minute track of it over the night
# is highest (within a minute; the night tracked every two minutes, then
# every minute around its highest), is at or above the minimum then, and
# is above it for half an hour by the track; each body not listed (the
# moon, the seven planets, the stars brighter than the magnitude) is not,
# by the track, two minutes either way at each crossing. The night runs from civil dusk to civil dawn; polar day and white
# nights have none, and say so.

my @places = (['London', 'Europe/London'], ['Sydney', 'Australia/Sydney'], ['Tromso', 'Europe/Oslo', 69.6496, 18.9560]);
my @stars = Time::Keeper::Star->brighter_than(1.5);
my @all = ('moon', qw(mercury venus mars jupiter saturn uranus neptune), map { "HR $_" } @stars);

my %w = (best => 0, low => 0, short => 0, missed => 0, order => 0, edge => 0, under => 0, cross => 0);
my ($nights, $listed, $none) = (0, 0, 0);
my $where = '';
for my $pl (@places) {
    my ($name, $zone, $lat, $lon) = @$pl;
    my $sky = defined $lat ? Time::Keeper::Sky->new(latitude => $lat, longitude => $lon, zone => $zone) : Time::Keeper::Sky->new(place => $zone);
    for my $month (1 .. 12) {
        my $date = Time::Keeper->new(year => 2026, month => $month, day => 15, hour => 12, zone => $zone);
        my $n = $sky->night(date => $date);
        my @up = $sky->tonight(date => $date);
        if ($n->{kind} ne 'night' && $n->{kind} ne 'polar_night') {
            $none++;
            is(scalar @up, 0, "$name 2026-$month-15 is a $n->{kind}: nothing listed");
            ok(!defined $n->{start} && !defined $n->{end}, '  and the night has no start or end');
            next;
        }
        $nights++;
        my ($s, $e) = ($n->{start}->epoch, $n->{end}->epoch);
        my %seen;
        my $last = 0;
        for my $r (@up) {
            $listed++;
            my $key = $r->{kind} eq 'star' ? "HR $r->{hr}" : $r->{body};
            $seen{$key} = 1;
            $w{order}++ if $r->{best}->epoch < $last;
            $last = $r->{best}->epoch;
            # the night every two minutes, then every minute around its highest
            my $tr = $sky->track($key, from => $s, to => $e, step => 120);
            my ($alt, $ep) = @$tr{qw(altitude epoch)};
            my $k = 0;
            $alt->[$_] > $alt->[$k] and $k = $_ for 0 .. $#$alt;
            my ($lo, $hi) = ($ep->[$k] - 180, $ep->[$k] + 180);
            $lo = $s if $lo < $s;
            $hi = $e if $hi > $e;
            my $fine = $sky->track($key, from => $lo, to => $hi, step => 60);
            # and the night's ends, where a track's last step falls short
            my @f = map { [$fine->{epoch}[$_], $fine->{altitude}[$_]] } 0 .. $#{ $fine->{epoch} };
            push @f, map { [$_, $sky->position($key, $_)->{altitude}] } $s, $e;
            my ($top) = sort { $b->[1] <=> $a->[1] } @f;
            my $d = abs($r->{best}->epoch - $top->[0]);
            # found to the second, so no sample is higher than the best moment
            my $hb = $sky->position($key, $r->{best})->{altitude};
            $w{under}++, diag("$name 2026-$month $key: a sample is " . ($top->[1] - $hb) . " higher") if $top->[1] > $hb + 1e-4;
            # the crossings of the minimum, to the second
            for ([from => $s], [until => $e]) {
                my ($which, $end) = @$_;
                next if $r->{$which}->epoch == $end;
                my $h = $sky->position($key, $r->{$which})->{altitude};
                $w{cross} = abs($h - 10) if abs($h - 10) > $w{cross};
            }
            ($w{best}, $where) = ($d, "$name 2026-$month $key") if $d > $w{best};
            $w{low}++ if $r->{altitude} < 10;
            # two minutes of sampling either way at each of two crossings
            my $above = 2 * grep { $_ >= 10 } @$alt;
            $w{short}++ if $above < 30 - 4;
            $w{edge}++ if $r->{from}->epoch < $s || $r->{until}->epoch > $e || $r->{from}->epoch > $r->{until}->epoch;
        }
        for my $b (@all) {
            next if $seen{$b};
            my $tr = $sky->track($b, from => $s, to => $e, step => 120);
            my $above = 2 * grep { $_ >= 10 } @{ $tr->{altitude} };
            if ($above > 30 + 4) {
                $w{missed}++;
                diag("$name 2026-$month: $b is above 10 degrees for $above minutes and not listed");
            }
        }
    }
}
cmp_ok($nights, '>=', 30, "$nights nights with a dark span, $none without");
cmp_ok($listed, '>', 300, "$listed bodies listed");
cmp_ok($w{best}, '<=', 60, "each best moment within a minute of the one-minute track's highest (worst $w{best} s, $where)");
is($w{low}, 0, 'none listed below the minimum at its best');
is($w{short}, 0, 'none listed that the track has above it for under half an hour');
is($w{missed}, 0, 'none missed that the track has above it for over half an hour');
is($w{order}, 0, 'in order of the best moment');
is($w{under}, 0, 'no sample of the track higher than the best moment');
cmp_ok($w{cross}, '<', 0.01, "from and until where the altitude crosses the minimum (worst $w{cross} degrees)");
is($w{edge}, 0, 'from and until inside the night, in order');

# ---- the nights -------------------------------------------------------------------------

{
    my $tromso = Time::Keeper::Sky->new(latitude => 69.6496, longitude => 18.9560, zone => 'Europe/Oslo');
    my $june = Time::Keeper->new(year => 2026, month => 6, day => 21, hour => 12, zone => 'Europe/Oslo');
    is($tromso->night(date => $june)->{kind}, 'polar_day', 'Tromso at midsummer: polar day');
    is(scalar(my @x = $tromso->tonight(date => $june)), 0, '  nothing tonight');
    my $may = Time::Keeper->new(year => 2026, month => 5, day => 5, hour => 12, zone => 'Europe/Oslo');
    is($tromso->night(date => $may)->{kind}, 'white_night', 'Tromso on 5 May: the sun sets, it never gets dark: a white night');
    my $svalbard = Time::Keeper::Sky->new(latitude => 78.2232, longitude => 15.6267, zone => 'Arctic/Longyearbyen');
    my $dec = Time::Keeper->new(year => 2026, month => 12, day => 21, hour => 12, zone => 'Arctic/Longyearbyen');
    my $n = $svalbard->night(date => $dec);
    is($n->{kind}, 'polar_night', 'Longyearbyen at midwinter: polar night');
    is($n->{start} . '', '2026-12-21T12:00:00+01:00', '  the whole window: from the date\'s noon');
    is($n->{end} . '', '2026-12-22T12:00:00+01:00', '  to the next day\'s');
    my @up = $svalbard->tonight(date => $dec);
    ok(scalar(grep { $_->{body} eq 'Capella' } @up), '  Capella, circumpolar there, is listed');

    my $london = Time::Keeper::Sky->new(place => 'Europe/London');
    my $oct = Time::Keeper->new(year => 2026, month => 10, day => 19, hour => 12, zone => 'Europe/London');
    my $ln = $london->night(date => $oct);
    is($ln->{kind}, 'night', 'London on 19 October: a night');
    is($ln->{start}->epoch, $london->next_dusk($oct)->epoch, '  from civil dusk');
    is($ln->{end}->epoch, $london->next_dawn($ln->{start})->epoch, '  to the next civil dawn');
    is($ln->{date} . '', '2026-10-19', '  the date');
    is($london->night(date => $oct->to_date)->{start}->epoch, $ln->{start}->epoch, 'date => a Time::Keeper::Date');
    is($london->night(date => Time::Keeper->new(year => 2026, month => 10, day => 19, hour => 23, zone => 'Europe/London'))->{start}->epoch,
       $ln->{start}->epoch, 'date => a value is its date in the zone');
    like($ln->{start} . '', qr/\+01:00$/, 'values in the place\'s zone');
    {
        no warnings 'once';
        local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 20, hour => 2, zone => 'Europe/London');
        is($london->night->{date} . '', '2026-10-19', 'no date at 2 am on the 20th: the night now in, the 19th\'s');
        is(scalar(my @x = $london->tonight), scalar(my @y = $london->tonight(date => $oct)), '  tonight too');
        local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 20, hour => 13, zone => 'Europe/London');
        is($london->night->{date} . '', '2026-10-20', '  at 1 pm the coming one, the 20th\'s');
    }

    # ---- the rows ---------------------------------------------------------------------
    my @up2 = $london->tonight(date => $oct);
    my ($jup) = grep { $_->{body} eq 'jupiter' } @up2;
    ok($jup, 'Jupiter is up on the night of 19 October 2026 from London');
    is($jup->{kind}, 'planet', '  a planet');
    is($jup->{constellation}, 'Leo', '  in Leo');
    cmp_ok($jup->{magnitude}, '<', -1.5, '  bright (' . sprintf('%.2f', $jup->{magnitude}) . ')');
    ok($jup->{illumination} > 0.9 && $jup->{illumination} <= 1, '  nearly full');
    my $pos = $london->position('jupiter', $jup->{best});
    cmp_ok(abs($pos->{altitude} - $jup->{altitude}), '<', 0.001, '  the altitude is position\'s at the best moment');
    cmp_ok(abs($pos->{azimuth} - $jup->{azimuth}), '<', 0.001, '  and the azimuth');
    cmp_ok(abs($pos->{apparent_altitude} - $jup->{apparent_altitude}), '<', 0.001, '  and the apparent altitude');
    my ($moon) = grep { $_->{body} eq 'moon' } @up2;
    ok($moon && !defined $moon->{magnitude} && defined $moon->{illumination}, 'the moon has an illumination and no magnitude');
    my ($vega) = grep { $_->{body} eq 'Vega' } @up2;
    is($vega->{hr}, 7001, 'a star has its HR number');
    is($vega->{constellation}, 'Lyr', '  and its constellation');
    cmp_ok(abs($london->position('Vega', $vega->{best})->{altitude} - $vega->{altitude}), '<', 0.001, '  its altitude position\'s');
    is_deeply([sort keys %$vega], [sort qw(body kind best from until altitude apparent_altitude azimuth constellation magnitude hr)], 'a star\'s keys');
    is_deeply([sort keys %$jup], [sort qw(body kind best from until altitude apparent_altitude azimuth constellation magnitude illumination)], 'a planet\'s keys');

    my @high = $london->tonight(date => $oct, minimum_altitude => 40);
    ok(@high < @up2 && !grep({ $_->{altitude} < 40 } @high), 'minimum_altitude => 40 lists fewer, none below 40 at its best');
    my @bright = $london->tonight(date => $oct, magnitude => 0);
    ok(!grep({ $_->{kind} eq 'star' && $_->{magnitude} > 0 } @bright), 'magnitude => 0: no star fainter than 0');
    my @faint = $london->tonight(date => $oct, magnitude => 3);
    cmp_ok(scalar(grep { $_->{kind} eq 'star' } @faint), '>', 50, 'magnitude => 3: many more stars');
    is(scalar(grep { $_->{kind} ne 'star' } @faint), scalar(grep { $_->{kind} ne 'star' } @up2), '  and the same moon and planets');
}

# ---- refusals ---------------------------------------------------------------------------

{
    my $london = Time::Keeper::Sky->new(place => 'Europe/London');
    for ([[date => 'today'], qr/^tonight: date must be a Time::Keeper::Date or a Time::Keeper value/],
         [['date'], qr/^tonight takes name and value pairs/],
         [[minimum_altitude => 'high'], qr/^tonight: minimum_altitude must be a number/],
         [[minimum_altitude => 90], qr/^tonight: minimum_altitude must be from -1 to under 90 degrees/],
         [[magnitude => undef], qr/^tonight: magnitude must be a number/],
         [[colour => 1], qr/^tonight: unknown argument 'colour'/]) {
        my ($args, $re) = @$_;
        ok(!eval { $london->tonight(@$args); 1 }, "tonight(@{[ map { $_ // 'undef' } @$args ]}) dies");
        like($@, $re, '  with its message');
    }
    ok(!eval { $london->night(magnitude => 2); 1 }, 'night takes no magnitude');
    like($@, qr/^night: unknown argument 'magnitude'/, '  by name');
    ok(!eval { Time::Keeper::Sky::tonight('x'); 1 }, 'tonight on something else dies');
}

done_testing;
