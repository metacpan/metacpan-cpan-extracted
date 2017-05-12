use strict;
use warnings;
package MooyComposer;

use Moo;
extends 'MooyClean';
with 'MooyRole';
use Scalar::Util 'weaken';
use namespace::autoclean;

sub child_stuff {}

use constant CAN => [ qw(stuff role_stuff child_stuff) ];
use constant CANT => [ qw(has refaddr reftype weaken) ];
1;
