use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Perl class for delays between frames generation.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
license 'bsd';
name 'Video-Delay';
readme_from 'Delay.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'English' => 0;
requires 'Error::Pure' => 0.11;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Video-Delay';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Video-Delay';
resources 'repository' => 'git://github.com/michal-josef-spacek/Video-Delay';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.17;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.07';

# Run.
WriteAll();
