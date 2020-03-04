use lib '.';
use inc::Module::Install;

name           'Test-utf8';
all_from       'lib/Test/utf8.pm';

# We only need a copy of Test::Builder to run
requires       'Test::Builder'         => 0;

# T::B::T before 0.09 breaks with modern perls
# (this is core, but doesn't ship with 5.7.3)
build_requires 'Test::Builder::Tester' => 0.09;

# We need proper unicode handling
perl_version '5.007003';

license 'perl';
githubmeta;
author_tests('xt');
readme_from 'lib/Test/utf8.pm';

repository 'https://github.com/2shortplanks/Test-utf8';

WriteAll;
