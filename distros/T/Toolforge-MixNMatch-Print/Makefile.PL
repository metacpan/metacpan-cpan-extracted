use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Toolforge Mix\'n\'match tool object print routines.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Toolforge-MixNMatch-Print';
perl_version 5.006002;
readme_from 'Print.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0;
requires 'Indent' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Toolforge-MixNMatch-Print/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/Toolforge-MixNMatch-Print';
resources 'repository' => 'git://github.com/michal-josef-spacek/Toolforge-MixNMatch-Print';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Toolforge::MixNMatch::Object' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
