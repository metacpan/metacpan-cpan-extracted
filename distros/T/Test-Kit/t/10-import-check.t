use strict;
use warnings;
use lib 't/lib';

use Test::More;

# Import Check - must not already have an import() sub

eval "use MyTest::ImportCheck;";
like(
    $@,
    qr/\QPackage MyTest::ImportCheck already has an import() sub\E/,
    'MyTest::ImportCheck is broken because it already has an import() sub'
);

done_testing();
