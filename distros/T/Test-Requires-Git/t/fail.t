use strict;
use warnings;
use Test::More;

use Test::Requires::Git -nocheck;

plan tests => 7;

ok( !eval { test_requires_git 'zlonk' }, 'odd specification' );
like(
    $@,
    qr/^zlonk does not look like a Git version /,
    '... expected error message'
);

ok( !eval { test_requires_git 'zlonk' => 'bam' }, 'bad specification' );
like(
    $@,
    qr/^Unknown git specification 'zlonk' /,
    '... expected error message'
);

ok( !eval { test_requires_git skip => 2, skip => 3 }, 'duplicate argument' );
like(
    $@,
    qr/^Duplicate 'skip' argument /,
    '... expected error message'
);

$ENV{PATH} = '';
test_requires_git;
fail( 'cannot happen');
