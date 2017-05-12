use inc::Module::Install;

name            'YAML-Tests';
all_from        'lib/YAML/Tests.pm';

# This module requires `prove` to run `yt`
requires        'Test::Harness' => '2.42';

install_script  'bin/yt';

WriteAll;
