#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

# Author test: PARITY.md, read and checked. Every method of the modules it
# covers has one row; every method a Time::Keeper column calls exists; every
# test file a row names exists; every reason a row gives for not providing a
# method has been accepted by the owner; and every row marked oracle gives
# what the module it replaces gives, on random values.
#
#   TK_PARITY_N=n   values per oracle row (2,000)

BEGIN {
    for my $m (qw(DateTime DateTime::Duration DateTime::TimeZone DateTime::Locale Time::Piece Time::Seconds Storable)) {
        eval "require $m; 1" or plan skip_all => "$m is not installed";
    }
}
use POSIX ();
use Scalar::Util qw(looks_like_number);
use Time::Keeper;
use Time::Keeper::Locale;
use Time::Keeper::Zone;

our ($dt, $dt2, $dt3, $t, $t2, $t3, $tp, $tp2, $ts, $s, $dd, $dd2, $d, $d2, $tz, $zone, $loc, $code);
our ($K, $D, $L, $Z) = ('Time::Keeper', 'Time::Keeper::Duration', 'Time::Keeper::Locale', 'Time::Keeper::Zone');
sub P { my ($x) = @_; join ',', $x->in_units(qw(months days minutes seconds nanoseconds)) }

my $dist = -e 'PARITY.md' ? '.' : die "run from the dist's top\n";
open my $fh, '<:encoding(UTF-8)', "$dist/PARITY.md" or die "PARITY.md: $!";
my @lines = <$fh>;
close $fh;

# ---- the rows ----------------------------------------------------------------

