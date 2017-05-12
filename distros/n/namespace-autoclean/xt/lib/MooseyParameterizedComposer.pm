use strict;
use warnings;
package MooseyParameterizedComposer;

use Moose;
extends 'MooseyClean';
with 'MooseyParameterizedRole' => { foo => 1 };
use Scalar::Util 'weaken';
use namespace::autoclean;

sub child_stuff {}

use constant CAN => [ qw(stuff child_stuff role_stuff parameterized_role_stuff meta) ];
use constant CANT => [ qw(has with parameter role refaddr reftype weaken) ];
1;
