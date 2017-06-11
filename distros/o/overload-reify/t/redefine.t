#!perl

use strict;
use warnings;

use Test::Lib;
use Test2::Bundle::Extended;

{
    package C1;

    use Test2::Bundle::Extended;
    use base 'Parent';

    sub operator_add_assign { }

    # do everything
    use overload::reify ();

    ok(
        dies {
            overload::reify->import;
        },
        "don't overwrite existing method"
    );
}

{
    package C2;

    use Test2::Bundle::Extended;
    use base 'Parent';

    use overload '+=' => sub {};

    # do everything
    use overload::reify ();

    ok(
        dies {
            overload::reify->import;
        },
        "don't overwrite existing operator"
    );
}


{
    package C3;

    use Test2::Bundle::Extended;
    use base 'Parent';

    sub operator_add_assign { }

    # do everything
    use overload::reify ();

    ok(
        lives {
            overload::reify->import( { -redefine => 1 } );
        },
        "overwrite existing method"
    );
}

{
    package C4;

    use Test2::Bundle::Extended;
    use base 'Parent';

    use overload '+=' => sub {};

    # do everything
    use overload::reify ();

    ok(
        lives {
            overload::reify->import( { -redefine => 1 } );
        },
        "overwrite existing operator"
    );
}


done_testing;
