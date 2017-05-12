#!/usr/bin/perl

use strict;
use warnings;

use Benchmark qw(:all);
use Tree::SizeBalanced qw(:short);

my $seed_count = 10;
my $data_size = 100_000;
my $verbose = 0;

$SIG{INT} = sub {
    print "SIGINT!\n";
    die;
};

timethese(1, {
    'Static array' => sub { eval {
        for my $seed (1 .. $seed_count) {
            srand($seed);

            my @array;
            for(1 .. $data_size) {
                my $query = int rand 10**10;
                my $count = grep { $_ gt $query } @array;
                print "$query: $count\n" if $verbose;
                push @array, $query;
            }
        }
    } },
    'Sorted array' => sub { eval {
        for my $seed (1 .. $seed_count) {
            srand($seed);

            my @array;
            for(1 .. $data_size) {
                my $query = int rand 10**10;

                my($a, $b) = (0, 0+@array);
                while( $a < $b ) {
                    my $c = $a + $b >> 1;
                    if( $array[$c] le $query ) {
                        $a = $c + 1;
                    } else {
                        $b = $c;
                    }
                }
                my $count = @array - $a;
                print "$query: $count\n" if $verbose;

                splice @array, $a, 0, $query;
            }
        }
    } },
    'tree set str' => sub { eval {
        for my $seed (1 .. $seed_count) {
            srand($seed);

            my $tree = sbtrees;
            for(1 .. $data_size) {
                my $query = int rand 10**10;
                my $count = $tree->count_gt($query);
                print "$query: $count\n" if $verbose;
                $tree->insert($query);
            }
        }
    } },
    'tree set any' => sub { eval {
        for my $seed (1 .. $seed_count) {
            srand($seed);

            my $tree = sbtreea { $a cmp $b };
            for(1 .. $data_size) {
                my $query = int rand 10**10;
                my $count = $tree->count_gt($query);
                print "$query: $count\n" if $verbose;
                $tree->insert($query);
            }
        }
    } },
});

__END__

test result: (perl 5.22.2, Tree::SizeBalanced 2.6)



seed_count=10, data_size=100_000, verbose=0

Benchmark: timing 1 iterations of Sorted array, Static array, tree set any, tree set str...
Sorted array: 15 wallclock secs (15.28 usr +  0.00 sys = 15.28 CPU) @  0.07/s (n=1)
            (warning: too few iterations for a reliable count)
^CSIGINT!
Static array: 673 wallclock secs (672.08 usr +  0.15 sys = 672.23 CPU) @  0.00/s (n=1)
            (warning: too few iterations for a reliable count)
tree set any:  6 wallclock secs ( 6.65 usr +  0.00 sys =  6.65 CPU) @  0.15/s (n=1)
            (warning: too few iterations for a reliable count)
tree set str:  2 wallclock secs ( 1.88 usr +  0.00 sys =  1.88 CPU) @  0.53/s (n=1)
            (warning: too few iterations for a reliable count)

(Note that "Static array" didn't complete. It's interrupted)
