use strict;
use warnings;
package SubClean;

use SubExporterModule qw/stuff/;
use Scalar::Util 'refaddr';
use namespace::autoclean;   # clean 'stuff' at end of compilation

sub method { }

use constant CAN => [ qw(method) ];
use constant CANT => [ qw(stuff refaddr) ];
1;
