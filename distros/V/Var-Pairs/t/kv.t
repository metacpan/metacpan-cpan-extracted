use 5.014;
use strict;
use Test::More tests => 5;

use Var::Pairs;


# What each data type is supposed to expand to...

my $scalar          = 'scalar value';
my $expected_scalar = [ 'scalar' => $scalar ];

my $ref          = [-10..-1];
my $expected_ref = [ 'ref' => $ref ];

my @array          = 1..10;
my $expected_array = [ 'array' => \@array ];

my %hash; @hash{1..6} = ('a'..'f');
my $expected_hash     = [ 'hash' => \%hash ];


# Do single args expand correctly???

is_deeply [to_kv($scalar)], $expected_scalar => 'to_kv $scalar';
is_deeply [to_kv($ref)],    $expected_ref    => 'to_kv $ref';
is_deeply [to_kv(@array)],  $expected_array  => 'to_kv @array';
is_deeply [to_kv(%hash)],   $expected_hash   => 'to_kv %hash';


# Do multiple args expand correctly???

is_deeply [to_kv $scalar, @array, %hash ],
          [@$expected_scalar, @$expected_array, @$expected_hash]
          => 'to_kv $scalar, @array, %hash';