my (%rows, %reasons, $module);
for (@lines) {
    chomp;
    if (/^## (\S+) [\d.]+$/) { $module = $1; next }
    if (/^## /) { $module = undef; next }
    if (/^\| (N\d+) \| (.*) \|$/) { $reasons{$1} = $2; next }
    next unless $module && /^\| `([^`]*)` \|/;
    my @c = map { s/^\s+|\s+$//gr } split /(?<!\\)\|/, substr($_, 1, -1);
    die "PARITY.md: a row of $module has " . scalar(@c) . " columns: $_\n" unless @c == 5;
    my ($method, $theirs, $ours, $check, $note) = @c;
    $method =~ s/^`(.*)`$/$1/;
    s/^`(.*)`$/$1/ for $theirs, $ours;
    push @{ $rows{$module} }, { method => $method, theirs => $theirs, ours => $ours, check => $check, note => $note };
}

# ---- every method has one row ------------------------------------------------

SKIP: {
    my ($list) = glob "$dist/../plan_time_keeper/sources/methods-timepiece-*.txt";
    skip 'the method lists are not beside the dist', 1 unless $list && -f $list;
    open my $lh, '<', $list or die "$list: $!";
    my (%want, $m);
    while (<$lh>) {
        chomp;
        if (/^== (\S+) [\d.]+ \(\d+\)/) { $m = $1; next }
        next unless $m && length;
        $want{$m}{$_}++;
    }
    my @wrong;
    for my $mod (sort keys %want) {
        my %have;
        $have{ $_->{method} }++ for @{ $rows{$mod} // [] };
        push @wrong, "$mod: no row for $_" for grep { !$have{$_} } sort keys %{ $want{$mod} };
        push @wrong, "$mod: $_ has a row but is not in the list" for grep { !$want{$mod}{$_} } sort keys %have;
        push @wrong, "$mod: $_ has $have{$_} rows" for grep { $have{$_} > 1 } sort keys %have;
    }
    is(scalar @wrong, 0, 'every method of the lists has one row, and no other') or diag(join "\n", @wrong);
}

# ---- every check is one that can be checked ------------------------------------

{
    my @wrong;
    for my $mod (sort keys %rows) {
        for my $r (@{ $rows{$mod} }) {
            my $c = $r->{check};
            next if $c =~ /^oracle(?: utc| local)?$/ || $c =~ /^ruled K\d+$/ || $c =~ /^struck: \S/;
            if ($c =~ /^not provided \((N\d+)\)$/) {
                push @wrong, "$mod $r->{method}: $1 is not a reason given" unless $reasons{$1};
                next;
            }
            push @wrong, "$mod $r->{method}: '$c' is not a file" unless -f "$dist/$c";
        }
    }
    is(scalar @wrong, 0, 'every check names an oracle, a ruling, a reason, or a test file that exists')
        or diag(join "\n", @wrong);
}

{
    my @open = grep { $reasons{$_} !~ /Accepted by the owner/ } sort { substr($a, 1) <=> substr($b, 1) } keys %reasons;
    is(scalar @open, 0, 'every reason for not providing a method has been accepted by the owner')
        or diag("not yet accepted: @open");
}

# ---- every method our columns call exists ---------------------------------------

{
    my %class = (t => 'Time::Keeper', t2 => 'Time::Keeper', t3 => 'Time::Keeper',
                 d => 'Time::Keeper::Duration', d2 => 'Time::Keeper::Duration', s => 'Time::Keeper::Duration',
                 K => 'Time::Keeper', D => 'Time::Keeper::Duration', L => 'Time::Keeper::Locale',
                 Z => 'Time::Keeper::Zone');
    my ($calls, @wrong) = (0);
    for my $mod (sort keys %rows) {
        for my $r (grep { length $_->{ours} } @{ $rows{$mod} }) {
            my $sub = eval "sub { $r->{ours} }";
            push @wrong, "$mod $r->{method}: does not compile: $@" unless $sub;
            while ($r->{ours} =~ /\$(\w+)->(\w+)/g) {
                my ($var, $m) = ($1, $2);
                next unless $class{$var};
                $calls++;
                push @wrong, "$mod $r->{method}: $class{$var} has no $m" unless $class{$var}->can($m);
            }
        }
    }
    is(scalar @wrong, 0, "every Time::Keeper method a row calls exists ($calls calls)") or diag(join "\n", @wrong);
}

# ---- the oracle -----------------------------------------------------------------

my %changed_from = (
    (map { $_ => 1767225600 } qw(America/Winnipeg America/Inuvik America/Edmonton
                                 America/Vancouver Africa/Casablanca Africa/El_Aaiun)),
    'Europe/Chisinau' => 1640995200,
);
my %skip = map { $_ => 1 } qw(EST5EDT CST6CDT MST7MDT PST8PDT);
my @zones = grep { !m{^Etc/} && !$skip{$_} && !$changed_from{$_} && eval { DateTime::TimeZone->new(name => $_); 1 } } Time::Keeper::Zone->names;

sub same {
    my ($x, $y) = @_;
    $_ = !defined $_ ? '' : ref $_ eq 'ARRAY' ? join(',', map { $_ // '' } @$_) : "$_" for $x, $y;
    return 1 if $x eq $y;
    return 1 if ($x eq '' || $x eq '0') && ($y eq '' || $y eq '0');
    return looks_like_number($x) && looks_like_number($y) && abs($x - $y) <= 1e-6 * (abs($x) > 1 ? abs($x) : 1);
}

sub run {
    my ($code) = @_;
    my @r = eval { $code->() };
    return $@ ? "died: " . ($@ =~ s/ at .*//sr) : @r == 1 ? $r[0] : [@r];
}

sub instant {
    my ($in) = @_;
    for (;;) {
        my $z = $in // $zones[int rand @zones];
        my $e = int(rand(4_000_000_000)) - 1_000_000_000;
        next if $changed_from{$z} && $e >= $changed_from{$z};
        return ($e, int(rand(1e9)), $z);
    }
}

sub dt_and_t {
    my ($e, $ns, $z) = @_;
    my $x = DateTime->from_epoch(epoch => $e, time_zone => 'UTC', locale => 'en')->set_nanosecond($ns)->set_time_zone($z);
    my $y = $K->from_epoch($e)->plus(nanoseconds => $ns)->in_zone($z);
    return ($x, $y);
}

my $N = $ENV{TK_PARITY_N} // 2000;
srand(1111);
my (%bad, $runs, $rows_run);
($runs, $rows_run) = (0, 0);
for my $mod (sort keys %rows) {
    for my $r (grep { $_->{check} =~ /^oracle/ } @{ $rows{$mod} }) {
        my ($scope) = $r->{check} =~ /^oracle ?(\w*)/;
        my $theirs = eval "sub { $r->{theirs} }" or do { $bad{"$mod $r->{method}"} = "theirs: $@"; next };
        my $ours = eval "sub { $r->{ours} }" or do { $bad{"$mod $r->{method}"} = "ours: $@"; next };
        $rows_run++;
        my @codes = $mod =~ /Locale/ ? qw(en fr de ja es it) : (undef);
        my $n = $mod =~ /Locale/ ? 1 : $N;
        for my $c (@codes) {
            for (1 .. $n) {
                local $ENV{TZ} = $scope eq 'local' ? 'America/New_York' : $ENV{TZ};
                POSIX::tzset();
                my $zin = $scope eq 'utc' ? 'UTC' : $scope eq 'local' ? 'America/New_York' : undef;
                my @a = instant($zin);
                ($dt, $t) = dt_and_t(@a);
                ($dt2, $t2) = dt_and_t(instant($zin // $a[2]));
                ($dt3, $t3) = dt_and_t(instant($zin // $a[2]));
                ($zone, $tz) = ($a[2], $dt->time_zone);
                if ($mod eq 'Time::Piece') {
                    my $e2 = (instant($zin))[0];
                    ($tp, $tp2) = $scope eq 'local' ? (scalar Time::Piece::localtime($a[0]), scalar Time::Piece::localtime($e2))
                                                    : (scalar Time::Piece::gmtime($a[0]), scalar Time::Piece::gmtime($e2));
                    my $tzname = $scope eq 'local' ? 'America/New_York' : 'UTC';
                    ($t, $t2) = ($K->from_epoch($a[0], zone => $tzname), $K->from_epoch($e2, zone => $tzname));
                }
                my $secs = int rand 10_000_000;
                ($ts, $s) = (Time::Seconds->new($secs), $D->from_seconds($secs));
                my $sign = rand() < 0.5 ? -1 : 1;
                my @f = map { $sign * int rand $_ } 30, 400, 100_000, 100_000, 1_000_000_000;
                my @f2 = map { $sign * int rand $_ } 30, 400, 100_000, 100_000, 1_000_000_000;
                my @k = qw(months days minutes seconds nanoseconds);
                ($dd, $d) = (DateTime::Duration->new(map { $k[$_] => $f[$_] } 0 .. 4), $D->new(map { $k[$_] => $f[$_] } 0 .. 4));
                ($dd2, $d2) = (DateTime::Duration->new(map { $k[$_] => $f2[$_] } 0 .. 4), $D->new(map { $k[$_] => $f2[$_] } 0 .. 4));
                if (defined $c) {
                    $code = $c;
                    $loc = DateTime::Locale->load($c);
                }
                my ($x, $y) = (run($theirs), run($ours));
                $runs++;
                next if same($x, $y);
                $bad{"$mod $r->{method}"} //= "$a[2] $a[0]" . (defined $c ? " $c" : '') . ": theirs '"
                    . (ref $x ? join(',', @$x) : $x) . "', ours '" . (ref $y ? join(',', @$y) : $y) . "'";
            }
        }
    }
}
is(scalar keys %bad, 0, "every oracle row agrees ($rows_run rows, $runs runs)")
    or diag(join "\n", map { "$_: $bad{$_}" } sort keys %bad);

done_testing;
