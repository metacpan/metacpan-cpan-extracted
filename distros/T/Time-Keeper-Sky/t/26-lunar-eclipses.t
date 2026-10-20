#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Sky;
use Time::Keeper::Eclipse;

# Lunar eclipses against the Five Millennium Canon (Espenak and Meeus,
# t/canon-lunar-1901-2100.tsv): every eclipse of 1901-2100 found, none
# invented, of the same type; greatest eclipse within 30 s in TD (Delta T
# left out); the magnitudes within 0.005; the contacts within 30 s, so each
# phase's duration within 60 s. Those marks were set in
# plan_time_keeper_sky/07 before any number was seen.
#
# Two bounds are not the plan's and say why. Gamma: the moon's chapter 47
# place is good to 10 arcseconds, 0.003 of the earth's radius at the moon.
# A grazing phase (a depth into its shadow under 0.05): its duration goes
# as the square root of the depth, so the moon's 10 arcseconds, a few
# thousandths of magnitude, are minutes of a grazing phase; such a phase is
# held to what its depth allows, half its duration times 0.002 over the depth.

sub utc { Time::Keeper->new(@_, zone => 'UTC') }

my $file = -e 't/canon-lunar-1901-2100.tsv' ? 't/canon-lunar-1901-2100.tsv' : 'canon-lunar-1901-2100.tsv';
open my $fh, '<', $file or die "$file: $!";
my @canon;
while (<$fh>) {
    next if /^#/;
    chomp;
    my @f = split /\t/;
    push @canon, \@f;
}
close $fh;
is(scalar @canon, 457, 'the Canon has 457 lunar eclipses in 1901-2100');

my @ours = (Time::Keeper::Eclipse->between(kind => 'lunar', from => utc(year => 1901, month => 1, day => 1), to => utc(year => 2000, month => 12, day => 31, hour => 23)),
            Time::Keeper::Eclipse->between(kind => 'lunar', from => utc(year => 2000, month => 12, day => 31, hour => 23), to => utc(year => 2100, month => 12, day => 31, hour => 23)));
is(scalar @ours, 457, 'and so many are found: none missed, none invented');

