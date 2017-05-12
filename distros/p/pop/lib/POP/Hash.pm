=head1 TIECLASS
Name:	POP::Hash
Desc:	Implements a tied hash which contains a list of persistent objects,
	lazily, so that it at first just contains the objects' pids, but goes
	out and restores the object when it is accessed.
=cut
package POP::Hash;

$VERSION = do{my(@r)=q$Revision: 1.4 $=~/d+/g;sprintf '%d.'.'%02d'x$#r,@r};

use strict;
use Carp;
use Devel::WeakRef;
use vars qw/$VERSION/;

=head2 METHOD
Name:	POP::Hash::TIEHASH
Desc:	The tied hash constructor; takes the name of this collection in our
	parent, our parent and a hashref containing initial values.
=cut
sub TIEHASH {
  my($type, $name, $parent, $hash) = @_;
  return bless {'name' => $name,
		'parent' => Devel::WeakRef::->new($parent),
                'hash' => {%$hash}}, $type;
}

=head2 METHOD
Name:	POP::Hash::FETCH
Desc:	Called whenever an element of the tied hash is accessed, this
	will restore the object if it hasn't already been, and then
	return it.
=cut
sub FETCH {
  my($this, $key) = @_;
  return $this->{'hash'}{$key};
}

=head2 METHOD
Name:	POP::Hash::STORE
Desc:	Called whenever an element in the hash is set; Tells our parent to
	update persistence
=cut
sub STORE {
  my($this, $key, $value) = @_;
  $this->{'hash'}{$key} = $value;
  if (my $p = $this->{'parent'}->deref) {
    (tied %$p)->STORE($this->{'name'}, undef, $key); # $key, $value, $subkey
  } else {
    croak "Parent gone when STORE called!?";
  }
}

=head2 METHOD
Name:	POP::Hash::EXISTS
Desc:	Called to see if a key exists in the hash.
=cut
sub EXISTS {
  my($this, $key) = @_;
  exists $this->{'hash'}{$key};
}

=head2 METHOD
Name:	POP::Hash::DELETE
Desc:	Called to delete one key/value pair in the hash.
=cut
sub DELETE {
  my($this, $key) = @_;
  delete $this->{'hash'}{$key};
  if (my $p = $this->{'parent'}->deref) {
    (tied %$p)->STORE($this->{'name'}, undef, $key); # $key, $value, $subkey
  } else {
    croak "Parent gone when STORE called!?";
  }
}

=head2 METHOD
Name:	POP::Hash::CLEAR
Desc:	Called to delete all key/value pairs in the hash.
=cut
sub CLEAR {
  my($this) = @_;
  $this->{'hash'} = {};
}

=head2 METHOD
Name:	POP::Hash::FIRSTKEY
Desc:	Called when first iterating through the hash.
=cut
sub FIRSTKEY {
  my($this) = @_;
  my $a = keys %{$this->{'hash'}}; # reset iterator
  each %{$this->{'hash'}};
}

=head2 METHOD
Name:	POP::Hash::NEXTKEY
Desc:	Called when iterating through the hash.
=cut
sub NEXTKEY {
  my($this) = @_;
  each %{$this->{'hash'}}; 
}

$VERSION = $VERSION;
