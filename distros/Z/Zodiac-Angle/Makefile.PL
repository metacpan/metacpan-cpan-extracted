use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Class for zodiac angle manipulation';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Zodiac-Angle';
perl_version 5.006002;
readme_from 'Angle.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Readonly' => 0;
requires 'Unicode::UTF8' => 0;
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Zodiac-Angle';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Zodiac-Angle';
resources 'repository' => 'git://github.com/michal-josef-spacek/Zodiac-Angle';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Unicode::UTF8' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
