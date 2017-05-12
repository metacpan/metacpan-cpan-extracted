# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Class for searching http://antikvariat11.cz .';
author 'Michal Špaček <skim@cpan.org>';
license 'bsd';
name 'WWW-Search-Antikvariat11CZ';
readme_from 'Antikvariat11CZ.pm';
requires 'HTTP::Cookies' => 0;
requires 'LWP::UserAgent' => 0;
requires 'Readonly' => 0;
requires 'Web::Scraper' => 0;
requires 'WWW::Search' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=WWW-Search-Antikvariat11CZ';
resources 'homepage' => 'https://github.com/tupinek/WWW-Search-Antikvariat11CZ';
resources 'repository' => 'git://github.com/tupinek/WWW-Search-Antikvariat11CZ';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.01;
test_requires 'Test::More' => 0;
test_requires 'Test::Pod' => 0;
test_requires 'Test::Pod::Coverage' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
