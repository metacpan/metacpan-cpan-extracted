use 5.014;
use warnings;
use autodie;

use Test::More;
use if $] > 5.016, experimental => 'smartmatch';
no warnings 'deprecated';

BEGIN {
    if ($] > 5.040) {
        plan skip_all => 'Smartmatching is iffy in recent Perls';
    }
}

use Test::Simpler tests => 2;

{
    my $expected = [ { a => 1, b => 2 }, 'c' ];
    my @got      = ( { a => 1, b => 2 }, 'c' );

    ok
        @got
        ~~
        $expected

    => 'Test 1';
}


TODO:{
    local $TODO = 'These are supposed to fail';

    {
        my $expected = [ { a => 1, b => 2, c => 3 }, 'c' ];
        my @got      = ( { a => 1, b => 2 }, 'c' );

        ok
            @got
            ~~
            $expected

        => 'Test 2';
    }
}

