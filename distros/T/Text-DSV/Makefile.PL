use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'DSV parser and serializer.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Text-DSV';
readme_from 'DSV.pm';
recursive_author_tests('xt');
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Text-DSV/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Text-DSV';
resources 'repository' => 'git://github.com/michal-josef-spacek/Text-DSV';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.11';

# Run.
WriteAll();
