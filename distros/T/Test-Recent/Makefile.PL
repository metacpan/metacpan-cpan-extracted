use inc::Module::Install;

name           'Test-Recent';
all_from       'lib/Test/Recent.pm';

requires       'DateTime'                  => 0;
requires       'DateTime::Format::ISO8601' => 0;
requires       'Time::Duration::Parse'     => 0;
requires       'Test::Builder'             => 0;
requires       'Scalar::Util'              => 0;

# T::B::T before 0.09 breaks with modern perls
build_requires 'Test::Builder::Tester'    => 0.09;

license 'perl';
githubmeta;
author_tests('xt');
readme_from 'lib/Test/Recent.pm';

WriteAll;
