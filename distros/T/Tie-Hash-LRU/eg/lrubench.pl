
use strict;
use warnings;

use Benchmark qw(:all);
use Cache::FastMmap;
use Cache::LRU;
use Tie::Cache::LRU;
use Tie::Hash::LRU;

# this script is baed on simple.pl benchmark from Cache::LRU

my $size = 20480;
my $loop = 100;

sub cache_hit {
    my $cache = shift;
    $cache->set(a => 1);
    my $c = 0;
    $c += $cache->get('a')
        for 1..$loop;
    $c;
}

sub cache_tie_hit {
    my $cache = shift;
    $cache->STORE(a => 1);
    my $c = 0;
    $c += $cache->FETCH('a')
        for 1..$loop;
    $c;
}

print "cache_hit:\n";
cmpthese(-1, {
    'Cache::FastMmap' => sub {
        cache_hit(
            Cache::FastMmap->new(
                cache_size => '1m',
            ),
        );
    },
    'Cache::FastMmap (raw)' => sub {
        cache_hit(
            Cache::FastMmap->new(
                cache_size => '1m',
                raw_values => 1,
            ),
        );
    },
    'Cache::LRU' => sub {
        cache_hit(
            Cache::LRU->new(
                size => $size,
            ),
        );
    },
    'Tie::Hash::LRU (direct)' => sub {
        cache_tie_hit(
            Tie::Hash::LRU->TIEHASH($size),
        );
    },
    'Tie::Cache::LRU (direct)' => sub {
        cache_tie_hit(
            Tie::Cache::LRU->TIEHASH($size),
        );
    },

    'Tie::Hash::LRU (tied)' => sub {
        tie my %cache, 'Tie::Hash::LRU', $size;
        $cache{a} = 1;
        my $c = 0;
        $c += $cache{a}
            for 1..$loop;
        $c;
    },

    'Tie::Cache::LRU (tied)' => sub {
        tie my %cache, 'Tie::Cache::LRU', $size;
        $cache{a} = 1;
        my $c = 0;
        $c += $cache{a}
            for 1..$loop;
        $c;
    },
});

print "\ncache_set:\n";
srand(0);
my @keys = map { int rand(1048576) } 1..65536;

sub cache_set {
    my $cache = shift;
    $cache->set($_ => 1)
        for @keys;
    $cache;
}
sub cache_tie_set {
    my $cache = shift;
    $cache->STORE($_ => 1)
        for @keys;
    $cache;
}
cmpthese(-1, {
    # no test for Cache::FastMmap since it does not have the "size" parameter
    'Cache::LRU' => sub {
        cache_set(
            Cache::LRU->new(
                size => $size,
            ),
        );
    },

    'Tie::Hash::LRU (tied)' => sub {
        tie my %cache, 'Tie::Hash::LRU', $size;
        $cache{$_} = 1
            for @keys;
        \%cache;
    },

    'Tie::Hash::LRU (direct)' => sub {
        cache_tie_set(
            Tie::Hash::LRU->TIEHASH($size),
        );
    },

    'Tie::Cache::LRU (tied)' => sub {
        tie my %cache, 'Tie::Cache::LRU', $size;
        $cache{$_} = 1
            for @keys;
        \%cache;
    },

    'Tie::Cache::LRU (direct)' => sub {
        cache_tie_set(
            Tie::Cache::LRU->TIEHASH($size),
        );
    },
});
