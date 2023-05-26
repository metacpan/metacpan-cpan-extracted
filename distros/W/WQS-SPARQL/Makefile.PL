use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Wikidata Query Service SPARQL class.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'WQS-SPARQL';
perl_version 5.006002;
readme_from 'SPARQL.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Error::Pure' => 0;
requires 'HTTP::Request' => 0;
requires 'JSON::XS' => 0;
requires 'LWP::UserAgent' => 0;
requires 'URI' => 0;
requires 'URI::QueryParam' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/WQS-SPARQL/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/WQS-SPARQL';
resources 'repository' => 'git://github.com/michal-josef-spacek/WQS-SPARQL';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
