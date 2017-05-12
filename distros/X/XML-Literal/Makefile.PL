use strict;
use inc::Module::Install;

name        'XML-Literal';
license     'MIT';
all_from    'lib/XML/Literal.pm';

requires 'Sub::Override';
include_deps 'ok';
include_deps 'Test::More';

sign; WriteAll;
