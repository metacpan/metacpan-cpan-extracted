use strict;
use warnings;

use Test::More;

{
    package Foo;
    use Scalar::Util qw(blessed);
    sub mysub { }
    use namespace::autoclean -except => ['blessed'];
}

ok( Foo->can('mysub'), 'Foo has mysub method' );
ok( Foo->can('blessed'), 'Foo has blessed sub - passed to -except as arrayref' );

{
    package Bar;
    use Scalar::Util qw(blessed);
    sub mysub { }
    use namespace::autoclean -except => 'blessed';
}

ok( Bar->can('mysub'), 'Bar has mysub method' );
ok( Bar->can('blessed'), 'Bar has blessed sub - passed to -except as string' );

{
    package Baz;
    use Scalar::Util qw(blessed);
    sub mysub { }
    use namespace::autoclean -except => qr/bless/;
}

ok( Baz->can('mysub'), 'Baz has mysub method' );
ok( Baz->can('blessed'), 'Baz has blessed sub - passed to -except as regex' );

done_testing();
