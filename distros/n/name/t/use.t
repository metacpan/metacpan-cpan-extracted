use warnings;
use strict;
use lib 't/lib';

use Scalar::Util 'blessed';
use Test::Fatal;
use Test::More;

BEGIN {
    use_ok 'name', 'foo', alias => 'Foo::Bar::Baz';
}

subtest failures => sub {
    eval 'use name';
    like $@, qr/^name: no name given at .+ line \d+\b/, 'fails w/o name';

    eval "use name 'x'";
    like $@, qr/^name: An 'alias' is required with 'use name' at .+ line \d+\b/,
         'fails w/o package alias';

    eval "use name 'x', useless => 1";
    like $@, qr/^name: An 'alias' is required with 'use name' at .+ line \d+\b/,
         'fails w/o package alias';
};

subtest alias => sub {
    ok __PACKAGE__->can('foo'), 'has an alias name';
    is foo, 'Foo::Bar::Baz', 'right result from name';
    eval "foo('bar')";
    like $@, qr/^Too many arguments for main::foo at .+ line \d+\b/,
        'alias name fails w/ one argument';
    eval "foo(bar => 'baz')";
    like $@, qr/^Too many arguments for main::foo at .+ line \d+\b/,
        'alias name fails w/ many arguments';
};

done_testing;
