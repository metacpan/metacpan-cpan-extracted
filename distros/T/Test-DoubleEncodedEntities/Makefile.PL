use inc::Module::Install;

name           'Test-DoubleEncodedEntities';
all_from       'lib/Test/DoubleEncodedEntities.pm';

# the interface changed for this at some point
# but I don't know which, so just require the
# eariest version I've tested with that works
# -- may work with older versions
requires       'HTML::TokeParser::Simple' => 3.15;

# T::B::T before 0.09 breaks with modern perls
build_requires 'Test::Builder::Tester' => 0.09;

license 'perl';
githubmeta;
author_tests('xt');

WriteAll;
