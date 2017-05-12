use strict;
use warnings;

use Test::More tests => 52;
use UNIVERSAL::isa 'isa';

{
    package Foo;
    sub isa { 1 }
}

{
    package Bar;
}

{
    package Gorch;
    sub isa
    {
        my ($self, $class) = @_;
        $self->SUPER::isa($class) unless $class eq 'Glab';
    }
}

{
    package Baz;
    sub isa
    {
        my ($self, $class) = @_;
        UNIVERSAL::isa($self, $class) unless $class eq 'Glab';
    }
}

my ($f, $b, $g, $x) = map { bless [], $_ } qw( Foo Bar Gorch Baz );

{
    my $warning = '';
    local $SIG{__WARN__} = sub { $warning = shift };

    ok( !isa( undef, 'Foo' ), 'undef isa nothing' );
    is( $warning, '', 'not warning by default' );

    ok(  isa( [], 'ARRAY' ), '[] is an array ref' );
    is( $warning, '', 'not warning by default' );

    $warning = '';
    ok(  isa( $b, 'Bar'   ), 'bar is a Bar'       );
    is( $warning, '', 'not warning by default' );

    $warning = '';
    ok(  isa( $f, 'Foo'   ), 'foo is a Foo'       );
    like( $warning, qr/as a function.+basic.t/, '... warning by default' );

    $warning = '';
    ok( !isa( $b, 'Zlap'  ), 'bar is not Zlap'    );
    is( $warning, '', 'not warning by default' );

    $warning = '';
    ok(  isa( $f, 'Zlap'  ), 'neither is Foo'     );
    like( $warning, qr/as a function.+basic.t/, '... warning by default' );

    $warning = '';
    ok(  isa( $g, 'Gorch' ), 'Gorch is itself'    );
    like( $warning, qr/as a function.+basic.t/, '... warning by default' );

    $warning = '';
    ok( !isa( $g, 'Zlap'  ), 'gorch is not Zlap'  );
    like( $warning, qr/as a function.+basic.t/, '... warning by default' );

    $warning = '';
    ok(  isa( $g, 'Glab'  ), '... it is dung'     );
    like( $warning, qr/as a function.+basic.t/, '... warning by default' );

    $warning = '';
    ok(  isa( $x, 'Baz'   ), 'Baz is itself'      );
    like( $warning, qr/as a function.+basic.t/, '... warning by default' );

    $warning = '';
    ok( !isa( $x, 'Zlap'  ), 'baz is not Zlap'    );
    like( $warning, qr/as a function.+basic.t/, '... warning by default' );

    $warning = '';
    ok(  isa( $x, 'Glab'  ), 'it is dung'         );
    like( $warning, qr/as a function.+basic.t/, '... warning by default' );
}

{
    use warnings 'UNIVERSAL::isa';

    my $warning = '';
    local $SIG{__WARN__} = sub { $warning = shift };

    ok( !isa( undef, 'Foo' ), 'undef isa nothing' );
    is( $warning, '', 'not warning by default' );

    $warning = '';
    ok( isa( {},     'HASH' ),   'hash reference isa HASH'       );
    is( $warning,    '',         '... and no warning by default' );

    $warning = '';
    ok( isa( [],     'ARRAY' ),  'array reference isa ARRAY'     );
    is( $warning,    '',         '... and no warning by default' );

    $warning = '';
    ok( isa( sub {}, 'CODE' ),   'code reference isa CODE'       );
    is( $warning,    '',         '... and no warning by default' );

    $warning = '';
    ok( isa( \my $a, 'SCALAR' ), 'scalar reference isa SCALAR'   );
    is( $warning,    '',         '... and no warning by default' );

    $warning = '';
    ok( isa( qr//,   'Regexp' ), 'regexp reference isa Regexp'   );
    is( $warning,    '',         '... and no warning by default' );

    $warning = '';
    ok( isa( \local *FOO, 'GLOB' ), 'glob reference isa GLOB'     );
    is( $warning, '', '... and no warning by default' );
}

{
    use warnings 'UNIVERSAL::isa';
    UNIVERSAL::isa::->import( 'verbose' );

    my $warning = '';
    local $SIG{__WARN__} = sub { $warning = shift };

    ok( !isa( undef, 'Foo' ), 'undef isa nothing' );
    like( $warning, qr/Called.+as a function.+on invalid invocant.+basic.t/,
        '... warning in verbose mode' );

    ok( isa( {},     'HASH' ),      'hash reference isa HASH'     );
    like( $warning, qr/Called.+as a function.+reftyp.+basic.t/,
        '... warning in verbose mode' );

    $warning = '';
    ok( isa( [],     'ARRAY' ),     'array reference isa ARRAY'   );
    like( $warning, qr/Called.+as a function.+reftyp.+basic.t/,
        '... warning in verbose mode' );

    $warning = '';
    ok( isa( sub {}, 'CODE' ),      'code reference isa CODE'     );
    like( $warning, qr/Called.+as a function.+reftyp.+basic.t/,
        '... warning in verbose mode' );

    $warning = '';
    ok( isa( \my $a, 'SCALAR' ),    'scalar reference isa SCALAR' );
    like( $warning, qr/Called.+as a function.+reftyp.+basic.t/,
        '... warning in verbose mode' );

    $warning = '';
    ok( isa( qr//, 'Regexp' ),      'regexp reference isa Regexp' );
    like( $warning, qr/Called.+as a functio.+basic.t/,
        '... warning in verbose mode' );

    $warning = '';
    ok( isa( \local *FOO, 'GLOB' ), 'glob reference isa GLOB'     );
    like( $warning, qr/Called.+as a function.+reftyp.+basic.t/,
        '... warning in verbose mode' );
}
