use strict;
use warnings;
package MouseyRole;

use Mouse::Role;
use File::Spec::Functions 'devnull';
use namespace::autoclean;

sub role_stuff {}

# can't test 'meta', it's unreliable with Mouse
use constant CAN => [ qw(role_stuff) ];
use constant CANT => [ qw(has with devnull)];
1;
