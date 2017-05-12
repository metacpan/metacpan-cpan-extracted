#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 40;

use vars qw($string $string_error $unblessed_error);

BEGIN {
    $string = 'Hello, world!';
    $string_error = qr{Can't locate object method "test" via package "$string"};
    $unblessed_error = qr{Can't call method "test" on unblessed reference\b};

    no strict 'refs';

    for my $name (qw(SCALAR ARRAY HASH CODE Scalar1 Scalar2)) {
        *{"$name\::test"} = sub { $name };
    }
}

# multiple unimports at the top level
no autobox;
no autobox;
no autobox;

BEGIN {
    eval { $string->test() };
    ok ($@ && ($@ =~ /^$string_error/), 'test 1');
}

eval { $string->test() };
ok ($@ && ($@ =~ /^$string_error/). 'test ');

use autobox SCALAR => 'Scalar1';

BEGIN { is($string->test(), 'Scalar1', 'test 2') }

is($string->test(), 'Scalar1', 'test ');

no autobox qw(SCALAR);

BEGIN {
    eval { $string->test() };
    ok ($@ && ($@ =~ /^$string_error/), 'test 3');
}

eval { $string->test() };
ok ($@ && ($@ =~ /^$string_error/), 'test ');

{
    # multiple unimports in a nested scope before "use autobox"
    no autobox;
    no autobox;
    no autobox;

    use autobox SCALAR => 'Scalar2';

    BEGIN { is($string->test(), 'Scalar2', 'test 4') }

    is($string->test(), 'Scalar2');

    # multiple unimports in a nested scope after "use autobox"
    no autobox;
    no autobox;
    no autobox;

    # attempt to sow confusion
    use autobox;

    {
        no autobox;
        use autobox;
        use autobox SCALAR => 'Fake1';
        no autobox;
        no autobox 'SCALAR';
        use autobox SCALAR => 'Fake2';
    }

    no autobox;

    use autobox;
    no autobox;
}

# unmatched "no autobox"
{
    {
        use autobox;
    }

    no autobox;
}

use autobox;

BEGIN {
    is(''->test(), 'SCALAR', 'test 5');
    is([]->test(), 'ARRAY', 'test 6');
    is({}->test(), 'HASH', 'test 7');
    is(sub {}->test(), 'CODE', 'test 8');
}

is(''->test(), 'SCALAR');
is([]->test(), 'ARRAY');
is({}->test(), 'HASH');
is(sub {}->test(), 'CODE');

no autobox qw(SCALAR);

BEGIN {
    eval { $string->test() };
    ok ($@ && ($@ =~ /^$string_error/), 'test 9');
}

eval { $string->test() };
ok ($@ && ($@ =~ /^$string_error/));

BEGIN {
    is([]->test(), 'ARRAY', 'test 10');
    is({}->test(), 'HASH', 'test 11');
    is(sub {}->test(), 'CODE', 'test 12');
}

is([]->test(), 'ARRAY');
is({}->test(), 'HASH');
is(sub {}->test(), 'CODE');

no autobox qw(ARRAY HASH);

BEGIN {
    eval { $string->test() };
    ok ($@ && ($@ =~ /^$string_error/), 'test 13');
    eval { []->test() };
    ok ($@ && ($@ =~ /^$unblessed_error/), 'test 14');
    eval { {}->test() };
    ok ($@ && ($@ =~ /^$unblessed_error/), 'test 15');
}

eval { $string->test() };
ok ($@ && ($@ =~ /^$string_error/));
eval { []->test() };
ok ($@ && ($@ =~ /^$unblessed_error/));
eval { {}->test() };
ok ($@ && ($@ =~ /^$unblessed_error/));

BEGIN { is(sub {}->test(), 'CODE', 'test 16') }

is(sub {}->test(), 'CODE');

no autobox;

BEGIN {
    eval { $string->test() };
    ok ($@ && ($@ =~ /^$string_error/), 'test 17');
    eval { []->test() };
    ok ($@ && ($@ =~ /^$unblessed_error/), 'test 18');
    eval { {}->test() };
    ok ($@ && ($@ =~ /^$unblessed_error/), 'test 19');
    eval { sub {}->test() };
    ok ($@ && ($@ =~ /^$unblessed_error/), 'test 20');
}

eval { $string->test() };
ok ($@ && ($@ =~ /^$string_error/));
eval { []->test() };
ok ($@ && ($@ =~ /^$unblessed_error/));
eval { {}->test() };
ok ($@ && ($@ =~ /^$unblessed_error/));
eval { sub {}->test() };
ok ($@ && ($@ =~ /^$unblessed_error/));

use autobox; # try to cause havoc with a stray trailing "use autobox"
