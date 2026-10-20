#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sun;

# Author test, network: random (place, date) pairs against USNO's one-day
# API, the responses cached in a directory keyed by the URL. Set
# TKS_USNO_SWEEP to the cache directory to run it, and TKS_USNO_ROWS to the
# number of pairs (500). Each ask waits half a second.

my $dir = $ENV{TKS_USNO_SWEEP} or plan skip_all => 'set TKS_USNO_SWEEP to a cache directory to sweep USNO';
my $rows = $ENV{TKS_USNO_ROWS} || 500;
mkdir $dir unless -d $dir;
srand(20261018);

my @places = (
    [51.5074, -0.1278, 'Europe/London'], [71.2906, -156.7886, 'America/Anchorage'], [78.2232, 15.6267, 'Arctic/Longyearbyen'],
    [69.6492, 18.9553, 'Europe/Oslo'], [-77.8419, 166.6863, 'Antarctica/McMurdo'], [-0.1807, -78.4678, 'America/Guayaquil'],
    [1.8721, -157.4278, 'Pacific/Kiritimati'], [-33.4489, -70.6693, 'America/Santiago'], [-31.5553, 159.0821, 'Australia/Lord_Howe'],
    [-33.8688, 151.2093, 'Australia/Sydney'], [64.1466, -21.9426, 'Atlantic/Reykjavik'], [39.4704, 75.9898, 'Asia/Shanghai'],
    [61.2181, -149.9003, 'America/Anchorage'], [21.3069, -157.8583, 'Pacific/Honolulu'], [35.6762, 139.6503, 'Asia/Tokyo'],
    [-34.6037, -58.3816, 'America/Argentina/Buenos_Aires'], [55.7558, 37.6173, 'Europe/Moscow'], [28.6139, 77.2090, 'Asia/Kolkata'],
    [-22.9068, -43.1729, 'America/Sao_Paulo'], [30.0444, 31.2357, 'Africa/Cairo'],
);
my %kind = ('Rise' => 'sunrises', 'Set' => 'sunsets', 'Upper Transit' => 'solar_noons', 'Lower Transit' => 'solar_midnights',
            'Begin Civil Twilight' => 'dawns', 'End Civil Twilight' => 'dusks');
my ($compared, $worst, @misses) = (0, 0);
for my $n (1 .. $rows) {
    my ($lat, $lon, $zone) = @{$places[int rand @places]};
    my $y = 1900 + int rand 200;
    my $date = Time::Keeper::Date->from_epoch_days(Time::Keeper::Date->new(year => $y, month => 1, day => 1)->epoch_days + int rand 365);
    my $sun = Time::Keeper::Sun->new(latitude => $lat, longitude => $lon, zone => $zone);
    my $day = $sun->on($date);
    my $tz = Time::Keeper->new(year => $date->year, month => $date->month, day => $date->day, hour => 12, zone => $zone)->offset / 3600;
    next if $tz * 4 != int($tz * 4);
    my $url = "https://aa.usno.navy.mil/api/rstt/oneday?date=$date&coords=$lat,$lon&tz=$tz";
    (my $key = $url) =~ s/[^A-Za-z0-9.-]/_/g;
    my $json;
    if (-e "$dir/$key") {
        open my $fh, '<', "$dir/$key" or die;
        local $/;
        $json = <$fh>;
    }
    else {
        $json = `curl -sS --max-time 40 "$url"`;
        select undef, undef, undef, 0.5;
        next unless $json =~ /"sundata"/;
        open my $fh, '>', "$dir/$key" or die;
        print $fh $json;
    }
    my ($sun_data) = $json =~ /"sundata":\s*\[(.*?)\]/s;
    my %theirs;
    while ($sun_data =~ /\{([^}]*)\}/g) {
        my $o = $1;
        my ($ph) = $o =~ /"phen":\s*"([^"]*)"/;
        my ($tm) = $o =~ /"time":\s*"([^"]*)"/;
        next unless defined $ph && defined $tm && length $tm;
        my ($h, $mi) = split /:/, $tm;
        push @{$theirs{$ph}}, Time::Keeper->new(year => $date->year, month => $date->month, day => $date->day, hour => $h, minute => $mi, zone => 'UTC')->epoch - $tz * 3600;
    }
    for my $phen (sort keys %kind) {
        my $method = $kind{$phen};
        my @ours = $day->$method;
        my @usno = @{$theirs{$phen} || []};
        next if !@usno && $phen =~ /Transit/;
        if (@ours != @usno) {
            push @misses, "$zone $date $phen: " . scalar(@ours) . " here, " . scalar(@usno) . " at USNO";
            next;
        }
        for my $i (0 .. $#usno) {
            my $diff = abs($ours[$i]->epoch - $usno[$i]);
            $worst = $diff if $diff > $worst;
            push @misses, "$zone $date $phen: $diff s" if $diff > 60;
            $compared++;
        }
    }
}
cmp_ok($compared, '>', 0, "$compared events compared");
is(scalar @misses, 0, 'every event within a minute of USNO and every count the same') or diag(join "\n", @misses);
diag("worst $worst s over $compared events");
done_testing;
