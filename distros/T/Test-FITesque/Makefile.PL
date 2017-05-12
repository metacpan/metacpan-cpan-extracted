use inc::Module::Install;

name     'Test-FITesque';
all_from 'lib/Test/FITesque.pm';
author   'Scott McWhirter <konobi@cpan.org>';

build_requires 'Test::More';
build_requires 'Test::Exception';

requires 'Test::Builder' => '0.64_01';
    # output of failure changed at 0.64_01,
requires 'Module::Load';
requires 'Class::Data::Inheritable';

license 'bsd';

auto_install;

WriteAll;

