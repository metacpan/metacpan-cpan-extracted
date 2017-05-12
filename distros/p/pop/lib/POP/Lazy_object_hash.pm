=head1 TIECLASS
Name:	POP::Lazy_object_hash
Desc:	Implements a tied hash which contains a list of persistent objects,
	lazily, so that it at first just contains the objects' pids, but goes
	out and restores the object when it is accessed.
=cut
package POP::Lazy_object_hash;

$VERSION = do{my(@r)=q$Revision: 1.5 $=~/d+/g;sprintf '%d.'.'%02d'x$#r,@r};

use strict;
use Carp;
use Devel::WeakRef;
use vars qw/$VERSION/;

=head2 METHOD
Name:	POP::Lazy_object_hash::TIEHASH
Desc:	The tied hash constructor; takes the persistent class, the name of
	this collection in our parent, our parent and a hashref of keys to pids.
	Notice that all the pids must be for objects in the same class
=cut
sub TIEHASH {
  my($type, $class, $name, $parent, $pids) = @_;
  my $pm = $class;
  $pm =~ s,::,/,g;
  $pm .= '.pm';
  return bless {'class' => $class,
                'pm' => $pm,
		'name' => $name,
		'parent' => Devel::WeakRef::->new($parent),
                'hash' => $pids}, $type;
}

=head2 METHOD
Name:	POP::Lazy_object_hash::FETCH
Desc:	Called whenever an element of the tied hash is accessed, this
	will restore the object if it hasn't already been, and then
	return it.
=cut
sub FETCH {
  my($this, $key) = @_;
  unless (ref $this->{'hash'}{$key}) {
    # restore the object
    require $this->{'pm'};
    my $obj = $this->{'class'}->new($this->{'hash'}{$key});
    unless ($obj) {
      croak "Unable to restore object [$this->{'hash'}{$key}] in class [".
	"$this->{'class'}]";
    }
    $this->{'hash'}{$key} = $obj;
  }
  return $this->{'hash'}{$key};
}

=head2 METHOD
Name:	POP::Lazy_object_hash::PIDS
Desc:	Returns a hash of keys to pids for every object in the hash, either by
	pulling the pid out of the restored object, or by simply returning
	that value of the hash if the object hasn't been restored yet.
=cut
sub PIDS {
  my($this) = @_;
  my %pids;
  while (my($k,$v) = each %{$this->{'hash'}}) {
    if (ref $v) {
      $pids{$k} = $v->pid;
    } else {
      $pids{$k} = $v;
    }
  }
  return wantarray ? %pids : \%pids;
}

=head2 METHOD
Name:	POP::Lazy_object_hash::STORE
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
Name:	POP::Lazy_object_hash::EXISTS
Desc:	Called to see if a key exists in the hash.
=cut
sub EXISTS {
  my($this, $key) = @_;
  exists $this->{'hash'}{$key};
}

=head2 METHOD
Name:	POP::Lazy_object_hash::DELETE
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
Name:	POP::Lazy_object_hash::CLEAR
Desc:	Called to delete all key/value pairs in the hash.
=cut
sub CLEAR {
  my($this) = @_;
  $this->{'hash'} = {};
}

=head2 METHOD
Name:	POP::Lazy_object_hash::FIRSTKEY
Desc:	Called when first iterating through the hash.
=cut
sub FIRSTKEY {
  my($this) = @_;
  my $a = keys %{$this->{'hash'}}; # reset iterator
  each %{$this->{'hash'}};
}

=head2 METHOD
Name:	POP::Lazy_object_hash::NEXTKEY
Desc:	Called when iterating through the hash.
=cut
sub NEXTKEY {
  my($this) = @_;
  each %{$this->{'hash'}}; 
}

$VERSION = $VERSION;
