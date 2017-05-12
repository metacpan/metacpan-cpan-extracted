=head1 TIECLASS
Name:	POP::Lazy_object_list
Desc:	Implements a tied array which contains a list of persistent objects,
	lazily, so that it at first just contains the objects' pids, but goes
	out and restores the object when it is accessed.
=cut
package POP::Lazy_object_list;

$VERSION = do{my(@r)=q$Revision: 1.8 $=~/d+/g;sprintf '%d.'.'%02d'x$#r,@r};

use strict;
use Carp;
use Devel::WeakRef;
use vars qw/$VERSION/;

=head2 METHOD
Name:	POP::Lazy_object_list::TIEARRAY
Desc:	The tied array constructor; takes the persistent class name and a
	list of pids as arguments.  Notice that all the pids must be for
	objects in the same class
=cut
sub TIEARRAY {
  my($type, $class, $name, $parent, @pids) = @_;
  my $pm = $class;
  $pm =~ s,::,/,g;
  $pm .= '.pm';
  return bless {'class' => $class,
                'pm' => $pm,
		'name' => $name,
		'parent' => Devel::WeakRef::->new($parent),
                'list' => [@pids]}, $type;
}

=head2 METHOD
Name:	POP::Lazy_object_list::FETCH
Desc:	Called whenever an element of the tied array is accessed, this
	will restore the object if it hasn't already been, and then
	return it.
=cut
sub FETCH {
  my($this, $index) = @_;
  unless (ref $this->{'list'}[$index]) {
    # restore the object
    require $this->{'pm'};
    my $obj = $this->{'class'}->new($this->{'list'}[$index]);
    unless ($obj) {
      croak "Unable to restore object [$this->{'list'}[$index]] in class [".
	"$this->{'class'}]";
    }
    $this->{'list'}[$index] = $obj;
  }
  return $this->{'list'}[$index];
}

=head2 METHOD
Name:	POP::Lazy_object_list::PIDS
Desc:	Returns the pids for every object in the array, either by pulling it
	out of the restored object, or by simply returning that element of the
	array if the object hasn't been restored yet.
=cut
sub PIDS {
  my($this) = @_;
  my @pids;
  foreach (@{$this->{'list'}}) {
    if (ref $_) {
      push(@pids, $_->pid)
    } else {
      push (@pids, $_);
    }
  }
  return @pids;
}

=head2 METHOD
Name:	POP::Lazy_object_list::STORE
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

=head2 METHOD
Name:	POP::Lazy_object_list::PUSH
Desc:	Called to push elements onto the list.
=cut
sub PUSH {
  my($this) = shift;
  my $low = @{$this->{'list'}};
  push(@{$this->{'list'}}, @_);
  if (my $p = $this->{'parent'}->deref) {
    (tied %$p)->STORE($this->{'name'}, undef, ($low..$low+(@_-1)));
  } else {
    croak "Parent gone when STORE called!?";
  }
}

sub EXTEND {}

=head2 METHOD
Name:	POP::Lazy_object_list::POP
Desc:	Called to pop an element from the list.
=cut
sub POP {
  my $val = FETCH($_[0], $#{$_[0]{'list'}});
  STORE($_[0], $#{$_[0]{'list'}}, undef);
  $val;
}

=head2 METHOD
Name:	POP::Lazy_object_list::SHIFT
Desc:	Called to shift an element from the list.
=cut
sub SHIFT {
  my $val = shift @{$_[0]{'list'}};
  if (my $p = $_[0]{'parent'}->deref) {
    (tied %$p)->STORE($_[0]{'name'}, $_[0]{'list'});
  } else {
    croak "Parent gone when STORE called!?";
  }
  $val;
}

sub CLEAR {
  @{$_[0]{'list'}} = ();
  if (my $p = $_[0]{'parent'}->deref) {
    (tied %$p)->STORE($_[0]{'name'}, (tied %$p)->{$_[0]{'name'}});
  } else {
    croak "Parent gone when STORE called!?";
  }
} 

=head2 METHOD
Name:	POP::Lazy_object_list::UNSHIFT
Desc:	Called to unshift an element onto the list.
=cut
sub UNSHIFT {
  unshift @{$_[0]{'list'}}, $_[1];
  if (my $p = $_[0]{'parent'}->deref) {
    (tied %$p)->STORE($_[0]{'name'}, $_[0]{'list'});
  } else {
    croak "Parent gone when STORE called!?";
  }
}

=head2 METHOD
Name:	POP::Lazy_object_list::SPLICE
Desc:	Called to splice elements from and into the list.
=cut
sub SPLICE {
  my($this, $offset, $length, @list) = @_;
  splice @{$this->{'list'}}, $offset, $length, @list;
  if (my $p = $this->{'parent'}->deref) {
    (tied %$p)->STORE($this->{'name'}, $this->{'list'});
  } else {
    croak "Parent gone when STORE called!?";
  }
}

=head2 METHOD
Name:	POP::Lazy_object_list::FETCHSIZE
Desc:	Called whenever the length of the array is requested.
=cut
sub FETCHSIZE {
  return scalar @{$_[0]->{'list'}};
}

=head2 METHOD
Name:	POP::Lazy_object_list::STORESIZE
Desc:	Called whenever the length of the array is set.
=cut
sub STORESIZE {
  $#{$_[0]->{'list'}} = $_[1];
}

$VERSION = $VERSION;