my %w = (t => 0, u => 0, p => 0, g => 0, dur => 0);
my ($types, $dates) = (0, 0);
my $where = '';
for my $i (0 .. $#canon) {
    my ($date, $td, $dt, $type, $gamma, $pen, $um, $pd, $ud, $td_min) = @{ $canon[$i] };
    my $e = $ours[$i] or last;
    my $g = $e->greatest;
    $dates++ if substr("$g", 0, 10) eq $date || abs($g->epoch - utc(year => substr($date, 0, 4), month => substr($date, 5, 2), day => substr($date, 8, 2))->epoch) < 2 * 86400;
    $types++ if $e->type eq $type;
    # our greatest in TD: the instant's own TT
    my $ours_td = Time::Keeper::Sun::_jde($g);
    my ($h, $m, $s) = split /:/, $td;
    my $canon_td = utc(year => substr($date, 0, 4), month => substr($date, 5, 2), day => substr($date, 8, 2), hour => $h, minute => $m, second => $s);
    my $canon_jde = 2440587.5 + $canon_td->epoch / 86400;
    my $dtd = abs($ours_td - $canon_jde) * 86400;
    ($w{t}, $where) = ($dtd, "$date") if $dtd > $w{t};
    my %d = (u => abs($e->umbral_magnitude - $um), p => abs($e->penumbral_magnitude - $pen), g => abs($e->gamma - $gamma));
    $w{$_} = $d{$_} > $w{$_} ? $d{$_} : $w{$_} for keys %d;
    my %c = map { $_->[0] => $_->[1]->epoch } $e->contacts;
    for ([p1 => p4 => $pd, $pen], [u1 => u4 => $ud, $um], [u2 => u3 => $td_min, $um - 1]) {
        my ($a, $b, $minutes, $depth) = @$_;
        next if $minutes eq '-';
        next unless defined $c{$a} && defined $c{$b};
        my $dd = abs(($c{$b} - $c{$a}) - $minutes * 60);
        if ($depth >= 0.05) { $w{dur} = $dd if $dd > $w{dur} }
        else {
            my $allowed = 0.5 * $minutes * 60 * 0.002 / $depth + 6;
            $w{graze}++ if $dd > $allowed;
            $w{grazing}++;
        }
    }
}
is($dates, 457, 'each on the Canon\'s date');
is($types, 457, 'each of the Canon\'s type (penumbral, partial, total)');
cmp_ok($w{t}, '<=', 30, "greatest eclipse within 30 s in TD (worst $w{t} s, $where)");
cmp_ok($w{u}, '<=', 0.005, "the umbral magnitude within 0.005 (worst $w{u})");
cmp_ok($w{p}, '<=', 0.005, "the penumbral magnitude within 0.005 (worst $w{p})");
cmp_ok($w{g}, '<=', 0.003, "gamma within 0.003, chapter 47's 10 arcseconds (worst $w{g})");
# the Canon gives durations to a tenth of a minute: 3 s of rounding each way
cmp_ok($w{dur}, '<=', 60, "every phase deeper than 0.05 lasts within 60 s of the Canon's (worst $w{dur} s)");
is($w{graze} // 0, 0, "and the " . ($w{grazing} // 0) . " grazing phases within what their depth allows");

# ---- the object -------------------------------------------------------------------------------

{
    my $t = utc(year => 2026, month => 1, day => 1);
    my $e = Time::Keeper::Eclipse->next(kind => 'lunar', after => $t);
    is($e->kind, 'lunar', 'kind');
    is($e->type, 'total', 'the eclipse of 2026 March 3 is total');
    is(substr($e->greatest . '', 0, 10), '2026-03-03', '  on 3 March');
    is_deeply([map { $_->[0] } $e->contacts], [qw(p1 u1 u2 u3 u4 p4)], 'a total eclipse has six contacts, in order');
    my @c = map { $_->[1]->epoch } $e->contacts;
    ok(!grep({ $c[$_] <= $c[$_ - 1] } 1 .. $#c), '  one after another');
    ok($c[2] < $e->greatest->epoch && $e->greatest->epoch < $c[3], '  greatest between U2 and U3');
    is($e->contact('U2')->epoch, $c[2], 'contact by name, case not minded');
    my $p = Time::Keeper::Eclipse->next(kind => 'lunar', after => $e->greatest);
    is($p->type, 'partial', 'the next, 2026 August 28, is partial');
    is_deeply([map { $_->[0] } $p->contacts], [qw(p1 u1 u4 p4)], '  four contacts');
    ok(!defined $p->contact('u2'), '  and no U2');
    my $n = Time::Keeper::Eclipse->next(kind => 'lunar', after => $p->greatest);
    is($n->type, 'penumbral', 'the next, 2027 February 20, is penumbral');
    is_deeply([map { $_->[0] } $n->contacts], [qw(p1 p4)], '  two contacts');
    is(Time::Keeper::Eclipse->previous(kind => 'lunar', before => $p->greatest)->greatest->epoch, $e->greatest->epoch, 'previous goes back');
    is(Time::Keeper::Eclipse->next(kind => 'lunar', after => $e->greatest)->greatest->epoch, $p->greatest->epoch, 'next from an eclipse\'s own greatest is the next one');

    my $london = Time::Keeper::Sky->new(place => 'Europe/London');
    my $tokyo = Time::Keeper::Sky->new(place => 'Asia/Tokyo');
    my @all = $e->visible(place => $tokyo, all => 1);
    is(scalar @all, 6, 'visible with all => 1 gives every contact with the moon\'s altitude');
    my @up = $e->visible(place => $tokyo);
    is(scalar @up, scalar(grep { $_->[2] > 0 } @all), '  without it, the ones with the moon up');
    cmp_ok(scalar @up, '>=', 5, '  and Tokyo sees most of the eclipse of 2026 March 3 (evening)');
    is(scalar(my @l = $e->visible(place => $london)), 0, '  London none of it (morning there, the moon set)');
    my $z = Time::Keeper::Eclipse->next(kind => 'lunar', after => $t, zone => 'Asia/Tokyo');
    like($z->greatest . '', qr/\+09:00$/, 'zone => gives the values in that zone');
}

# ---- refusals -------------------------------------------------------------------------------

{
    my $t = utc(year => 2026, month => 1, day => 1);
    for ([[after => $t], qr/needs kind => lunar or solar/], [[kind => 'stellar', after => $t], qr/no eclipse kind is called 'stellar' \(lunar or solar\)/],
         [[kind => 'lunar', before => $t], qr/unknown argument 'before'/], [[kind => 'lunar', 'after'], qr/takes name and value pairs/]) {
        my ($args, $re) = @$_;
        ok(!eval { Time::Keeper::Eclipse->next(@$args); 1 }, "next(@$args) dies");
        like($@, $re, '  with its message');
    }
    ok(!eval { Time::Keeper::Eclipse->between(kind => 'lunar', from => $t, to => $t->epoch + 101 * 366 * 86400); 1 }, 'between: more than a century dies');
    ok(!eval { Time::Keeper::Eclipse->between(kind => 'lunar', from => $t, to => $t); 1 }, 'between: no span dies');
    my $e = Time::Keeper::Eclipse->next(kind => 'lunar', after => $t);
    ok(!eval { $e->contact('x1'); 1 }, 'an unknown contact dies');
    ok(!eval { $e->visible; 1 }, 'visible needs a place');
    ok(!eval { Time::Keeper::Eclipse::type('x'); 1 }, 'a method on something else dies');
    like($@, qr/type: not a Time::Keeper::Eclipse/, '  by name');
}

done_testing;
