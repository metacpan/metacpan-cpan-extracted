use strict;
use warnings;
package MouseyDirty;

use Mouse;
use File::Spec::Functions 'catdir';

sub stuff {}

use constant CAN => [ qw(stuff has with meta catdir) ];
use constant CANT => [ ];
1;
