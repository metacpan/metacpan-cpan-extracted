#use strict;
#use warnings;

use Test::More tests => 2;                      # last test to print

eval { require List::Util };
plan skip_all => "List::Util not installed" if $@; 

use FindBin '$Bin';
use rig -file => $Bin . '/perlrig';

use rig '_t_perlrig';
is( eval '$var = 1 ', undef , 'strictness' ) ;

use rig '_t_perlrig_utils';
is( sum(1..10), 55, 'sum' );

