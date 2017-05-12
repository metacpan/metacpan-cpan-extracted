use inc::Module::Install;
all_from 'lib/lib/require/all.pm';
readme_from('lib/lib/require/all.pm');
build_requires 'Test::More', 0.88;
test_requires 'Test::Requires';
auto_set_repository();
auto_provides;
WriteAll;
