# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 3;
use vars qw(%hash);

BEGIN { use_ok( 'Tie::Hash::MultiValue' ); }

my $object = tie %hash, 'Tie::Hash::MultiValue';
isa_ok($object, 'Tie::Hash::MultiValue');
can_ok $object, qw(iterators refs mode);
