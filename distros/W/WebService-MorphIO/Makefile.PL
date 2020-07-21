use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Perl class to communication with morph.io.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'WebService-MorphIO';
readme_from 'MorphIO.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.05;
requires 'Error::Pure' => 0.16;
requires 'IO::Barf' => 0.07;
requires 'LWP::Simple' => 0;
requires 'URI' => 0;
requires 'URI::Escape' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=WebService-MorphIO';
resources 'homepage' => 'https://github.com/michal-josef-spacek/WebService-MorphIO';
resources 'repository' => 'git://github.com/michal-josef-spacek/WebService-MorphIO';
test_requires 'English' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
