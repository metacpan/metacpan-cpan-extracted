use inc::Module::Install;

name     'Web-API-Mapper';
all_from 'lib/Web/API/Mapper.pm';
author   q{Cornelius <cornelius.howl@gmail.com>};
license  'perl';

build_requires 'Test::More';

requires 'Path::Dispatcher';
requires 'Any::Moose';

author_tests('xt');

repository 'http://github.com/c9s/Web-API-Mapper';

readme_markdown_from 'lib/Web/API/Mapper.pm';

auto_install;

WriteAll;
