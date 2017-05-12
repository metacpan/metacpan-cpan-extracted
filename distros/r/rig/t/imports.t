BEGIN {
    sub rig::task::t_imports::rig {
        { use => [
            { 'List::Util'=> [ 'sum','max' ] },
        ] }
    };
}

use Test::More;

eval { require List::Util };
plan skip_all => "List::Util not installed" if $@; 

use FindBin '$Bin';
use rig -file => $Bin . '/perlrig';
use rig 't_imports';

is( sum(1..10), 55, 'sum' );
is( max(1..10), 10, 'max' );

done_testing;
