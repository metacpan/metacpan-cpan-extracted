# -*- cperl -*-
# Win32/ShellExt/DragAndDropHandler.pm
#
# (C) 2002 jbnivoit@cpan.org
#

package Win32::ShellExt::DragAndDropHandler;

use 5.006;
use strict;
use warnings;
use Win32::ShellExt::CtxtMenu;
$Win32::ShellExt::DragAndDropHandler::VERSION = '0.1';
@Win32::ShellExt::DragAndDropHandler::ISA = qw(Win32::ShellExt::CtxtMenu);

sub new() {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless ($self, $class);
  return $self;
}

1;
__END__

=head1 NAME

Win32::ShellExt::DragAndDropHandler - Perl module for implementing D&D context menu extensions of the Windows Explorer

=head1 SYNOPSIS

 See Win32::ShellExt::CtxtMenu.

=head1 DESCRIPTION

This is used in the same fashion as Win32::ShellExt::CtxtMenu, the only difference being when the callbacks on your
package are invoked: when subclassing this package, the callbacks are only called in the right click context menu of
a drag and drop shell operation.

=head2 EXPORT

None by default. None needed.

=head1 AUTHOR

Jean-Baptiste Nivoit E<lt>jbnivoit@hotmail.comE<gt>

=head1 SEE ALSO

L<perl>.

=cut
