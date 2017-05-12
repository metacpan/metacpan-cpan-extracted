use strict;
use warnings;
package MooyClean;

use Moo;
use Scalar::Util 'refaddr';
use namespace::autoclean;

sub stuff {}

use constant CAN => [ qw(stuff) ];
use constant CANT => [ qw(has refaddr) ];
1;
