use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'List of unicode blocks.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Unicode-Block-List';
readme_from 'List.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.02;
requires 'Unicode::Block' => 0.02;
requires 'Unicode::UCD' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Unicode-Block-List/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Unicode-Block-List';
resources 'repository' => 'git://github.com/michal-josef-spacek/Unicode-Block-List';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.06;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
