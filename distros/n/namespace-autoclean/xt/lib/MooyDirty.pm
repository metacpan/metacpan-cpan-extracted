use strict;
use warnings;
package MooyDirty;

use Moo;
use Scalar::Util 'refaddr';

sub stuff {}

use constant CAN => [ qw(stuff has refaddr) ];
use constant CANT => [ ];
1;
