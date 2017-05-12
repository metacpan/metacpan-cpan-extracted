use 5.014;
use strict;
use Test::More tests => 12;

use Var::Pairs;

my @data = 'a'..'f';
my %data = kvs @data;

for my $index (0..$#data) {
    is $data[$index], $data{$index} => "kv'd index $index correctly";
}

while (1) {
    my ($index, $value) = each_kv @data
        or last;
    is $data[$index], $value => "each_kv'd index $index correctly";
}

