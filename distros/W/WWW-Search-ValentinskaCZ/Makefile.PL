# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Class for searching http://valentinska.cz .';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'WWW-Search-ValentinskaCZ';
readme_from 'ValentinskaCZ.pm';
recursive_author_tests('xt');
requires 'Encode' => 0;
requires 'LWP::UserAgent' => 0;
requires 'Readonly' => 0;
requires 'URI' => 0;
requires 'WWW::Search' => 0;
requires 'Web::Scraper' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=WWW-Search-ValentinskaCZ';
resources 'homepage' => 'https://github.com/tupinek/WWW-Search-ValentinskaCZ';
resources 'repository' => 'git://github.com/tupinek/WWW-Search-ValentinskaCZ';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
