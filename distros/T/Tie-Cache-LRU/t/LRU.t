#!/usr/bin/perl -w

use strict;
use Test::More tests => 29;

use_ok 'Tie::Cache::LRU';


my %cache;
my $tied = tie %cache, 'Tie::Cache::LRU', 5;
ok(defined $tied, 'tie');


{

$cache{foo} = "bar";
is($cache{foo}, 'bar', 'basic store & fetch');

ok(exists $cache{foo}, 'basic exists');

$cache{bar} = 'yar';
$cache{car} = 'jar';
# should be car, bar, foo
my @test_order = qw(car bar foo);
my @keys = keys %cache;
is_deeply(\@test_order, \@keys, 'basic keys');


# Try a key reordering.
my $foo = $cache{bar};
# should be bar, car, foo
@test_order = qw(bar car foo);
@keys = keys %cache;
is_deeply(\@test_order, \@keys, 'basic promote');


# Try the culling.
$cache{har}  = 'mar';
$cache{bing} = 'bong';
$cache{zip}  = 'zap';
# should be zip, bing, har, bar, car
@test_order = qw(zip bing har bar car);
@keys = keys %cache;
is_deeply(\@test_order, \@keys, 'basic cull');


# Try deleting from the end.
delete $cache{car};
is_deeply([qw(zip bing har bar)], [keys %cache], 'end delete');

# Try from the front.
delete $cache{zip};
is_deeply([qw(bing har bar)], [keys %cache], 'front delete');

# Try in the middle
delete $cache{har};
is_deeply([qw(bing bar)], [keys %cache], 'middle delete');

# Add a bunch of stuff and make sure the index doesn't grow.
@cache{qw(1 2 3 4 5 6 7 8 9 10)} = qw(11 12 13 14 15 16 17 18 19 20);
is(keys %{tied(%cache)->{index}}, 5);


# Test accessing the sizes.
my $cache = tied %cache;
is( $cache->curr_size, 5,                    'curr_size()' );
is( $cache->max_size,  5,                    'max_size()'  );

# Test lowering the max_size.
@keys = keys %cache;

$cache->max_size(2);
is( $cache->curr_size, 2 );
is( keys %cache, 2 );
is_deeply( [@keys[0..1]], [keys %cache] );


# Test raising the max_size.
$cache->max_size(10);
is( $cache->curr_size, 2 );
for my $num (21..28) { $cache{$num} = "THIS IS REALLY OBVIOUS:  $num" }
is( $cache->curr_size, 10 );
is_deeply( [@keys[0..1]], [(keys %cache)[-2,-1]] );

%cache = ();
is( $cache->curr_size,  0 );
is( keys   %cache,      0 );
is( values %cache,      0 );
is( $cache->max_size,   10 );

}


# Make sure an empty cache will work.
my %null_cache;
$tied = tie %null_cache, 'Tie::Cache::LRU', 0;
ok(defined $tied, 'tie() null cache');

$null_cache{foo} = "bar";
ok(!exists $null_cache{foo},    'basic null cache exists()' );
is( $tied->curr_size,   0,      'curr_size() null cache' );
is( keys   %null_cache, 0,      'keys() null cache' );
is( values %null_cache, 0,      'values() null cache' );
is( $tied->max_size,    0,      'max_size() null cache' );
