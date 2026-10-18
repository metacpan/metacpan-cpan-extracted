#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Local qw(timegm);

# resolve_local_all at every overlap and gap of every zone from 1970 to
# 2100. An overlap's first and last repeated wall-clock seconds have two
# instants, earlier first, with different offsets and the same wall clock;
# the second just after it has one. A gap's first and last skipped seconds
# have none, and the offsets either side; the second just after it has one.

use Time::Keeper::Zone;

my $Z = 'Time::Keeper::Zone';
sub abi { Time::Keeper::Zone::_abi_call(@_) }

my ($from, $to) = (timegm(0, 0, 0, 1, 0, 1970), timegm(0, 0, 0, 1, 0, 2100));
my ($overlaps, $gaps, @bad) = (0, 0);

for my $name ($Z->names) {
    my $id = abi('lookup', $name);
    for my $t ($Z->transitions($name, $from, $to)) {
        my ($at, $before, $after) = @$t;
        next if $before == $after;
        my $err;
        if ($after < $before) {
            $overlaps++;
            for my $local ($at + $after, $at + $before - 1) {
                my ($n, $u0, $o0, $u1, $o1) = abi('resolve_local_all', $id, $local);
                my ($s0) = $Z->offset_at($name, $u0);
                my ($s1) = $Z->offset_at($name, $u1);
                $err = "overlap: $n readings" if $n != 2;
                $err //= 'overlap: not earlier first' unless $u0 < $u1;
                $err //= 'overlap: the same offset twice' if $o0 == $o1;
                $err //= 'overlap: wall clocks differ' unless $u0 + $s0 == $local && $u1 + $s1 == $local;
                $err //= 'overlap: offsets disagree with offset_at' unless $o0 == $s0 && $o1 == $s1;
                last if $err;
            }
            $err //= 'after an overlap: not one reading'
                unless (abi('resolve_local_all', $id, $at + $before))[0] == 1;
        }
        else {
            $gaps++;
            for my $local ($at + $before, $at + $after - 1) {
                my ($n, $u0, $o0, $u1, $o1) = abi('resolve_local_all', $id, $local);
                $err = "gap: $n readings" if $n != 0;
                $err //= 'gap: not the offsets either side' unless $o0 == $before && $o1 == $after;
                $err //= 'gap: utc is not local less the offset'
                    unless $u0 == $local - $o0 && $u1 == $local - $o1;
                last if $err;
            }
            $err //= 'after a gap: not one reading'
                unless (abi('resolve_local_all', $id, $at + $after))[0] == 1;
        }
        if ($err) {
            push @bad, "$name at $at: $err";
            last;
        }
    }
}

cmp_ok($overlaps, '>', 1000, "$overlaps overlaps");
cmp_ok($gaps, '>', 1000, "$gaps gaps");
is(scalar @bad, 0, 'every one has the readings it should')
    or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);

done_testing;
