use strict;
use warnings;
package Clean;

use ExporterModule qw/stuff/;
use Scalar::Util 'refaddr';
use namespace::autoclean;

sub method { }

use constant CAN => [ qw(method) ];
use constant CANT => [ qw(stuff refaddr) ];
1;
