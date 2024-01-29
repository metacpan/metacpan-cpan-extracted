use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Class for searching http://kacur.cz .';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'WWW-Search-KacurCZ';
readme_from 'KacurCZ.pm';
recursive_author_tests('xt');
requires 'Encode' => 0,
requires 'LWP::UserAgent' => 0;
requires 'Perl6::Slurp' => 0;
requires 'Readonly' => 0;
requires 'Text::Iconv' => 0;
requires 'Web::Scraper' => 0;
requires 'WWW::Search' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/WWW-Search-KacurCZ/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/WWW-Search-KacurCZ';
resources 'repository' => 'git://github.com/michal-josef-spacek/WWW-Search-KacurCZ';
test_requires 'WWW::Search' => 0;
test_requires 'File::Object' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Unicode::UTF8' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
