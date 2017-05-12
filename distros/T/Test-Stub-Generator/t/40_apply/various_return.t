use strict;
use warnings;

use Test::More;
use Test::Stub::Generator qw(make_subroutine);

my $some_method = make_subroutine(
    [
        { expects => [0], return => [0] },
        { expects => [0], return => [0, 1] },
        { expects => [0], return => { a => 1 } },
        { expects => [0], return => [ [0], [0, 1] ] },
        { expects => [0], return => [ { a => 1 }, { b => 2 } ] },
    ]

);

is_deeply( &$some_method(0), [ 0 ], 'sub return are as You expected'  );
is_deeply( &$some_method(0), [ 0, 1 ], 'sub return are as You expected'  );
is_deeply( &$some_method(0), { a => 1 }, 'sub return are as You expected'  );
is_deeply( &$some_method(0), [ [0], [ 0, 1 ] ], 'sub return are as You expected'  );
is_deeply( &$some_method(0), [ { a => 1 }, { b => 2 } ], 'sub return are as You expected'  );

done_testing;
