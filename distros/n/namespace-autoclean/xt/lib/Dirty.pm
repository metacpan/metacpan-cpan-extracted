use strict;
use warnings;
package Dirty;

use ExporterModule 'stuff';

use constant CAN => [ qw(stuff) ];
use constant CANT => [ qw(dualvar) ];

1;
