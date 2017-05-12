use inc::Module::Install;
name 'XML-FOAF';
all_from 'lib/XML/FOAF.pm';
readme_from 'lib/XML/FOAF.pm';

requires 'RDF::Core';
requires 'URI';

test_requires 'Test::More';

use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;