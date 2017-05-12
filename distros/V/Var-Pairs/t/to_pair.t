use 5.014;
use strict;
use Test::More tests => 15;

use Var::Pairs;


# What each data type is supposed to expand to...

my $scalar            = 'scalar value';
my $ref               = [-10..-1];
my @array             = 1..10;
my %hash; @hash{1..6} = ('a'..'f');


# Do single args expand correctly???

is +(to_pair($scalar))[0]->key, 'scalar' => 'to_pair $scalar key';
is +(to_pair($ref))[0]->key,    'ref'    => 'to_pair $ref key';
is +(to_pair(@array))[0]->key,  'array'  => 'to_pair @array key';
is +(to_pair(%hash))[0]->key,   'hash'   => 'to_pair %hash key';

is +(to_pair($scalar))[0]->value, $scalar => 'to_pair $scalar value';
is +(to_pair($ref))[0]->value,    $ref    => 'to_pair $ref value';
is +(to_pair(@array))[0]->value, \@array  => 'to_pair @array value';
is +(to_pair(%hash))[0]->value,  \%hash   => 'to_pair %hash value';


# Do multiple args expand correctly???

my @list = to_pair $scalar, @array, %hash;
is scalar(@list), 3 => 'Correct number of args';

is $list[0]->key, 'scalar' => 'to_pair list keys';
is $list[1]->key,  'array';
is $list[2]->key,   'hash';

is $list[0]->value, $scalar => 'to_pair list values';
is $list[1]->value, \@array;
is $list[2]->value,  \%hash;
