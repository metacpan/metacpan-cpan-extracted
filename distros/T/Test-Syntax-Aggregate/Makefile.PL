use inc::Module::Install;

name     'Test-Syntax-Aggregate';
all_from 'lib/Test/Syntax/Aggregate.pm';
author   q{Pavel Shaydo <zwon@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'parent';

auto_install;

WriteAll;

