#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;
use Time::Keeper::Natural::Words;

my $N = 'Time::Keeper::Natural';
my $W = 'Time::Keeper::Natural::Words';
my $dir = $W->dir;
opendir my $dh, $dir or die "$dir: $!";
my @codes = sort map { /^(.+)\.txt\z/ ? $1 : () } readdir $dh;
closedir $dh;
cmp_ok(scalar @codes, '>=', 16, 'the tables: ' . join(' ', @codes));

my $en = $W->from_file("$dir/en.txt", 'en');
my %english = map { my $k = $_; map { lc($_) => $k } $en->phrases($k) } $en->keys;

for my $code (@codes) {
    my $w = eval { $W->from_file("$dir/$code.txt", $code) };
    ok($w, "$code: the table loads") or do { diag($@); next };
    my @tests = $w->tests;
    cmp_ok(scalar @tests, '>=', 3, "$code: at least three test lines");

    my $anchor = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London', locale => $code);
    local $Time::Keeper::CLOCK = $anchor;
    my $n = $N->new(zone => 'Europe/London', locale => $code);
    my @bad;
    for my $t (@tests) {
        my $got = eval { $t->[1] =~ m{ / } ? join(' / ', $n->parse_interval($t->[0])) : '' . $n->parse($t->[0]) };
        push @bad, "'$t->[0]' gave " . ($got // "a death: $@") . ", not $t->[1]" unless defined $got && $got eq $t->[1];
    }
    ok(!@bad, "$code: every test line reads to its value") or diag(join "\n", @bad);

    for my $key ($w->keys) {
        my @p = $w->phrases($key);
        next unless @p;
        my $used = grep {
            my $text = $_->[0];
            $key eq 'of' ? scalar(() = $w->split_on($text, 'of'))
          : $key eq 'range' ? $_->[1] =~ m{ / } && scalar(grep { my ($m) = /\{0\}(.*)\{1\}/; $m =~ s/^\s+|\s+\z//g; length $m && (index(lc $text, lc " $m ") >= 0 || (($w->{spaceless} || /\}\S|\S\{1\}/) && index(lc $text, lc $m) >= 0)) } @p)
          : $key eq 'skip' || $key eq 'last' ? scalar(grep { $text =~ /(?:^|[\s'\x{2019}])\Q$_\E(?:\s|['\x{2019}]|\z)/i || index(lc $text, lc $_) == 0 || ($w->{spaceless} && index($text, $_) >= 0) } @p)
          : $key eq 'alias' ? scalar(grep { my ($i) = split /=/; index(lc $text, lc $i) >= 0 } @p)
          : $key eq 'nth' ? scalar(grep { my @l = grep { /\S/ } split /\{(?:period|n|weekday)\}/; !grep { index(lc $text, lc(s/^\s+|\s+\z//gr)) < 0 } @l } @p)
          : scalar(() = $w->frame($text, $key)) || scalar(grep { index(lc $text, lc($_ =~ s/\s*\{0\}\s*//r)) >= 0 } @p);
        } @tests;
        ok($used, "$code: some test line uses its $key");
    }

    next if $code eq 'en';
    my $text = do { local $/; open my $fh, '<:encoding(UTF-8)', "$dir/$code.txt" or die $!; <$fh> };
    like($text, qr/^# UNREVIEWED:/m, "$code: the table says it is unreviewed");
    my @lifted = grep { exists $english{ lc $_ } } map { $w->phrases($_) } $w->keys;
    is_deeply(\@lifted, [], "$code: no phrase lifted from English");
    my ($first) = grep { $_->[1] =~ /T23:59:59/ || $_->[1] =~ /T00:00:00/ } @tests;
    my $p = $N->new(zone => 'Europe/London', locale => 'en');
    ok(!defined $p->try_parse($first->[0]), "$code: '$first->[0]' does not read as English") if $first;
    # and the other way: English's worded test lines do not read in the locale
    my $here = $N->new(zone => 'Europe/London', locale => $code);
    my @read = grep { defined $here->try_parse($_->[0]) || eval { $here->parse_interval($_->[0]); 1 } } grep { $_->[0] =~ /[a-z]{3}/ } $en->tests;
    is_deeply([map { $_->[0] } @read], [], "$code: English's test lines do not read in it");
}

# A table never takes a CLDR word's meaning: in every locale with a table, each
# relative string CLDR has still reads, a counted one to the anchor plus its count.
# (Bengali's locative frame "{0}ে" would otherwise swallow CLDR's "1 মাসে".)
{
    my $a = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
    local $Time::Keeper::CLOCK = $a;
    my %plus = (year => 'years', quarter => 'months', month => 'months', week => 'weeks', day => 'days',
                hour => 'hours', minute => 'minutes', second => 'seconds');
    my ($asks, @bad, @faults) = (0);
    for my $code (grep { $_ ne 'en' } @codes) {
        my $p = $N->new(zone => 'Europe/London', locale => $code);
        my $v = $a->in_locale($code);
        for my $f (qw(year quarter month week day hour minute second mon tue wed thu fri sat sun)) {
            for my $w (qw(long short narrow)) {
                my $r = Time::Keeper::Locale->relative_names($code, $f, $w);
                for my $s (values %{ $r->{at} }) {
                    $asks++;
                    # A phrase CLDR writes for two offsets (ar "this or next
                    # Saturday") reads once prefer picks one (0.02).
                    push @bad, "$code '$s' does not read" unless defined $p->try_parse($s) || defined $p->new(prefer => 'future')->try_parse($s);
                }
                for my $c (1, 2, 3) {
                    for my $d ([future => 1], [past => -1]) {
                        my %seen;
                        for my $pat (grep { !$seen{$_}++ } values %{ $r->{ $d->[0] } }) {
                            (my $s = $pat) =~ s/\{0\}/$c/;
                            $asks++;
                            my $got = $p->try_parse($s) // $p->new(prefer => $d->[0])->try_parse($s);
                            if (!defined $got) { push @bad, "$code '$s' does not read"; next }
                            next unless $plus{$f} && $pat =~ /\{0\}/;
                            my $other = $d->[1] > 0 ? 'past' : 'future';
                            if (grep { $_ eq $pat } values %{ $r->{$other} }) { push @faults, "$code $f $w '$pat'"; next }
                            my $want = $v->plus($plus{$f} => $d->[1] * $c * ($f eq 'quarter' ? 3 : 1));
                            push @bad, "$code '$s' read as $got, not $want" unless $got->epoch == $want->epoch;
                        }
                    }
                }
            }
        }
    }
    ok(!@bad, "every CLDR relative string reads in the table locales ($asks asks)") or diag(join "\n", @bad[0 .. ($#bad < 14 ? $#bad : 14)]);
    my %f = map { $_ => 1 } @faults;
    is_deeply([ sort keys %f ], ["ar month short '\x{62e}\x{644}\x{627}\x{644} {0} \x{623}\x{634}\x{647}\x{631}'"],
              'the one CLDR 48.2.3 pattern written for both directions, Arabic\'s short few months, is left to its marker') or diag(join "\n", sort keys %f);
}

# The POD names the tables that ship, and only those.
{
    my $pm = $INC{'Time/Keeper/Natural.pm'};
    open my $fh, '<:encoding(UTF-8)', $pm or die $!;
    my ($line) = grep { /^Word tables ship for:/ } <$fh>;
    ok($line, 'the POD lists the tables');
    my @found = ($line // '') =~ /\b([a-z]{2,3}(?:-[A-Za-z0-9]+)*)\b(?=[,.\s])/g;
    my @listed = sort grep { $_ ne 'for' } @found;
    is_deeply(\@listed, \@codes, 'and its list is the directory');
}

done_testing;
