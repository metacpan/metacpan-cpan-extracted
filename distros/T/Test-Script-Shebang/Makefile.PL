use inc::Module::Install;
name 'Test-Script-Shebang';
all_from 'lib/Test/Script/Shebang.pm';

test_requires 'Test::More', 0.96;
test_requires 'Test::Requires', 0.06;

tests_recursive 't';
author_tests 'xt';

auto_include();
auto_set_repository();

WriteAll;
