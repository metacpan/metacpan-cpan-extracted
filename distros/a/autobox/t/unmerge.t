#!/usr/bin/env perl

use strict;
use warnings;

use Test::Fatal qw(exception);
use Test::More tests => 40;

use vars qw($string $string_error $unblessed_error);

BEGIN {
    $string = 'Hello, world!';
    $string_error = qr{^Can't locate object method "test" via package "$string"};
    $unblessed_error = qr{^Can't call method "test" on unblessed reference\b};

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
    like(exception { $string->test() }, $string_error);
}

like(exception { $string->test() }, $string_error);

use autobox SCALAR => 'Scalar1';

BEGIN { is($string->test(), 'Scalar1') }

is($string->test(), 'Scalar1');

no autobox qw(SCALAR);

BEGIN {
    like(exception { $string->test() }, $string_error);
}

like(exception { $string->test() }, $string_error);

{
    # multiple unimports in a nested scope before "use autobox"
    no autobox;
    no autobox;
    no autobox;

    use autobox SCALAR => 'Scalar2';

    BEGIN { is($string->test(), 'Scalar2') }

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
    is(''->test(), 'SCALAR');
    is([]->test(), 'ARRAY');
    is({}->test(), 'HASH');
    is(sub {}->test(), 'CODE');
}

is(''->test(), 'SCALAR');
is([]->test(), 'ARRAY');
is({}->test(), 'HASH');
is(sub {}->test(), 'CODE');

no autobox qw(SCALAR);

BEGIN {
    like(exception { $string->test() }, $string_error);
}

like(exception { $string->test() }, $string_error);

BEGIN {
    is([]->test(), 'ARRAY');
    is({}->test(), 'HASH');
    is(sub {}->test(), 'CODE');
}

is([]->test(), 'ARRAY');
is({}->test(), 'HASH');
is(sub {}->test(), 'CODE');

no autobox qw(ARRAY HASH);

BEGIN {
    like(exception { $string->test() }, $string_error);
    like(exception { []->test() }, $unblessed_error);
    like(exception { {}->test() }, $unblessed_error);
}

like(exception { $string->test() }, $string_error);
like(exception { []->test() }, $unblessed_error);
like(exception { {}->test() }, $unblessed_error);

BEGIN { is(sub {}->test(), 'CODE') }

is(sub {}->test(), 'CODE');

no autobox;

BEGIN {
    like(exception { $string->test() }, $string_error);
    like(exception { []->test() }, $unblessed_error);
    like(exception { {}->test() }, $unblessed_error);
    like(exception { sub {}->test() }, $unblessed_error);
}

like(exception { $string->test() }, $string_error);
like(exception { []->test() }, $unblessed_error);
like(exception { {}->test() }, $unblessed_error);
like(exception { sub {}->test() }, $unblessed_error);

use autobox; # try to cause havoc with a stray trailing "use autobox"
