use inc::Module::Install;

name          'UNIVERSAL-filename';
all_from      'lib/UNIVERSAL/filename.pm';
author        'shelling <navyblueshellingford@gmail.com>';
license       'MIT';

# requires    '';

tests         't/*.t';
author_tests  'xt';

test_requires 'Test::More';

auto_set_repository;
auto_include;
WriteAll;
