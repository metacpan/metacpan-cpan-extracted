use strict;
use warnings;
package MooseExporter;

use Moose::Exporter;
use Moose::Role ();
use namespace::autoclean;

Moose::Exporter->setup_import_methods(also => 'Moose::Role');

use constant CAN => [ qw(import unimport) ];
use constant CANT => [ qw(has with) ];
1;
