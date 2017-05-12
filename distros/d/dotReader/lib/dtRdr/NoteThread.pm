package dtRdr::NoteThread;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;

use Tree::Simple 'use_weak_refs';
use base 'Tree::Simple'; # I guess

# the id will always be the note id
use Method::Alias (
# new     old     (Method::Alias still feels backwards)
  id   => 'getUID',
  note => 'getNodeValue',
  # the rest are names that I just don't like because this isn't java
  map({my $n = $_; $n =~ s/^get//; (lc($n) => $_)} qw(
    getDepth
    getWidth
    getIndex
    getParent
  )),
  children => 'getAllChildren',
  is_root  => 'isRoot',
  # and these to make it pretend to be a range
  'a'         => 'get_start_pos',
  'start_pos' => 'get_start_pos',
  'b'         => 'get_end_pos',
  'end_pos'   => 'get_end_pos',
);

  sub has_children {return(! $_[0]->isLeaf);}
  sub get_start_pos {return($_[0]->note->get_start_pos)};
  sub get_end_pos {return($_[0]->note->get_end_pos)};

  sub is_dummy {return($_[0]->note->is_fake)}; # for now

  # the text 'root' makes a terrible object, and yet it is a true value,
  # which is about useless thank you very much
  sub getParent {
    my $self = shift;
    my $p = $self->SUPER::getParent;
    $p or die "now what?";
    ($p eq 'root') and return();
    return($p);
  }

=head1 NAME

dtRdr::NoteThread - an n-ary tree of notes

=head1 SYNOPSIS

  my (@threads) = dtRdr::NoteThread->create(@notes);

=head1 Method Names

Most of the methods from L<Tree::Simple> have been aliased to a
lowercase+underscores, terse naming convention (e.g. 'getParent' becomes
'parent', 'getDepth' => 'depth', 'getAllChildren' => 'children', etc.)

=over

=item id

The thread id (getUID) is the note id.

=item note

Returns the note object (getNodeValue.)

=back

If possible, use the aliases to work with this package.  In the case
that I find time to write Tree::Simpler, the javaLike names will vanish.

=cut

=head1 Identifier Methods

A notethread needs to pretend to be an annotation (in some contexts), so
we implement these identifiers.

=head2 IS_RANGE_TYPE

true

=head2 ANNOTATION_TYPE

notethread

=cut

use constant {ANNOTATION_TYPE => 'notethread'};

=head1 Class Methods

=head2 create

Sorts through a pile of notes and turns them all into threads.

  my (@threads) = dtRdr::NoteThread->create(@notes);

The threads will be in arbitrary order.

=cut

sub create {
  my $package = shift;
  my @notes = @_;
  my %notes = map({$_->id => $_} @notes);
  # not sure if I can build trees and arbitrarily plug them together.
  my %roots; # will hold rootlist
  my %done;
  my $mk_root = sub {
    my ($rid, $note) = @_;
    my $tree = $package->new($note);
    return($roots{$rid} = $done{$rid} = $tree);
  };
  my $get_root = sub {
    my ($rid, $child) = @_;
    $roots{$rid} and return($roots{$rid});
    my $note = $notes{$rid};
    unless($note) {
      $note = $package->dummy($rid, $child);
    }
    return($mk_root->($rid, $note));
  };
  my $mk_tree = sub {
    my ($id, $note, $parent) = @_;
    my $tree = $package->new($note, $parent);
    return($done{$id} = $tree);
  };
  my $get_parent;
  $get_parent = sub {
    my ($note, @anc) = @_;
    # lookup
    if(my $tree = $done{$anc[0]}) {
      return($tree);
    }
    # create
    if(1 == scalar(@anc)) {
      return($get_root->($anc[0], $note));
    }
    my $grandparent = $get_parent->($note, @anc[1..$#anc]);
    my $pid = $anc[0];
    my $pnote = $notes{$pid};
    unless($pnote) {
      $pnote = $package->dummy($pid, $note);
    }
    return($mk_tree->($pid, $pnote, $grandparent));
  };
  foreach my $note (@notes) {
    my $id = $note->id;
    $done{$id} and next;
    if(my @ancestors = $note->references) {
      my $parent = $get_parent->($note, @ancestors);
      $mk_tree->($id, $note, $parent);
    }
    else {
      $mk_root->($id, $note);
    }
  }
  return(values(%roots));
} # end subroutine create definition
########################################################################

=head2 dummy

Creates a dummy note.  Copies all of the attributes from the descendant
note (in the same thread), except the id and references.

  my $note = dtRdr::NoteThread->dummy($id, $descendant);

=cut

sub dummy {
  my $package = shift;
  my ($id, $desc) = @_;

  my @refs = $desc->references;
  my ($i) = grep({$id eq $refs[$_]} 0..$#refs);
  defined($i) or croak("cannot find '$id' in those references");
  splice(@refs, 0, $i);

  my $note = $desc->dummy(
    id => $id,
    (scalar(@refs) ? (references => \@refs) : ())
  );
  $note->set_is_fake;
  $note->set_content("note '$id' not available");
  return($note);
} # end subroutine dummy definition
########################################################################

=head1 Constructor

=head2 new

See L<Tree::Simple>.

  my $thread = dtRdr::NoteThread->new($note, $parent);

=cut

sub new {
  my $package = shift;
  my $note = shift;

  my $self = $package->SUPER::new($note, @_);
  $self->setUID($note->id);
  return($self);
} # end subroutine new definition
########################################################################

=head1 Methods

=head2 rmap

Depth-first recursion.  At each level, $sub is called as $sub->($node, \%ctrl).

The %ctrl hash allows you to send commands back to the dispatcher.

  my $sub = sub {
    my ($node, $ctrl) = @_;
    if(something($node)) {
      $ctrl->{prune} = 1; # do not follow children
    }
  };
  $tree->rmap($sub);

=cut

sub rmap {
  my $self = shift;
  my ($subref) = @_;

  my %ctrl;
  my @answers = do {
    local $_ = $self;
    $subref->($self, \%ctrl);
  };
  $ctrl{prune} and return(@answers);
  foreach my $child ($self->children) {
    push(@answers, $child->rmap($subref));
  }
  return(@answers);
} # end subroutine rmap definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm and OSoft, All Rights Reserved.

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

# vi:ts=2:sw=2:et:sta
1;
