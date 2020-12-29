use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Toolforge Mix\'n\'match tool diff.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Toolforge-MixNMatch-Diff';
perl_version 5.010;
readme_from 'Diff.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0;
requires 'Toolforge::MixNMatch::Object' => 0.01;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Toolforge-MixNMatch-Diff/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/Toolforge-MixNMatch-Diff';
resources 'repository' => 'git://github.com/michal-josef-spacek/Toolforge-MixNMatch-Diff';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
