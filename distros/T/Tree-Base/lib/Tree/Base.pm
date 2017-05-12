package Tree::Base;
$VERSION = v0.10.2;

use warnings;
use strict;
use Carp;

use Scalar::Util ();

=head1 NAME

Tree::Base - a base class for trees

=head1 SYNOPSIS

  package MyTree;
  use base 'Tree::Base';

  sub blah {shift->{blah}}


  use MyTree;
  my $tree = MyTree->new(blah => ...);
  my $child = $tree->create_child(blah => ...);
  $child->create_child(blah => ...);

=cut

=head2 new

  my $tree = Tree::Base->new(%data);

=cut

sub new {
  my $package = shift;
  my $class = ref($package) || $package;
  my $self = {@_};
  bless($self, $class);
  # TODO parent
  die "todo" if($self->{parent});
  return($self);
} # new ################################################################

=head2 create_child

  my $child = $tree->create_child(%data);

=cut

sub create_child {
  my $self = shift;
  my $child = $self->new(@_);

  return($self->add_child($child));
} # create_child #######################################################

=head2 add_child

  $tree->add_child($child);

=cut

sub add_child {
  my $self = shift;
  my $child = shift;

  croak("cannot add rooted child") if($child->{parent});

  $child->{parent} = $self;
  my $root = $self->root;
  $child->{root} = $root;
  Scalar::Util::weaken($child->{parent});
  Scalar::Util::weaken($child->{root});

  foreach my $child ($child->children) {
    $child->rmap(sub {Scalar::Util::weaken(shift->{root} = $root); ()})
  }

  my $kids = $self->{children} ||= [];
  push(@$kids, $child);

  return($child);
} # add_child ##########################################################

=head2 parent

undef if the node is the root.

  my $parent = $tree->parent;

=head2 children

  my @children = $tree->children;

=cut

sub children {
  my $self = shift;
  return($self->{children} ? @{$self->{children}} : ());
} # children ###########################################################

=head2 child

Get the child with index $i.

  my $child = $toc->child($i);

=cut

sub child {
  my $self = shift;
  my ($i) = @_;
  (1 == @_) or croak "wrong number of arguments";

  my @children = $self->children;
  $children[$i] or croak "no child at index $i";
  return($children[$i]);
} # end subroutine child definition
########################################################################

=head2 root

The root node ($tree if $tree is the root.)

  my $root = $tree->root;

=cut

sub root {
  my $self = shift;
  return(exists($self->{parent}) ? $self->{root} : $self);
} # root ###############################################################

=head2 is_root

True if this is the root node.

  $tree->is_root;

=cut

sub is_root { return(! exists(shift->{parent})) }
########################################################################

=head2 descendants

Recursive children.

  my @descendants = $toc->descendants;

=cut

sub descendants {
  my $self = shift;

  return map({$_->rmap(sub {shift})} $self->children);
} # descendants ########################################################

=head2 older_siblings

Nodes before this, at the same level.

  my @nodes = $tree->older_siblings;

=cut

sub older_siblings {
  my $self = shift;

  $self->is_root and return();
  my @siblings = $self->parent->children;

  while(my $s = pop(@siblings)) {($s == $self) and last;}

  return(@siblings);
} # older_siblings #####################################################


=head2 younger_siblings

Nodes after this, at the same level.

  my @nodes = $tree->younger_siblings;

=cut

sub younger_siblings {
  my $self = shift;

  $self->is_root and return();
  my @siblings = $self->parent->children;

  while(my $s = shift(@siblings)) {($s == $self) and last;}

  return(@siblings);
} # younger_siblings ###################################################


=head2 next_sibling

Returns the next sibling or undef.

  $younger = $toc->next_sibling;

=cut

sub next_sibling {
  my $self = shift;

  my @younger = $self->younger_siblings or return();
  return($younger[0]);
} # next_sibling #######################################################

=head2 prev_sibling

Returns the previous sibling or undef.

  $older = $tree->prev_sibling;

=cut

sub prev_sibling {
  my $self = shift;

  my @older = $self->older_siblings or return();
  return($older[-1]);
} # prev_sibling #######################################################

=head2 ancestors

Returns all of the node's ancestors (from parent upward.)

  my @ancestors = $tree->ancestors;

=cut

sub ancestors {
  my $self = shift;
  my $node = $self;
  my @ancestors;
  while(my $parent = $node->parent) {
    push(@ancestors, $parent);
    $node = $parent;
  }
  return(@ancestors);
} # ancestors ##########################################################

=head2 rmap

  my @ans = $tree->rmap(sub {...});

=cut

sub rmap {
  my $self = shift;
  my ($subref, $knob) = @_;
  $knob ||= Tree::Base::Knob->new;

  my @ans; for ($self) { @ans = $subref->($self, $knob); }

  $knob->{pruned} and return(@ans);

  foreach my $child ($self->children) {
    push(@ans, $child->rmap($subref, $knob));
    $knob->{stopped} and last;
  }
  return(@ans);
} # rmap ###############################################################

sub parent { shift->{parent} }

sub DESTROY {
  my $self = shift;
  delete($self->{children});
}

BEGIN {
package Tree::Base::Knob;
sub new {return bless({}, 'Tree::Base::Knob')};
sub prune {shift->{pruned} = 1; return()}
sub stop  {shift->{stopped} = 1; return()}
} # Tree::Base::Knob
########################################################################

=head1 See Also

You may prefer the JavaStyleAccessors of Tree::Simple or one of the
other tree modules mentioned in its fine manual.  I wanted a tree with
lower-cased accessors, fewer methods, a root() which returned undef, and
no need to worry about circular references.

This module was partially based on the tree functionality of dotReader's
dtRdr::TOC object.

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2006-2009 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
