use strict;
use warnings;
package ClassMOPDirty;

use metaclass;
use Scalar::Util 'refaddr';

sub stuff {}

use constant CAN => [ qw(stuff refaddr meta) ];
use constant CANT => [ ];
1;
