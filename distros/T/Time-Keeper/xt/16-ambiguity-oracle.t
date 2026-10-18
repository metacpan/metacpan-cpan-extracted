#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Local qw(timegm);

# Every overlap in every zone from 1970 to 2100: the two values with the
# repeated wall-clock time are each other's other_reading, both are
# ambiguous, and new() with overlap => earlier and later gives them. The
# overlaps come from Zone's transitions: one where the offset falls.

use Time::Keeper;
use Time::Keeper::Zone;

my $K = 'Time::Keeper';
my ($from, $to) = (timegm(0, 0, 0, 1, 0, 1970), timegm(0, 0, 0, 1, 0, 2100));
my ($overlaps, @bad) = (0);

for my $name (Time::Keeper::Zone->names) {
    for my $tr (Time::Keeper::Zone->transitions($name, $from, $to)) {
        my ($at, $before, $after) = @$tr;
        next unless $after < $before;
        $overlaps++;
        # At $at the clocks read $at + $after, which they first read
        # $before - $after seconds earlier.
        my $l = $K->from_epoch($at, zone => $name);
        my $e = $K->from_epoch($at - ($before - $after), zone => $name);
        my $err;
        $err = 'the earlier is not ambiguous' unless $e->is_ambiguous;
        $err //= 'the later is not ambiguous' unless $l->is_ambiguous;
        $err //= 'wall clocks differ' unless $e->strftime('%F %T') eq $l->strftime('%F %T');
        $err //= 'other_reading of the earlier is not the later'
            unless defined $e->other_reading && $e->other_reading->epoch == $l->epoch;
        $err //= 'other_reading of the later is not the earlier'
            unless defined $l->other_reading && $l->other_reading->epoch == $e->epoch;
        unless ($err) {
            my %f = map { $_ => $l->$_ } qw(year month day hour minute second);
            my $ne = $K->new(%f, zone => $name, overlap => 'earlier');
            my $nl = $K->new(%f, zone => $name, overlap => 'later');
            $err = 'overlap => earlier is not the earlier' unless $ne->epoch == $e->epoch;
            $err //= 'overlap => later is not the later' unless $nl->epoch == $l->epoch;
        }
        if ($err) {
            push @bad, "$name at $at: $err";
            last;
        }
    }
}

cmp_ok($overlaps, '>', 1000, "$overlaps overlaps");
is(scalar @bad, 0, 'each has two readings that are each other\'s other_reading')
    or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);

done_testing;
