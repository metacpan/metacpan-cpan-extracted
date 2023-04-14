use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Wikibase cache backend to local static basic ids (units, common properties).';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Wikibase-Cache-Backend-Basic';
perl_version 5.006002;
readme_from 'Basic.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Error::Pure' => 0.15;
requires 'Text::DSV' => 0;
requires 'Wikibase::Cache::Backend' => 0.03;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Wikibase-Cache-Backend-Basic/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/Wikibase-Cache-Backend-Basic';
resources 'repository' => 'git://github.com/michal-josef-spacek/Wikibase-Cache-Backend-Basic';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
