use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Stub::Generator qw(make_subroutine);

my $some_method = make_subroutine(
    [
        { expects => [0], return => sub { (0, 1) } },
        { expects => [0], return => sub { (a => 1) } },
        { expects => [0], return => sub { sub {} }  },
    ]
);


cmp_deeply( [&$some_method(0)], [(0, 1)], 'sub return are as You expected' );
cmp_deeply( [&$some_method(0)], [(a => 1)], 'sub return are as You expected' );
ok( ref &$some_method(0) eq 'CODE', 'sub return are as You expected' );

done_testing;
