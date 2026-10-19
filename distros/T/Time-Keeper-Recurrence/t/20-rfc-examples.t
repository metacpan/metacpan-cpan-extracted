#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;
use Time::Keeper::Recurrence;

# Every RRULE example of RFC 5545 section 3.8.5.3 (and the one in 3.3.10)
# gives exactly the occurrences the RFC lists, read from t/rfc5545-examples.tsv,
# transcribed from the RFC text. The examples are in America/New_York, as the
# RFC says, and run in it.

my $R = 'Time::Keeper::Recurrence';
my $zone = 'America/New_York';
my $far = Time::Keeper->new(year => 2100, month => 1, day => 1, zone => 'UTC');

# the TSV's shorthand: @days A B HH:MM is every day A to B at that time;
# @grid DAY H0 H1 M,M,M is every listed minute of each hour H0 to H1 of DAY
sub expand {
    my @out;
    my @tok = split ' ', shift;
    while (@tok) {
        my $t = shift @tok;
        if ($t eq '@days') {
            my ($a, $b, $hm) = splice @tok, 0, 3;
            my $d = Time::Keeper::Date->parse($a);
            my $e = Time::Keeper::Date->parse($b);
            while ($d <= $e) { push @out, $d->iso8601 . "T$hm"; $d = $d->plus(days => 1) }
        }
        elsif ($t eq '@grid') {
            my ($day, $h0, $h1, $mins) = splice @tok, 0, 4;
            for my $h ($h0 .. $h1) { push @out, sprintf('%sT%02d:%02d', $day, $h, $_) for split /,/, $mins }
        }
        else { push @out, $t }
    }
    return @out;
}

open my $fh, '<', 't/rfc5545-examples.tsv' or die "t/rfc5545-examples.tsv: $!";
my $n = 0;
while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ /^#/ || $line !~ /\S/;
    my ($name, $dtstart, $rrule, $occ, $complete, $start_excluded) = split /\t/, $line;
    my @want = expand($occ);
    my $start = Time::Keeper->parse($dtstart, zone => $zone);
    my $r = $R->new(rrule => $rrule, start => $start);
    my @got = $complete ? $r->between($start, $far) : $r->first(scalar(@want) + $start_excluded);
    shift @got if $start_excluded;
    my @text = map { $_->format('y-MM-dd') . 'T' . $_->format('HH:mm') } @got;
    is_deeply(\@text, \@want, $name) or diag(join(' ', @text) . "\n" . join(' ', @want));
    is($r->zone, $zone, "$name: in New York");
    if ($complete) {
        is(scalar($r->first(scalar @want + 1)), $want[-1] ? scalar @want : 0, "$name: first(n+1) gives n: the rule ends") if 0;
        my @more = $r->first(scalar(@want) + 1);
        is(scalar @more, scalar @want, "$name: the rule ends there") if !$start_excluded;
    }
    $n++;
}
close $fh;
cmp_ok($n, '>=', 43, 'every example ran');

done_testing;
