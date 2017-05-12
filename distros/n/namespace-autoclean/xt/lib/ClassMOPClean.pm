use strict;
use warnings;
use Class::MOP::Class;

my $meta = Class::MOP::Class->create('ClassMOPClean');

package ClassMOPClean;
use Scalar::Util 'refaddr';
use namespace::autoclean;

sub stuff {}

use constant CAN => [ qw(stuff meta) ];
use constant CANT => [ qw(refaddr) ];
1;
