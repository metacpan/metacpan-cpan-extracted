#!perl
use strict;
use warnings;
use Test::More;
our $TESTS;

my $val;

BEGIN { $TESTS++ }
{
    use overload::eval;
    $val = eval 1;
    if ($@) {
        fail($@);
    }
    else {
        is( $val, 'eval(1)', 'hook to &eval' );
    }
}

BEGIN { $TESTS++ }
{
    use overload::eval 'foo';
    $val = eval 2;
    if ($@) {
        fail($@);
    }
    else {
        is( $val, 'foo(2)', 'hook to &foo' );
    }
}

BEGIN { $TESTS++ }
{
    undef $val;
    $val = eval 3;
    if ($@) {
        fail($@);
    }
    else {
        is( $val, 3, 'no hook' );
    }
}

BEGIN { $TESTS++ }
{
    no overload::eval;
    $val = eval 4;
    if ($@) {
        fail($@);
    }
    else {
        is( $val, 4, 'Disable hook 1' );
    }
}

BEGIN { $TESTS++ }
{
    use overload::eval 'foo';
    no overload::eval;
    $val = eval 5;
    if ($@) {
        fail($@);
    }
    else {
        is( $val, 5, 'Disable hook 2' );
    }
}

BEGIN { $TESTS += 5 }
{
    use overload::eval 'wantarray';

    my $context;
    is_deeply( [ eval '(2,3,4,5)' ], [ 2 .. 5 ], 'list context 1' );
    is( $context, 'list', 'list context 2' );
    is_deeply( [ scalar eval 'no warnings q[void]; (2,3,4,5)' ],
        [5], 'scalar context 1' );
    is( $context, 'scalar', 'scalar context 2' );

    eval '(2,3,4,5)';
    is( $context, 'void', 'void context' );

    sub wantarray {
        no overload::eval;
        $context =
              CORE::wantarray          ? 'list'
            : defined(CORE::wantarray) ? 'scalar'
            :                            'void';
        return eval shift;
    }
}

sub eval {"eval(@_)"}
sub foo  {"foo(@_)"}
BEGIN { plan( tests => $TESTS ) }
