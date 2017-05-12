#!perl

use strict;
use warnings FATAL => 'all';
use Test::Most qw(!code);
use Tie::Symbol;

plan tests => 15;

tie( my %ST, 'Tie::Symbol' );

sub abc { 123 }
our $abc = 456;
our @abc = qw(7 8 9);
our %abc = ( 10, 11, 12, 13 );

isa_ok $ST{'&abc'} => 'CODE';
isa_ok $ST{'$abc'} => 'SCALAR';
isa_ok $ST{'@abc'} => 'ARRAY';
isa_ok $ST{'%abc'} => 'HASH';

is $ST{'@def'} => undef, '@def is undef';
is $ST{'%def'} => undef, '%def is undef';
is $ST{'&def'} => undef, '&def is undef';

is $ST{'&abc'} => \&abc, 'refaddr of &abc';
is $ST{'$abc'} => \$abc, 'refaddr of $abc';
is $ST{'@abc'} => \@abc, 'refaddr of @abc';
is $ST{'%abc'} => \%abc, 'refaddr of %abc';

is_deeply $ST{'$abc'} => \456, 'unpack $abc';
is_deeply $ST{'@abc'} => [ 7, 8, 9 ], 'unpack @abc';
is_deeply $ST{'%abc'} => { 10, 11, 12, 13 }, 'unpack %abc';
is $ST{'&abc'}->() => 123, 'unpack &abc';

done_testing;
