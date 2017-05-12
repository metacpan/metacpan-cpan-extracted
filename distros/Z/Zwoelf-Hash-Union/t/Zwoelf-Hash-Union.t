# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Zwoelf-Hash-Union.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;
use Test::Deep;
BEGIN { use_ok('Zwoelf::Hash::Union') };

use Zwoelf::Hash::Union qw( unique_array merge_hash );

my $fn_unique_array = \&unique_array;
my $fn_merge_hash   = \&merge_hash;

my $hash1    = { a => 1, b => [2..4], c => { d => 5, e => [ {f => 6 }, { g => 7 } ] } };
my $hash2    = { a => 1, b => [2..6], c => { d => 5, e => [ {f => 6 }, { h => 8 } ] } };
my $exp_hash = { a => 1, b => [2..6], c => { d => 5, e => [ {f => 6 }, { g => 7 }, { h => 8 } ] } };

my $array1    = [ {f => 6 }, { g => 7 }, { f => 6 }, { g => 7 }, { h => 8 } ];
my $exp_array = [ {f => 6 }, { g => 7 }, { h => 8 } ];

my $unique_array = $fn_unique_array->( $array1 );
cmp_deeply( $unique_array, $exp_array, 'unification of array works' );

my $merged = $fn_merge_hash->( $hash1, $hash2 );
cmp_deeply( $merged, $exp_hash, 'merging with union of array works' );

my $merged_2 = merge_hash(
    { a => 1, b => [{ b => 2 }, { c => 3 }] },
    { a => 2, b => [{ b => 2 }, { d => 4 }] },
);
my $expect_2 = { a => 2, b => [{ b => 2}, { c => 3 }, { d => 4 }] };
cmp_deeply( $merged_2, $expect_2, 'merging with union of array as from POD works' );

my $merged_3 = merge_hash(
    { a => 1, b => [{ b => 2 }, { c => 3 }] },
    { a => 2, b => [{ b => 2 }, { d => 4 }] },
    'LEFT_PRECEDENT'
);
my $expect_3 = { a => 1, b => [{ b => 2}, { c => 3 }, { d => 4 }] };
cmp_deeply( $merged_3, $expect_3, 'merging  with LEFT_PRECEDENT works' );

done_testing();
