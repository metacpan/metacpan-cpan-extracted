use strict;
use warnings;
package MooseyRole;

use Moose::Role;
use Scalar::Util 'reftype';
use namespace::autoclean;

sub role_stuff {}

use constant CAN => [ qw(role_stuff meta) ];
use constant CANT => [ qw(has with reftype) ];
1;
