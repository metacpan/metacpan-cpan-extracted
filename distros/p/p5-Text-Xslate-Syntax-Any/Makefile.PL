use inc::Module::Install;
name 'Text-Xslate-Syntax-Any';
all_from 'lib/Text/Xslate/Syntax/Any.pm';

requires 'Text::Xslate' => 0;

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
