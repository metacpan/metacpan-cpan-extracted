# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Class for searching http://galerie-ilonka.cz .';
author 'Michal Špaček <skim@cpan.org>';
license 'bsd';
name 'WWW-Search-GalerieIlonkaCZ';
readme_from 'GalerieIlonkaCZ.pm';
requires 'Encode' => 0,
requires 'LWP::UserAgent' => 0;
requires 'Readonly' => 0;
requires 'Web::Scraper' => 0;
requires 'WWW::Search' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=WWW-Search-GalerieIlonkaCZ';
resources 'homepage' => 'https://github.com/tupinek/WWW-Search-GalerieIlonkaCZ';
resources 'repository' => 'git://github.com/tupinek/WWW-Search-GalerieIlonkaCZ';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.08;
test_requires 'Test::More' => 0;
test_requires 'Test::Pod' => 0;
test_requires 'Test::Pod::Coverage' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
