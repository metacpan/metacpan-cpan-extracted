use strict;
use warnings;
package Composer;

use parent 'Clean';
use Role::Tiny 'with';
with 'Role';
use Scalar::Util 'weaken';
use namespace::autoclean;

sub child_stuff {}

use constant CAN => [ qw(method child_stuff role_stuff) ];
use constant CANT => [ qw(with refaddr reftype weaken) ];
1;
