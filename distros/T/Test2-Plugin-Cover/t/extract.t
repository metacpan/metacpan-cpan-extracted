use Test2::Plugin::Cover;
use Test2::V0 -target => 'Test2::Plugin::Cover';

is( $CLASS->extract('(eval 1)'), undef, "No file to extract from (eval 1)");
is( $CLASS->extract('(eval 123)'), undef, "No file to extract from (eval 123)");
is( $CLASS->extract('(eval 0)'), undef, "No file to extract from (eval 0)");
is( $CLASS->extract('(eval)'), undef, "No file to extract from (eval)");

is( $CLASS->extract(__FILE__), __FILE__, "Can find the current file");

is($CLASS->extract($_), 'foo/bar.pm', "extracted from '$_'") for (
    # Stuff Moose sometimes spits out
    'defined at foo/bar.pm line 123',
    'declared at foo/bar.pm line 123',
    'defined in foo/bar.pm line 123',
    'declared in foo/bar.pm line 123',
    'defined at foo/bar.pm at line 123',
    'declared at foo/bar.pm at line 123',
    'defined in foo/bar.pm at line 123',
    'declared in foo/bar.pm at line 123',

    # More stuff Moose does
    '(eval 123)[foo/bar.pm:123]',
    'fasdf (foo/bar.pm) at line 123',
    'fasdf (foo/bar.pm) line 123',

    # 2 arg open
    '>>foo/bar.pm',
    '>foo/bar.pm',
    '|foo/bar.pm',
    '<foo/bar.pm',
    '>+foo/bar.pm',
    '>-foo/bar.pm',
    '<+foo/bar.pm',
    '<-foo/bar.pm',
);

is($CLASS->extract('declared in (eval 123) line 123'), undef, "Nothing to extract");
is($CLASS->extract('foo ()'), undef, "Nothing to extract");
is($CLASS->extract('[foo]'), undef, "Nothing to extract");
is($CLASS->extract('foo.pm foo->bar'), undef, "Nothing to extract");
is($CLASS->extract('|eval|'), undef, "Nothing to extract");
is($CLASS->extract('eval'), undef, "Nothing to extract");
is($CLASS->extract(' eval '), undef, "Nothing to extract");

done_testing;
