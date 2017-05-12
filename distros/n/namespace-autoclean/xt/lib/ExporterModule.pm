use strict;
use warnings;
package ExporterModule;

use Scalar::Util 'dualvar';
use namespace::autoclean -except => 'import';

use Exporter 'import';
our @EXPORT_OK = qw(stuff);

sub stuff { 'stuff' }

use constant CAN => [ qw(stuff import) ];
use constant CANT => [ qw(dualvar) ];
1;
