use inc::Module::Install;

name 'Test-Mocha-PhantomJS';
all_from 'lib/Test/Mocha/PhantomJS.pm';
readme_from 'lib/Test/Mocha/PhantomJS.pm';
license 'perl';

requires 'Scope::Guard';
requires 'Test::TCP';
test_requires 'Plack';
test_requires 'Plack::Middleware::DirIndex';

auto_include;
auto_install;

WriteAll;
