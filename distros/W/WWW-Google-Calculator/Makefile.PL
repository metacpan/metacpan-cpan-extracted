use inc::Module::Install;
name 'WWW-Google-Calculator';
all_from 'lib/WWW/Google/Calculator.pm';

requires 'Class::Accessor::Fast' => 0;
requires 'HTML::TokeParser' => 0;
requires 'WWW::Mechanize' => 0;

test_requires 'Test::More' => '0.88';
use_test_base;

auto_set_repository;

WriteAll;
