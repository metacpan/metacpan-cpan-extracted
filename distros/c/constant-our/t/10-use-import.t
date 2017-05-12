#!perl -T

use strict;
use warnings;

use Test::More tests => 7;

use constant::our {
                    AAA => 'aaaaaa',
                    BBB => 'bbbbbb',
};

package other_package;
use constant::our { CCC => 'cccccc', };
use constant::our { DDD => 'dddddd', };

package My::Test;
use Test::More;
use constant::our {
                    EEE => 'eeeeee',
                    FFF => 'ffffff',
};
use constant::our qw(AAA BBB CCC DDD);
use constant::our qw(CONSTANT_NO_SET);

is( AAA,             'aaaaaa' );
is( BBB,             'bbbbbb' );
is( CCC,             'cccccc' );
is( DDD,             'dddddd' );
is( EEE,             'eeeeee' );
is( FFF,             'ffffff' );
is( CONSTANT_NO_SET, undef );
