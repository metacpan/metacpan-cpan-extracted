# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'List of unicode blocks.';
author 'Michal Špaček <skim@cpan.org>';
license 'bsd';
name 'Unicode-Block-List';
readme_from 'List.pm';
requires 'Class::Utils' => 0.02;
requires 'Unicode::Block' => 0.02;
requires 'Unicode::UCD' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Unicode-Block-List';
resources 'homepage' => 'https://github.com/tupinek/Unicode-Block-List';
resources 'repository' => 'git://github.com/tupinek/Unicode-Block-List';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.06;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Pod' => 0;
test_requires 'Test::Pod::Coverage' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
