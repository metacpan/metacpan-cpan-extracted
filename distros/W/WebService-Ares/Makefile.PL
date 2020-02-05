use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Perl class to communication with ARES service.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'WebService-Ares';
readme_from 'Ares.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.05;
requires 'Encode' => 0;
requires 'Error::Pure' => 0.16;
requires 'Exporter' => 0;
requires 'HTTP::Request' => 0;
requires 'LWP::UserAgent' => 0;
requires 'Readonly' => 0;
requires 'XML::Parser' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=WebService-Ares';
resources 'homepage' => 'https://github.com/michal-josef-spacek/WebService-Ares';
resources 'repository' => 'git://github.com/michal-josef-spacek/WebService-Ares';
test_requires 'Encode' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.16;
test_requires 'File::Object' => 0.05;
test_requires 'Perl6::Slurp' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
