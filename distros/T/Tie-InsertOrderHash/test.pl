#!/usr/bin/perl -w

use Test::More tests => 9;

eval 'use Tie::InsertOrderHash';
is ($@, '', 'loaded Tie::InsertOrderHash');

my %hash;
eval 'tie %hash => "Tie::InsertOrderHash"';
is ($@, '', 'tied empty hash');

eval '$hash{foo} = "bar"';
is ($@, '', 'inserted key/value pair');
my $value;
eval '$value = $hash{foo}';
is ($@, '', 'extracted value for key');
is ($value, 'bar', 'value ok');

eval 'untie %hash';
is ($@, '', 'untied hash');

eval 'tie %hash => "Tie::InsertOrderHash",
  a => 1, b => 2, "\x{263A}" => "smile", c => 3, 5 => 7';
is ($@, '', 'tied hash with key/value pairs');
my @keys;
eval '@keys = keys %hash';
is ($@, '', 'extracted keys');
is_deeply (['a', 'b', "\x{263A}", 'c', 5], \@keys, 'keys in insert order');

1;
