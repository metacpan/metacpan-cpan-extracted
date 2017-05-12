# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Ascii output of unicode block.';
author 'Michal Špaček <skim@cpan.org>';
license 'bsd';
name 'Unicode-Block-Ascii';
readme_from 'Ascii.pm';
requires 'Class::Utils' => 0.02;
requires 'Error::Pure' => 0.16;
requires 'Readonly' => 0;
requires 'Text::UnicodeBox' => 0;
requires 'Text::UnicodeBox::Control' => 0;
requires 'Unicode::Block' => 0.02;
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Unicode-Block-Ascii';
resources 'homepage' => 'https://github.com/tupinek/Unicode-Block-Ascii';
resources 'repository' => 'git://github.com/tupinek/Unicode-Block-Ascii';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.06;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Pod' => 0;
test_requires 'Test::Pod::Coverage' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
