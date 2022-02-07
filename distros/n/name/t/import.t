use strict;
use lib 't/lib';

use Scalar::Util 'blessed';
use Test::Fatal;
use Test::More;

subtest failures => sub {
    require_ok 'name';

    like exception { name->import }, qr/^name: no name given at .+ line \d+\b/,
         'fails w/o name';
    like exception { name->import('x') },
         qr/^name: An 'alias' is required with 'use name' at .+ line \d+\b/,
         'fails w/o package alias or prefix';
    like exception { name->import('x', autoload => 1) },
         qr/^name: An 'alias' is required with 'use name' at .+ line \d+\b/,
         'fails w/o package alias or prefix';
};

subtest alias => sub {
    ok !__PACKAGE__->can('foo'), 'not has an name';
    ok !exception { name->import('foo', alias => 'Foo::Bar::Baz') },
       'create name';
    ok __PACKAGE__->can('foo'), 'has an name';
    is foo(), 'Foo::Bar::Baz', 'right result from name';
};

done_testing;
