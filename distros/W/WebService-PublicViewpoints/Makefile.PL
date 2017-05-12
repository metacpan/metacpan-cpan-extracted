use inc::Module::Install;
name 'WebService-PublicViewpoints';
all_from 'lib/WebService/PublicViewpoints.pm';

requires
    'Object::Tiny' => '1.06',
    'LWP::Simple'  => 0,
    'URI'          => 0,
    'Text::CSV::Slurp' => 0;

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';

auto_include;
WriteAll;
