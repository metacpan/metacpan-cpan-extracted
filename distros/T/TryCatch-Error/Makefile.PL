use inc::Module::Install;

name     'TryCatch-Error';
all_from 'lib/TryCatch/Error.pm';
author   'Pedro Figueiredo <me@pedrofigueiredo.org>';
license  'perl';

build_requires  'Test::More';

requires        'Moose';
requires        'MooseX::FollowPBP';

auto_install;

WriteAll;

