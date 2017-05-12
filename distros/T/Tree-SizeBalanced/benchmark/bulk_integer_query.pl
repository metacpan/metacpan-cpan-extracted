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
                push @array, $query;
            }
            for(1 .. $data_size) {
                my $query = int rand 10**10;
                my $count = grep { $_ > $query } @array;
                print "$query: $count\n" if $verbose;
            }
        }
    } },
    'Sorted array' => sub { eval {
        for my $seed (1 .. $seed_count) {
            srand($seed);

            my @array;
            for(1 .. $data_size) {
                my $query = int rand 10**10;
                push @array, $query;
            }
            @array = sort { $a <=> $b } @array;
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
            }
        }
    } },
    'tree set int' => sub { eval {
        for my $seed (1 .. $seed_count) {
            srand($seed);

            my $tree = sbtreei;
            for(1 .. $data_size) {
                my $query = int rand 10**10;
                $tree->insert($query);
            }
            for(1 .. $data_size) {
                my $query = int rand 10**10;
                my $count = $tree->count_gt($query);
                print "$query: $count\n" if $verbose;
            }
        }
    } },
    'tree set any' => sub { eval {
        for my $seed (1 .. $seed_count) {
            srand($seed);

            my $tree = sbtreea { $a <=> $b };
            for(1 .. $data_size) {
                my $query = int rand 10**10;
                $tree->insert($query);
            }
            for(1 .. $data_size) {
                my $query = int rand 10**10;
                my $count = $tree->count_gt($query);
                print "$query: $count\n" if $verbose;
            }
        }
    } },
});

__END__

test result: (perl 5.22.2, Tree::SizeBalanced 2.6)



seed_count=10, data_size=100_000, verbose=0

Benchmark: timing 1 iterations of Sorted array, Static array, tree set any, tree set int...
Sorted array:  3 wallclock secs ( 2.99 usr +  0.00 sys =  2.99 CPU) @  0.33/s (n=1)
            (warning: too few iterations for a reliable count)
^CSIGINT!
Static array: 251 wallclock secs (251.85 usr +  0.02 sys = 251.87 CPU) @  0.00/s (n=1)
            (warning: too few iterations for a reliable count)
tree set any:  6 wallclock secs ( 5.24 usr +  0.00 sys =  5.24 CPU) @  0.19/s (n=1)
            (warning: too few iterations for a reliable count)
tree set int:  1 wallclock secs ( 0.86 usr +  0.00 sys =  0.86 CPU) @  1.16/s (n=1)
            (warning: too few iterations for a reliable count)

(Note that "Static array" didn't complete. It's interrupted)
