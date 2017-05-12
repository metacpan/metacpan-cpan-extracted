use strict;
use warnings;

use inc::Module::Install;

name 'Workflow-Lite';

license  'MIT';
all_from 'lib/Workflow/Lite.pm';

requires 'namespace::autoclean';
requires 'Class::Load';
requires 'Moose';
requires 'Moose::Exporter';
requires 'Moose::Role';
requires 'MooseX::ClassAttribute';

test_requires 'Test::More';

auto_install;
WriteAll;
