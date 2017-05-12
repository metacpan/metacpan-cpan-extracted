# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Class for searching http://melcer.cz .';
author 'Michal Špaček <skim@cpan.org>';
license 'bsd';
name 'WWW-Search-MelcerCZ';
readme_from 'MelcerCZ.pm';
requires 'Encode' => 0,
requires 'LWP::UserAgent' => 0;
requires 'Readonly' => 0;
requires 'Text::Iconv' => 0;
requires 'Web::Scraper' => 0;
requires 'WWW::Search' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=WWW-Search-MelcerCZ';
resources 'homepage' => 'https://github.com/tupinek/WWW-Search-MelcerCZ';
resources 'repository' => 'git://github.com/tupinek/WWW-Search-MelcerCZ';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.01;
test_requires 'Test::More' => 0;
test_requires 'Test::Pod' => 0;
test_requires 'Test::Pod::Coverage' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
