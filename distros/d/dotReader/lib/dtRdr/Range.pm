package dtRdr::Range;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;

use Carp;

use dtRdr::Location;
use Data::GUID;

use Class::Accessor::Classy;
rw qw(
  start
  end
  id
);
no  Class::Accessor::Classy;

=begin complain

Alas, Method::Alias eval($string)'s subs in my package, so
Pod::Coverage claims that I have to document it.  Bah.

=end complain

=for podcoverage_trustme
a
start_pos
b
end_pos
node
book
get_book

=cut

use Method::Alias (
  a         => 'get_start_pos',
  start_pos => 'get_start_pos',
  b         => 'get_end_pos',
  end_pos   => 'get_end_pos',
  node      => 'get_node',
  book      => 'get_book',
  get_book  => 'get_node',
  );

=head1 NAME

dtRdr::Range - a pair of dtRdr::Location objects

=cut

=head1 Constructor

=head2 new

$start and $end are both dtRdr::Location objects.

  my $range = dtRdr::Range->new(
    id    => $id,
    start => $start,
    end   => $end
  );

=cut

sub new {
  my $class = shift;
  (@_ %2) and croak("odd number of elements in argument hash");
  #ref($_[0]) and croak("must use named parameters");
  my %args = @_;

  my ($start, $end) = map({$args{$_}} qw(start end));
  if(defined $start and defined $end) {
    ($start->node == $end->node) or
      croak("range must be for a single node");
  }

  my $self = {%args};
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 create

A constructor which creates the location objects for you.  You must pass
a node object for this to work.  If you do not provide an id, it will be
created for you.

  my $range = dtRdr::Range->create(
    id    => $id,
    node  => $node, # passed to Location constructor
    range => [$start_pos, $end_pos],
    );

=cut

my $new_id = sub {
  my $id = Data::GUID->new()->as_hex;
  # bah
  $id =~ s/^0x/x/;
  return($id);
};

sub create {
  my $package = shift;
  (@_ %2) and croak("odd number of elements in argument hash");
  my %args = @_;

  my ($node, $pos) = map({delete($args{$_})} qw(node range));
  ($pos and ref($pos)) or croak("must have a range");
  if(eval {$pos->isa('dtRdr::Range')}) {
    if(defined($node)) { # check the range
      ref($node) or croak("node '$node' is not an object");
      ($pos->node == $node) or
        croak("node '$node' does not match range node '",
          $pos->node, "'");
    }
    else { # or DWIM with it
      $node = $pos->node;
    }
    # we got fed an existing range
    $pos = [$pos->a, $pos->b];
  }
  else {
    (ref($pos) eq 'ARRAY') or croak('range must be an object or array ref');
  }

  $node or croak("must have a node object");

  $args{id} = $new_id->() unless(defined($args{id}));

  my ($s, $e) = map({dtRdr::Location->new($node, $_)} @$pos);
  return($package->new(%args, start => $s, end => $e));
} # end subroutine create definition
########################################################################

=head1 Methods

=cut


=head2 get_start_pos

Get the start position as a number.

  my $s = $range->get_start_pos;

Also:

  my $s = $range->start_pos;

Also:

  my $s = $range->a;

=cut

sub get_start_pos {
  my $self = shift;
  return($self->start->offset);
} # end subroutine get_start_pos definition
########################################################################

=head2 get_end_pos

Get the end position as a number.

  my $e = $range->get_end_pos;

Also:

  my $e = $range->b;

=cut

sub get_end_pos {
  my $self = shift;
  return($self->end->offset);
} # end subroutine get_end_pos definition
########################################################################


=head2 set_start

  $range->set_start($location);

=cut

sub set_start {
  my $self = shift;
  my ($location) = @_;

  defined($self->start) and
    croak("Attempt to change the start of a ", ref($self), " object");

  if($self->end) {
    ($location->node == $self->end->node) or
      croak("range must be for a single node");
    return($self->SUPER::set_start($location));
  }
} # end subroutine set_start definition
########################################################################

=head2 set_end

  $range->set_end($location);

=cut

sub set_end {
  my $self = shift;
  my ($location) = @_;

  defined($self->end) and
    croak("Attempt to change the end of a ", ref($self), " object");

  if ($self->start){
    ($location->node == $self->start->node) or
      croak("range must be for a single node");
    return($self->SUPER::set_end($location));
  }
} # end subroutine set_end definition
########################################################################

=head2 set_id

  $range->set_id($id);

=cut

sub set_id {
  my $self = shift;
  my ($id) = @_;

  defined($self->id) and
    croak("Attempt to change the id of a ", ref($self), " object");

  $self->SUPER::set_id($id);
} # end subroutine set_id definition
########################################################################

=head2 get_node

also node(), get_book(), book()

  $range->get_node;

=cut

sub get_node {
  my $self = shift;
  return($self->start->get_node);
} # end subroutine get_node definition
########################################################################

=head1 Comparisons

=head2 encloses

Returns true if the $range encloses $offset.

  $range->encloses($offset);

=cut

sub encloses {
  my $self = shift;
  my ($offset) = @_;
  defined($offset) or croak("offset must be defined");
  return(
    $self->end->offset >= $offset and
    $self->start->offset <= $offset
  );
} # end subroutine encloses definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

Dan Sugalski <dan@sidhe.org>

=head1 COPYRIGHT

Copyright (C) 2006 by Dan Sugalski, Eric L. Wilhelm, and OSoft, All
Rights Reserved.

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
