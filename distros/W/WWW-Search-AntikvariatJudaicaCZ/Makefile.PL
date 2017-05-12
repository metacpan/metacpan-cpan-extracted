# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Class for searching http://www.antikvariat-judaica.cz/ .';
author 'Michal Spacek <skim@cpan.org>';
license 'bsd';
name 'WWW-Search-AntikvariatJudaicaCZ';
readme_from 'AntikvariatJudaicaCZ.pm';
requires 'LWP::UserAgent' => 0;
requires 'Readonly' => 0;
requires 'Web::Scraper' => 0;
requires 'WWW::Search' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=WWW-Search-AntikvariatJudaicaCZ';
resources 'homepage' => 'https://github.com/tupinek/'.
	'WWW-Search-AntikvariatJudaicaCZ';
resources 'repository' => 'git://github.com/tupinek/'.
	'WWW-Search-AntikvariatJudaicaCZ';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.01;
test_requires 'Test::More' => 0;
test_requires 'Test::Pod' => 0;
test_requires 'Test::Pod::Coverage' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
