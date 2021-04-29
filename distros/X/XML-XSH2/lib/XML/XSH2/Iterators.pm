# $Id: Iterators.pm,v 2.2 2007-01-02 22:03:22 pajas Exp $

package XML::XSH2::Iterators;

  $VERSION='2.2.9'; # VERSION TEMPLATE

#namespace ???
#attribute ??

sub create_iterator {
  my ($class,$node,$axis,$filter)=@_;
  my $iterator;

  die "Unsupported or unknown axis $axis\n"
    unless $class->can("iterate_$axis");

  if ($class->can("init_$axis")) {
    $node=&{"init_$axis"}($node);
  }
  return undef unless defined $node;

  $iterator= XML::XSH2::FilteredIterator->new($node, $filter);
  $iterator->iterator_function(\&{"iterate_$axis"});
  $iterator->first_filtered() || return undef;
  return $iterator;
}

sub iterate_self {
  return undef;    # the most trivial iterator :-)
}

sub init_child {
  my ($node)=@_;
  return $node->firstChild;
}

sub iterate_child {  # iteration must start at the first child!
  my ($iter, $dir) = @_;
  if ( $dir < 0 ) {
    return $iter->{CURRENT}->previousSibling;
  } else {
    return $iter->{CURRENT}->nextSibling;
  }
}

sub init_following_sibling {
  my ($node)=@_;
  return $node->nextSibling();
}

sub iterate_following_sibling {
  my ($iter, $dir) = @_;
  if ( $dir < 0 ) {
    if ($iter->{FIRST}->isSameNode( $iter->{CURRENT}->previousSibling )) {
      return undef;
    }
    return $iter->{CURRENT}->previousSibling;
  } else {
    return $iter->{CURRENT}->nextSibling;
  }
}


sub init_preceding_sibling {
  my ($node)=@_;
  return $node->nextSibling();
}

sub iterate_preceding_sibling {
  my ($iter, $dir) = @_;
  if ( $dir < 0 ) {
    if ($iter->{FIRST}->isSameNode( $iter->{CURRENT}->nextSibling )) {
      return undef;
    }
    return $iter->{CURRENT}->nextSibling;
  } else {
    return $iter->{CURRENT}->previousSibling;
  }
}

sub iterate_ancestor_or_self {
  my ($iter, $dir) = @_;
  if ( $dir < 0 ) {
    my $node = undef;
    return undef if $iter->{CURRENT}->isSameNode( $iter->{FIRST} );
    $node=$iter->{FIRST};
    while ($node->parentNode and
	   not($node->parentNode->isSameNode($iter->{CURRENT}))) {
      $node=$node->parentNode;
    }
    return $node;
  } else {
    return $iter->{CURRENT}->parentNode;
  }
}

sub init_ancestor {
  my ($node)=@_;
  return $node->parentNode();
}
*iterate_ancestor = *iterate_ancestor_or_self;

*init_parent = *init_ancestor;
*iterate_parent = *iterate_ancestor_or_self;

sub iterate_descendant_or_self {
  my $iter = shift;
  my $dir  = shift;
  if ( $dir < 0 ) {
    return undef if $iter->{CURRENT}->isSameNode( $iter->{FIRST} );
    return get_prev_node($iter->{CURRENT});
  } else {
    return get_next_node($iter->{CURRENT},$iter->{FIRST});
  }
  return $node;
}

sub init_descendant {
  my ($node)=@_;
  return $node->firstChild;
}
sub iterate_descendant { # iteration must start at the first child!
  my $iter = shift;
  my $dir  = shift;
  if ( $dir < 0 ) {
    return undef if $iter->{CURRENT}->isSameNode( $iter->{FIRST} );
    return get_prev_node($iter->{CURRENT});
  } else {
    return get_next_node($iter->{CURRENT},$iter->{FIRST}->parentNode);
  }
}

