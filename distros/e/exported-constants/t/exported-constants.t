use strict;
use warnings;

use Test::More;

{
    package TestExporter;

    use Module::Loaded;
    BEGIN { mark_as_loaded(__PACKAGE__); }

    use exported::constants
        SOME_CONSTANT => 3,
        ANOTHER_CONSTANT => 'This is a string',
    ;

    sub helper_sub { 'This does something else' }
}

{
    package TestImporter;

    use TestExporter;
}

ok(defined(&TestImporter::SOME_CONSTANT), 'SOME_CONSTANT is defined');
ok(defined(&TestImporter::ANOTHER_CONSTANT), 'ANOTHER_CONSTANT is defined');
ok(!defined(&TestImporter::helper_sub), 'helper_sub is not exported');

is(eval { TestImporter::SOME_CONSTANT() }, 3, '. . . and SOME_CONSTANT has the right value');
is(eval { TestImporter::ANOTHER_CONSTANT() }, 'This is a string', '. . . and ANOTHER_CONSTANT has the right value');

done_testing();
