use strict;
use warnings;
package MooyRole;

use Scalar::Util 'reftype';
use Moo::Role;  # order is significant here
use namespace::autoclean;

sub role_stuff {}

use constant CAN => [ qw(role_stuff) ];
use constant CANT => [ qw(has reftype) ];
1;