sub iterate_following_or_self {
  my $iter = shift;
  my $dir  = shift;
  if ( $dir < 0 ) {
    return undef if $iter->{CURRENT}->isSameNode( $iter->{FIRST} );
    return get_prev_node($iter->{CURRENT});
  } else {
    return get_next_node($iter->{CURRENT});
  }
}

sub iterate_preceding_or_self {
  my $iter = shift;
  my $dir  = shift;
  if ( $dir < 0 ) {
    return undef if $iter->{CURRENT}->isSameNode( $iter->{FIRST} );
    return get_next_node($iter->{CURRENT});
  } else {
    return get_prev_node($iter->{CURRENT});
  }
}

sub init_following {
  return get_next_node($_[0]);
}
*iterate_following = *iterate_following_or_self;

sub init_preceding {
  return get_prev_node($_[0]);
}
*iterate_preceding = *iterate_preceding_or_self;

sub init_first_descendant {
  return $_[0]->firstChild;
}

sub iterate_first_descendant_or_self {
  my ($iter, $dir) = @_;

  if ( $dir < 0 ) {
    if ($iter->{FIRST}->isSameNode( $iter->{CURRENT} )) {
      return undef;
    }
    return $iter->{CURRENT}->parent;
  } else {
    return $iter->{CURRENT}->firstChild;
  }
}
sub iterate_first_descendant {
  iterate_first_descendant_or_self(@_);
}
#*iterate_first_descendant = *iterate_first_descendant_or_self;

sub init_last_descendant {
  return $_[0]->lastChild;
}
*iterate_last_descendant = *iterate_last_descendant_or_self;

sub iterate_last_descendant_or_self {
  my ($iter, $dir) = @_;
  if ( $dir < 0 ) {
    if ($iter->{FIRST}->isSameNode( $iter->{CURRENT} )) {
      return undef;
    }
    return $iter->{CURRENT}->parent;
  } else {
    return $iter->{CURRENT}->lastChild;
  }
}


#STATIC
sub get_prev_node {
  my ($node) = @_;
  if ($node->previousSibling) {
    $node = $node->previousSibling;
    if ($node->hasChildNodes) {
      return $node->lastChild;
    } else {
      return $node;
    }
  }
  return $node->parentNode;
}

#STATIC
sub get_next_node {
  my ($node,$stop) = @_;

  if ( $node->hasChildNodes ) {
    return $node->firstChild;
  } else {
    while ($node) {
      return undef if ($stop and $node->isSameNode($stop) or
		       not $node->parentNode);
      return $node->nextSibling if $node->nextSibling;
      $node = $node->parentNode;
    }
    return undef;
  }
}

package XML::XSH2::FilteredIterator;
use strict;
BEGIN {
  local $^W=0; # suppress warning with perl5.8.2
  require XML::LibXML::Iterator;
};
use base qw(XML::LibXML::Iterator);

sub new {
  my ($class,$node,$filter)=@_;
  $class = ref($class) || $class;
  my $self = $class->SUPER::new($node);
  $self->{FILTER}=$filter;
  return $self;
}

sub filter {
  my $self=shift;
  if (@_) { $self->{FILTER}=$_[0]; }
  return $self->{FILTER};
}

sub first_filtered {
  my $self=shift;
  my ($node)=@_;
  my $filter=$self->filter;
  $self->first(@_) || return undef;
  if (ref($filter) eq 'CODE') {
    while ($self->current() and not &$filter($self->current())) {
      $self->next() || return undef;
    }
  }
  return $self->current();
}

sub next {
  my $self=shift;
  my ($node)=@_;
  my $filter=$self->filter;
  $self->SUPER::next() || return undef;
  while ($self->current() and not &$filter($self->current())) {
    $self->SUPER::next() || return undef;
  }
  return $self->current();
}

sub prev {
  my $self=shift;
  my ($node)=@_;
  my $filter=$self->filter;
  $self->SUPER::prev() || return undef;
  while ($self->current() and not &$filter($self->current())) {
    $self->SUPER::prev() || return undef;
  }
  return $self->current();
}

1;

