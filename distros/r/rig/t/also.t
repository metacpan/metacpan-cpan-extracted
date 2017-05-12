use strict;
use warnings;
no strict 'refs';
use Test::More;

eval { require List::Util };
plan skip_all => "List::Util not installed" if $@; 

use FindBin '$Bin';
use rig -file => $Bin . '/perlrig';
use rig '_t_also';
my %sym = %{ \%main:: };
ok( exists $sym{countit}, 'countit also' );
ok( exists $sym{first}, 'first also' );
ok( exists $sym{cmpthese}, 'cmpthese also' );
ok( ref timethese( 10, { a=>sub{ '' } }), 'also 2' );
is( ( first { defined } ('a','b') ), 'a', 'also first' );

done_testing;
