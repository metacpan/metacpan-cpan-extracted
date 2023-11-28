use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Ascii output of unicode block.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Unicode-Block-Ascii';
readme_from 'Ascii.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.02;
requires 'Error::Pure' => 0.16;
requires 'Readonly' => 0;
requires 'Text::UnicodeBox' => 0;
requires 'Text::UnicodeBox::Control' => 0;
requires 'Unicode::Block' => 0.02;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Unicode-Block-Ascii/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Unicode-Block-Ascii';
resources 'repository' => 'git://github.com/michal-josef-spacek/Unicode-Block-Ascii';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.06;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
