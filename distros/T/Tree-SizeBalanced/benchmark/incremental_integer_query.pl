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
                my $count = grep { $_ > $query } @array;
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
                    if( $array[$c] <= $query ) {
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
    'tree set int' => sub { eval {
        for my $seed (1 .. $seed_count) {
            srand($seed);

            my $tree = sbtreei;
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

            my $tree = sbtreea { $a <=> $b };
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

Benchmark: timing 1 iterations of Sorted array, Static array, tree set any, tree set int...
Sorted array: 12 wallclock secs (12.60 usr +  0.00 sys = 12.60 CPU) @  0.08/s (n=1)
            (warning: too few iterations for a reliable count)
^CSIGINT!
Static array: 737 wallclock secs (736.96 usr +  0.14 sys = 737.10 CPU) @  0.00/s (n=1)
            (warning: too few iterations for a reliable count)
tree set any:  5 wallclock secs ( 4.70 usr +  0.01 sys =  4.71 CPU) @  0.21/s (n=1)
            (warning: too few iterations for a reliable count)
tree set int:  1 wallclock secs ( 0.69 usr +  0.01 sys =  0.70 CPU) @  1.43/s (n=1)
            (warning: too few iterations for a reliable count)

(Note that "Static array" didn't complete. It's interrupted)
