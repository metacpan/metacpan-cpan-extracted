use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Wikibase data types.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Wikibase-Datatype';
perl_version 5.006002;
readme_from 'Datatype.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Error::Pure' => 0.15;
requires 'Exporter' => 0;
requires 'Mo' => 0;
requires 'Mo::utils' => 0.03;
requires 'List::MoreUtils' => 0;
requires 'Readonly' => 0;
requires 'Unicode::UTF8' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Wikibase-Datatype/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/Wikibase-Datatype';
resources 'repository' => 'git://github.com/michal-josef-spacek/Wikibase-Datatype';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::MockObject' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
