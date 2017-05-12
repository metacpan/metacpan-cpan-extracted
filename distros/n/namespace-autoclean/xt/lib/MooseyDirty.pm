use strict;
use warnings;
package MooseyDirty;

use Moose;
use Scalar::Util 'refaddr';

sub stuff {}

use constant CAN => [ qw(stuff has with refaddr meta) ];
use constant CANT => [ ];
1;
