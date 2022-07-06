use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Test JSON data with types.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Test-JSON-Type';
perl_version 5.006002;
readme_from 'Type.pm';
recursive_author_tests('xt');
requires 'Cpanel::JSON::XS' => 4.05;
requires 'Cpanel::JSON::XS::Type' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'Readonly' => 0;
requires 'Test::Differences' => 0;
requires 'Test::Builder::Module' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Test-JSON-Type/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Test-JSON-Type';
resources 'repository' => 'git://github.com/michal-josef-spacek/Test-JSON-Type';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
