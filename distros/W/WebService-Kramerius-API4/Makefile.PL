use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Class to Kramerius v4+ API.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.03;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'WebService-Kramerius-API4';
readme_from 'API4.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.02;
requires 'Error::Pure' => 0.24;
requires 'LWP::UserAgent' => 0;
requires 'List::Util' => 1.33;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/WebService-Kramerius-API4/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/WebService-Kramerius-API4';
resources 'repository' => 'git://github.com/michal-josef-spacek/WebService-Kramerius-API4';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
