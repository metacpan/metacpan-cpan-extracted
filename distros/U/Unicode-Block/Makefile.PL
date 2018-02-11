use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Class for unicode block manipulation.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Unicode-Block';
readme_from 'Block.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.06;
requires 'Error::Pure' => 0.13;
requires 'Text::CharWidth' => 0;
requires 'Unicode::Char' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Unicode-Block';
resources 'homepage' => 'https://github.com/tupinek/Unicode-Block';
resources 'repository' => 'git://github.com/tupinek/Unicode-Block';
test_requires 'Encode' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.13;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.07';

# Run.
WriteAll();
