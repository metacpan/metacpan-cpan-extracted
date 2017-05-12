use strict;
use warnings;
package MouseyClean;

use Mouse;
use File::Spec::Functions 'catdir';
use namespace::autoclean;

sub stuff {}

use constant CAN => [ qw(stuff meta) ];
use constant CANT => [ qw(has with catdir)];
1;
