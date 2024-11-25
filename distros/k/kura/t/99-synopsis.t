use Test2::V0;
use Test2::Require::Module 'Type::Tiny', '2.000000';
use Test2::Require::Module 'Data::Checks', '0.09';
use Test2::Require::Module 'Moose', '2.2207';

package MyFoo {
    use Exporter 'import';
    use Data::Checks qw(StrEq);
    use kura Foo => StrEq('foo');
}

package MyBar {
    use Exporter 'import';
    use Types::Standard -types;
    use kura Bar => Str & sub { $_[0] eq 'bar' };
}

package MyBaz {
    use Exporter 'import';
    use Moose::Util::TypeConstraints;
    use kura Baz => subtype as 'Str' => where { $_[0] eq 'baz' };
}

package MyQux {
    use Exporter 'import';
    use kura Qux => sub { $_[0] eq 'qux' };
}

use MyFoo qw(Foo); isa_ok Foo, 'Data::Checks::Constraint';
use MyBar qw(Bar); isa_ok Bar, 'Type::Tiny';
use MyBaz qw(Baz); isa_ok Baz, 'Moose::Meta::TypeConstraint';
use MyQux qw(Qux); isa_ok Qux, 'Type::Tiny'; # CodeRef converted to Type::Tiny

ok  Foo->check('foo') && !Foo->check('bar') && !Foo->check('baz') && !Foo->check('qux');
ok !Bar->check('foo') &&  Bar->check('bar') && !Bar->check('baz') && !Bar->check('qux');
ok !Baz->check('foo') && !Baz->check('bar') &&  Baz->check('baz') && !Baz->check('qux');
ok !Qux->check('foo') && !Qux->check('bar') && !Qux->check('baz') &&  Qux->check('qux');

done_testing;
