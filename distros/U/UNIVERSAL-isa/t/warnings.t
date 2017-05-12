use strict;
use warnings;

use Test::More tests => 12;
use UNIVERSAL::isa 'isa';

use warnings 'UNIVERSAL::isa';

{
    package Foo;

    sub isa { 1 }
}

{
    package Bar;
}

my $foo = bless {}, 'Foo';
my $bar = bless {}, 'Bar';

{
    my $warning          = '';
    local $SIG{__WARN__} = sub { $warning = shift };

    UNIVERSAL::isa( $foo, 'Foo' );
    like( $warning, qr/Called UNIVERSAL::isa\(\) as a function.+warnings.t/,
        'U::i should warn by default when redirecting to overridden method' );

    $warning = '';
    UNIVERSAL::isa( $foo, 'Bar' );
    like( $warning, qr/Called UNIVERSAL::isa\(\) as a function.+warnings.t/,
        '... even if isa() would return false' );

    $warning = '';
    $foo->isa( 'Bar' );
    is( $warning, '', 'No warnings when called properly, as a method' );

    $warning = '';
    UNIVERSAL::isa( $bar, 'Foo' );
    is( $warning, '', '... but not by default on default isa()' );

    $warning = '';
    UNIVERSAL::isa( $bar, 'Bar' );
    is( $warning, '', '... even when it would return false' );

    $warning = '';
    $bar->isa( 'Bar' );
    is( $warning, '', 'No warnings when called properly, as a method' );
}

{
    UNIVERSAL::isa::->import( 'verbose' );

    my $warning          = '';
    local $SIG{__WARN__} = sub { $warning = shift };

    UNIVERSAL::isa( $foo, 'Foo' );
    like( $warning, qr/Called UNIVERSAL::isa\(\) as a function.+warnings.t/,
        'U::i should warn when verbose when redirecting to overridden method' );

    $warning = '';
    UNIVERSAL::isa( $foo, 'Bar' );
    like( $warning, qr/Called UNIVERSAL::isa\(\) as a function.+warnings.t/,
        '... even if isa() would return false' );

    $warning = '';
    $foo->isa( 'Bar' );
    is( $warning, '', 'No warnings when called properly, as a method' );

    $warning = '';
    UNIVERSAL::isa( $bar, 'Foo' );
    like( $warning, qr/Called UNIVERSAL::isa\(\) as a function.+warnings.t/,
        '... and on default isa()' );

    $warning = '';
    UNIVERSAL::isa( $bar, 'Bar' );
    like( $warning, qr/Called UNIVERSAL::isa\(\) as a function.+warnings.t/,
        '... even when it would return false' );

    TODO: {
        local $TODO = 'no apparent way of distinguishing between being called as a function and a method';
        $warning = '';
        $bar->isa( 'Bar' );
        is( $warning, '', 'No warnings when called properly, as a method' );
    }
}
