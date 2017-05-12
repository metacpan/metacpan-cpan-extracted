use inc::Module::Install;
name 'Test-LoadAllModules';
all_from 'lib/Test/LoadAllModules.pm';

requires(
    'Module::Pluggable::Object' => 0,
    'List::MoreUtils'           => 0,
    'Test::More'                => 0,
);

test_requires(
    'Test::More'                   => 0,
    'File::Spec'                => 0,
    'Module::Install::AuthorTests' => 0,
);

use_test_base;
auto_include;
WriteAll;
