#!perl -T

use strict;
use warnings;

use Test::More tests => 10;

my ( $warn, $die );

sub clean
{
    ( $warn, $die ) = ( 0, 0 );
}

clean();

$SIG{__WARN__} = sub { ++$warn };
$SIG{__DIE__}  = sub { ++$die };

# Ничего не должно произойти
eval 'use constant::our { AAA => 1 }';
is( $warn, 0 );
is( $die,  0 );
clean();

# Повторная декларация
eval 'use constant::our { BBB => 1 }';
eval 'use constant::our { BBB => 1 }';

is( $warn, 1 );
is( $die,  0 );
clean();

# Разные значения
eval 'use constant::our { CCC => 1 }';
is( $warn, 0 );
is( $die,  0 );
eval 'use constant::our { CCC => 0 }';
is( $warn, 0 );
is( $die,  2 );
clean();

# Зарезервированное слово
eval 'use constant::our { import => 1 }';

is( $warn, 0 );
is( $die,  2 );
clean();
