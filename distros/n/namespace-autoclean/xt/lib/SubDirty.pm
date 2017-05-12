use strict;
use warnings;
package SubDirty;

use SubExporterModule qw/stuff/;

sub method { }

use constant CAN => [ qw(stuff method) ];
use constant CANT => [ ];
1;
