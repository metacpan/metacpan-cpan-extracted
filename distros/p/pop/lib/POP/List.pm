=head1 TIECLASS
Name:	POP::List
Desc:	Implements a tied array which contains a list of persistent objects,
	lazily, so that it at first just contains the objects' pids, but goes
	out and restores the object when it is accessed.
=cut
package POP::List;

$VERSION = do{my(@r)=q$Revision: 1.7 $=~/d+/g;sprintf '%d.'.'%02d'x$#r,@r};

use strict;
use Carp;
use Devel::WeakRef;
use Tie::Array;
use vars qw/@ISA $VERSION/;

@ISA = qw/Tie::StdArray/;

=head2 METHOD
Name:	POP::List::TIEARRAY
Desc:	The tied array constructor; takes the name of this collection in our
	parent, the parent and a list of initial values
=cut
sub TIEARRAY {
  my($type, $name, $parent, @list) = @_;
  return bless {'name' => $name,
		'parent' => Devel::WeakRef::->new($parent),
                'list' => \@list}, $type;
}

=head2 METHOD
Name:	POP::List::FETCH
Desc:	Called whenever an element of the tied array is accessed, this
	will restore the object if it hasn't already been, and then
	return it.
=cut
sub FETCH {
  my($this, $index) = @_;
  return $this->{'list'}[$index];
}

=head2 METHOD
Name:	POP::List::STORE
Desc:	Called whenever an element in the array is set; tells our parent to
	update persistence.
=cut
sub STORE {
  my($this, $index, $value) = @_;
  $this->{'list'}[$index] = $value;
  if (my $p = $this->{'parent'}->deref) {
    (tied %$p)->STORE($this->{'name'}, undef, $index); # $key, $value, $subkey
  } else {
    croak "Parent gone when STORE called!?";
  }
}

sub PUSH {
  my($this) = shift;
  my $low = @{$this->{'list'}};
  push @{$this->{'list'}}, @_;
  if (my $p = $this->{'parent'}->deref) {
    (tied %$p)->STORE($this->{'name'}, undef, ($low..($low+@_-1)));
  } else {
    croak "Parent gone when STORE called!?";
  }
} 

=head2 METHOD
Name:	POP::List::FETCHSIZE
Desc:	Called whenever the length of the array is requested.
=cut
sub FETCHSIZE {
  my($this) = @_;
  return scalar @{$this->{'list'}};
}

=head2 METHOD
Name:	POP::List::STORESIZE
Desc:	Called whenever the length of the array is set.
=cut
sub STORESIZE {
  my($this, $size) = @_;
  $#{$this->{'list'}} = $size;
}

$VERSION = $VERSION;
