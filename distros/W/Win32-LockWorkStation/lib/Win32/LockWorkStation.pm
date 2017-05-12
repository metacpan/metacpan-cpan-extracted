package Win32::LockWorkStation;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

require 5.005;

use strict;
use warnings;
use Exporter;
use DynaLoader;

our $VERSION     = '0.03';
our @ISA         = qw(Exporter DynaLoader);
our @EXPORT      = qw();
our %EXPORT_TAGS = (
                    'all' => [qw(LockWorkStation)]
                   );
our @EXPORT_OK   = (@{$EXPORT_TAGS{'all'}});

########################################################
# Start Public Module
########################################################

sub LockWorkStation {

    my $self  = shift;
    my $class = ref($self) || $self;

    return $self->w32_LockWorkStation()
}

########################################################
# End Public Module
########################################################

bootstrap Win32::LockWorkStation;

1;

__END__

########################################################
# Start POD
########################################################

=head1 NAME

Win32::LockWorkStation - Win32 Lock Workstation

=head1 SYNOPSIS

  use Win32::LockWorkStation;

  if (!defined(Win32::LockWorkStation->LockWorkStation())) {
      print "Error locking workstation\n"
  }

=head1 DESCRIPTION

Win32::LockWorkStation is a class implementing the LockWorkStation 
function in the user32.dll library via XS.  This is a 'shortcut' to 
CTRL-ALT-DEL and pressing the "Lock Computer" button.

=head1 REQUIREMENTS

Win32::LockWorkStation requires the following:

  - Win32 Operating System equal to or greater than XP.
  - C compiler and make utility *

* It's important to 'match' your C compiler and make utility.  This 
module has been tested with MinGW/dmake and MS VC++/nmake.

=head1 METHODS

=head2 LockWorkStation() - lock workstation

  Win32::LockWorkStation->LockWorkStation();

Lock the workstation.

=head1 EXPORT

None by default.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut
