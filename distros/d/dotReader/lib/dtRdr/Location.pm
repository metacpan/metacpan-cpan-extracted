package dtRdr::Location;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;

use Carp;

use Class::Accessor::Classy;
ro qw(
  node
  offset
);
no  Class::Accessor::Classy;

=head1 NAME

dtRdr::Location - location objects

=head1 ABOUT

A location is simply a byte offset from the beginning of a node.

An absolute location is a byte offset from the beginning of a book.  For
now, it will pretend that the book is a node unless it needs to do
otherwise.

=cut

=head1 Constructor

=head2 new

Takes a node object and an offset (in bytes.)

  my $loc = dtRdr::Location->new($node, $offset);

=cut

sub new {
  my $class = shift;
  my ($node, $offset) = @_;
  (@_ == 2) or croak("not enough arguments to new()");
  (eval {$node->isa('dtRdr::Book') or
    $node->isa('dtRdr::TOC')}
    ) or croak('not a dtRdr::TOC');

  my $self = {
    node   => $node,
    offset => $offset
    };
  bless($self, $class);

  return($self);
} # end subroutine new definition
########################################################################

# TODO put some functionality in here?
# operator overloading?


=head2 is_absolute

  $loc->is_absolute and $pony->frolic;

=cut

sub is_absolute {
  my $self = shift;
  return $self->node->isa('dtRdr::Book');
} # end subroutine is_absolute definition
########################################################################

=head1 AUTHOR

Eric Wilhelm

Dan Sugalski <dan@sidhe.org>

=head1 COPYRIGHT

Copyright (C) 2006 Dan Sugalski, Eric L. Wilhelm and OSoft, All Rights
Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vim:ts=2:sw=2:et:sta
1;
