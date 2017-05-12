use 5.007003; # the earlier perl doesn't have utf8 capabilities
use inc::Module::Install;

name     'Test-More-UTF8';
all_from 'lib/Test/More/UTF8.pm';
author   'Mons Anderson <mons@cpan.org>';
license  'perl';

build_requires 'Test::More';

auto_install;
auto_provides;

WriteAll;
