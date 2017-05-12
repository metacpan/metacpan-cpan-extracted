use strict;
use inc::Module::Install;

name        'XML-All';
license     'MIT';
all_from    'lib/XML/All.pm';

requires    'XML::Twig';
requires    'Tie::Simple';
requires    'XML::Literal';
requires    'Class::InsideOut';
requires    'Exporter::Lite';

include_deps 'ok';
include_deps 'Test::More';

sign; WriteAll;
