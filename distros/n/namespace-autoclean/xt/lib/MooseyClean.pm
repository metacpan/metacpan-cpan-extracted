use strict;
use warnings;
package MooseyClean;

use Moose;
use Scalar::Util 'refaddr';
use namespace::autoclean;

sub stuff {}

use constant CAN => [ qw(stuff meta) ];
use constant CANT => [ qw(has with refaddr) ];
1;
