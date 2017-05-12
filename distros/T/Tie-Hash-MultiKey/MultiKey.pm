package Tie::Hash::MultiKey;

#use diagnostics;
use strict;
use Carp;
use Tie::Hash;
use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 0.08 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

my $indexmax = 2**48;	# a really big unique number that perl will not convert to float

=head1 NAME

Tie::Hash::MultiKey - multiple keys per value

=head1 SYNOPSIS

  use Tie::Hash::MultiKey;

  $thm = tie %hash, qw(Tie::Hash::MultiKey) ,@optionalext;
  $thm = tied %hash;

  untie %hash;

  ($href,$thm) = new Tie::Hash::MultiKey;

  $hash{'foo'}        = 'baz';
	or
  $hash{'foo', 'bar'} = 'baz';
	or
  $array_ref = ['foo', 'bar'];
  $hash{ $array_ref } = 'baz';

  print $hash{foo};	# prints 'baz'
  print $hash{bar};	# prints 'baz'

  $array_ref = ['fuz','zup'];
  $val = tied(%hash)->addkey('fuz' => 'bar');
  $val = tied(%hash)->addkey('fuz','zup' => 'bar');
  $val = tied(%hash)->addkey( $array_ref => 'bar');

  print $hash{fuz}	# prints 'baz'

  $array_ref = ['foo', 'bar'];
  $val = tied(%hash)->remove('foo');
  $val = tied(%hash)->remove('foo', 'bar');
  $val = tied(%hash)->remove( $array_ref );

  $val = tied(%hash)->delkey(); alias for above

  @ordered_keys = tied(%hash)->keylist('foo')
  @allkeys_by_order = tied(%hash)->keylist();
  @slotlist = tied(%hash)->slotlist($i);
  @ordered_vals = tied(%hash)->vals();

  $num_vals = tied(%hash)->size;
  $num_vals = tied(%hash)->consolidate;

  ($newRef,$newThm) = tied(%hash)->clone();
  $newThm = tied(%hash)->copy(tied(%new),@optionalext);

  All of the above methods can be accessed as:

  i.e.	$thm->consolidate;

=head1 DESCRIPTION

Tie::Hash::MultiKey creates hashes that can have multiple ordered keys for a single value. 
As shown in the SYNOPSIS, multiple keys share a common value.

Additional keys can be added that share the same value and keys can be removed without deleting other 
keys that share that value.

STORE..ing a value for one or more keys that already exist will overwrite
the existing value and add any missing keys to the key group for that
value.

B<WARNING:> multiple key values supplied as an ARRAY to STORE and DELETE
operations are passed by Perl as a B<single> string separated by Perl's $;
multidimensional array seperator. i.e.

	$hash{'a','b','c'} = $something;
  or
	@keys = ('a','b','c');
	$hash{@keys} = $something'

This really means $hash{join($;, 'a','b','c')};

Tie::Hash::MultiKey will do the right thing as long as your keys B<DO NOT>
contain binary data the may include the $; separator character.

It is recommended that you use the ARRAY_REF construct to supply multiple
keys for binary data. i.e.

	$hash{['a','b','c']} = $something;
  or
	$keys = ['a','b','c'];
	$hash{$keys} = $something;

The ARRAY_REF construct is ALWAYS safe.

=cut

#
# data structure
# [
#
# 0 =>	{	# $kh
#	key	=> vi		# value_index for array below
#	},
# 1 =>	{	# $vh
#	vi	=> value,	# contains value
#	},
# 2 =>	{	# $sh	pointer to hash list of all shared keys
#	vi	= {key => dummy, key => dummy, ...}, values unused
#	},
# 3 =>	vi,	# numeric value of value index
# 4 =>	or,	# numeric value of key order
# 5 =>  crumbs	# STORE key value
# 6 =>	reserved
# 7 =>  {	# extensions
#   FETCH    => subref,	# required
#   STORE    => subref,	# required
#   DELETE   => subref,	# required
#   COPY     => subref,	# required
#   CLEAR    => subref,	# required
#   REORDERV => subref,	# required
#   TIE      => subref,	# optional
#   EXISTS   => subref,	# optional
#   NEXT     => subref,	# optional
#   ADDKEY   => subref,	# optional
#   DELKEY   => subref,	# optional
#   REORDERK => subref,	# optional
#   CONSOLD  => subref, # optional
# one or more key names as required
#   DATAn     => scalar, array_ref, hash_ref
# }
# ]

my @extrequired = qw(
	FETCH
	STORE
	DELETE
	COPY
	CLEAR
	REORDERV
);
my @extoptional = qw(
	TIE
	EXISTS
	NEXT
	ADDKEY
	DELKEY
	REORDERK
	CONSOLD
);

sub TIEHASH {
  my $class = shift;
  my $self = bless [{},{},{},0,0,undef], $class;
  if (@_) {
    my %extensions = ref $_[0] ? @{$_[0]} : @_;
    foreach (@extrequired) {
      unless (exists $extensions{$_}) {
	croak "missing required extension for '$_'";
      } elsif (ref $extensions{$_} ne 'CODE') {
	croak "'$_' extension pointer is not a subref";
      } else {
	$self->[7]->{$_} = $extensions{$_};
      }
    }

    foreach(@extoptional) {
      unless (exists $extensions{$_}) {
	$self->[7]->{$_} = sub {};
      }
      elsif (ref $extensions{$_} ne 'CODE') {
	croak "'$_' extension pointer is not a subref";
      } else {
	$self->[7]->{$_} = $extensions{$_};
      }
    }

    $self->[7]->{TIE}->($self);		# execute TIE extension to create DATA element
  }
  $self;
}

# extract reference type and class from referrant or return an empty array
# class may be empty;
sub _ref_class {
  my $src = shift;
  my $ref = ref $src or return ();
  my $class;
  if ( "$src" =~ /^\Q$ref\E\=([A-Z]+)\(0x[0-9a-fA-Z]+\)$/ ) {
    $class = $ref;
    $ref = $1;
  }
  return ($ref,$class);
}

sub _isarrayref {
  my($ref,$class) = &_ref_class; 
  return ($ref && $ref eq 'ARRAY') ? 1:0;
}

sub _wash {
  my $keys = shift;
  $keys = [$keys eq '' 
	? ('')
	: split /$;/, $keys, -1] 
  		unless ref $keys eq 'ARRAY';
  croak "empty key\n" unless @$keys;
  return $keys;
}

sub FETCH {
  my($self,$key) = @_;
  my $okey = $key;
#
# in the case where an autoFETCH is done after a store
# i.e.
#	$x = $hp->{[k1,k2,k3]} = item
# or	$x = $hp->{ k1,k2,k3 } = item
#
# the key set is passed by perl to the fetch instead of one of the keys
# 
# check if a fetch follows a store where
# 1	the key is an ARRAY and the referrant from the STORE are equal
# 2	the key, stringified is equal to the key from the STORE
#
# if either of these two condition are met, wash the keys and use
# key[0] as the FETCH key
#
  my $crumbs = $self->[5];
  if (defined $crumbs) {			# see if a recent STORE left key crumbs
    $self->[5] = undef;				# yes, clear it
    if ((_isarrayref($crumbs) &&
	 _isarrayref($key) &&			# keys are really ARRAY's
	 $key == $crumbs ) ||			# and referrants the same
	$key . $; . 'X' eq $crumbs . $; . 'X')	# or keys as string identical
    {
      $key = ${_wash($key)}[0];
    }
  }
  return undef unless exists $self->[0]->{$key};
  my $vi = $self->[0]->{$key};	# get key index
  $self->[7]->{FETCH}->($self,$okey,$vi) if $self->[7];	# extend functionality ($vi)
  return $self->[1]->{$vi};
}

# take arguments of the form:
#	$array_ref, $val
# or
#	$a0, $a1, $a2, $val
# and returns
#	$val, @aN

sub _flip {
  my $val;
  if (ref $_[0] eq "ARRAY") {
    return ($_[1],@{$_[0]});
  }
  return (pop(@_),@_);
}

sub STORE {
  my($self,$keys,$val) = @_;
  $self->[5] = $keys;
  my @keys = @{_wash($keys)};
  my($kh,$vh,$sh) = @{$self};
  my($vi,%found);
  foreach my $key (@keys) {
    my $vi;
    next unless exists $kh->{$key};
    $vi = $kh->{$key};	# get key index
    $found{$vi} = $sh->{$vi}->{$key};	# capture shared key value
  }
  my @vi = keys %found;
  $keys = {};
  my $ostart = $self->[4];
  my $oend = $ostart + $#keys;		# first key order entry
  $self->[4] = $oend + 1;		# last key order entry
  @{$keys}{@keys} = ($ostart..$oend);	# create key list
  if (@vi) {				# if there are existing keys
    foreach (@vi) {			# consolidate keys
      my @sk = keys %{$sh->{$_}};	# shared keys
      @{$keys}{@sk} = @{$sh->{$_}}{@sk};
      delete $vh->{$_};		# delete existing value
      delete $sh->{$_};		# delete existing key list
    }
  } else {
    $vi[0] = $self->[3]++;	# new key pointer
  }
  $vi = shift @vi;

  $vh->{$vi} = $val;		# set value
  $sh->{$vi} = $keys;		# set key list
  foreach (keys %$keys) {
    $kh->{$_} = $vi;		# set value index
  }
  $self->_rordkeys() if $self->[3] > $indexmax;
  $self->_rordvals() if $self->[4] > $indexmax;
  $self->[7]->{STORE}->($self,\@keys,$vi) if $self->[7];	# extend functionality (value index)
  $val;
}

sub DELETE {
  my($self,$keys) = @_;
  $self->[5] = undef;		# clear crumbs
  my @keys = @{_wash($keys)};
  my($kh,$vh,$sh) = @{$self};
  my @vis = delete @{$kh}{@keys};	# delete all identified keys
  my(@dkeys,@vix);
  foreach (@vis) {		# $vi delete key shared list entries
    unless (defined $_ && defined $sh->{$_}) { # already deleted?
      $_ = '';			# vi is never empty
      next;
    }
    push @vix, $_;		# save unique value indices
    my $keys = delete $sh->{$_};
    @keys = sort { $keys->{$a} <=> $keys->{$b} } keys %$keys;	# all keys in this key set in the order added
    push @dkeys, @keys;
    delete @{$kh}{@keys};	# delete remaining keys in key set
  }
  $self->[7]->{DELETE}->($self,\@dkeys,\@vix) if $self->[7];
  delete @{$vh}{@vix};		# delete and return values in delete key order
} # NOTE: does not look like 'delete' does a wantarray

sub EXISTS {
  $_[0]->[5] = undef;	# clear crumbs
  return undef unless exists $_[0]->[0]->{$_[1]};
  $_[0]->[7]->{EXISTS}->(@_) if $_[0]->[7];	# ($key)
  1;
}

sub FIRSTKEY {
  keys %{$_[0]->[0]};	# reset iterator
  &NEXTKEY;
}

sub NEXTKEY {
#  defined (my $key = each %{$_[0]->[0]}) or return undef;
#  return $key;
  $_[0]->[5] = undef;		# clear crumbs
  my($key,$vi) = each %{$_[0]->[0]};
  $_[0]->[7]->{NEXT}->($_[0],$key,$vi) if $_[0]->[7] && defined $key;
  $key;
}

# delete all key, value sets
sub _clear {
  my $self = shift;
  $self->[3] = 0;
  $self->[4] = 0;
  $self->[5] = undef;
  %{$self->[0]} = ();		# empty existing hashes
  %{$self->[1]} = ();
  %{$self->[2]} = ();
  $self;
}

sub CLEAR {
  my $self = &_clear;
  $self->[7]->{CLEAR}->($self) if $self->[7];
  $self;
}

sub SCALAR {
  $_[0]->[5] = undef;		# clear crumbs
# no extension
  scalar %{$_[0]->[0]};
}

=over 4

=item * $thm = tie %hash,'Tie::Hash::MultiKey' ,%optional_ex

Ties a %hash to this package for enhanced capability and returns a method
pointer.

  my %hash;
  my $thm = tie %hash,'Tie::Hash::MultiKey';

Extension of this module is discussed in detail below.

=item * $thm = tied %hash;

Returns a method pointer for this package.

=item * untie %hash;

Breaks the binding between a variable and this package. There is no affect
if the variable is not tied.

B<REMEMBER> that if you have created a reference to the tied hash, untie
will not work until that binding is broken. This means that the object will
not be destroyed or garbage collected and the memory will not be reclaimed.

i.e	WRONG

  $thm = tie %h, 'Tie::Hash::MultiKey';
  ... code ...
  untie %h;

	RIGHT

  $thm = tie %h, 'Tie::Hash::MultiKey';
  ... code ...
  undef $thm;
  untie %h;

=item * ($href,$thm) = new 'Tie::Hash::MultiKey' ,%optional_ex

This method returns an UNBLESSED reference to an anonymous tied %hash.

  input:	none
  returns:	unblessed tied %hash reference,
		object handle

To get the object handle from \%hash use this.

	$thm = tied %{$href};

In SCALAR context it returns the unblessed %hash pointer. In ARRAY context it returns
the unblessed %hash pointer and the package object/method  pointer.

=cut

sub new {
  my($proto,@args) = @_;
  my $class = ref $proto || $proto || __PACKAGE__;
  my %x;
  my $thm = tie %x, $class, @args;
  return wantarray ? (\%x,$thm) : \%x;
}

=item * $val = $thm->addkey('new_key' => 'existing_key');

Add one or more keys to the shared key group for a particular value.

  input:	array or array_ref,
		existing_key
  returns:	hash value
	    or	dies with stack trace

Dies with stack trace if B<existing_key> does not exist OR if B<new> key
belongs to another key set.

Arguments may be a single SCALAR, ARRAY, or ARRAY_REF

=cut

sub addkey {
  my $self = shift;
  $self->[5] = undef;
  my($kh,$vh,$sh) = @{$self};
  my($key,@new) = &_flip;
  croak "key '$key' does not exist\n" unless exists $kh->{$key};
  my $vi = $kh->{$key};
  foreach(@new) {
    if (exists $kh->{$_} && $kh->{$key} != $vi) {
      my @kset = sort { $sh->{$vi}->{$a} <=> $sh->{$vi}->{$b} } keys %{$sh->{$vi}};
      croak "key belongs to key set @kset\n";
    }
    $sh->{$vi}->{$_} = $self->[4]++;
    $kh->{$_} = $vi;
  }
  $self->[7]->{ADDKEY}->($self,$key,$vi,\@new) if $self->[7];
  $self->_rordvals() if $self->[4] > $indexmax;
  return $vh->{$vi};
}    

=item * $val = ->remove('key');

=item * $val = ->delkey('key');	alias for above

Remove one or more keys from the shared key group for a particular value 
If this operation removes the LAST key, then it performs a DELETE which is the same as:

	delete $hash{key};

B<remove> returns a reverse list of the removed value's by key

  i.e.	@val = remove(something);
   or	$val = remove(something);

Arguments may be a single SCALAR, ARRAY or ARRAY_REF

=cut

# DELETE above does
#	array of deleted keys, array of deleted value indices
# $self->[7]->{DELETE}->($self,\@dkeys,\@vix) if $self->[7];
#
# sub delete	DELETE a key
*delkey = \&remove;
sub remove {
  my($self,@ks) = @_;
  my($kh,$vh,$sh) = @{$self};
  $self->[5] = undef;
  my $ks = ref $ks[0] ? $ks[0] : \@ks;	# extract reference is first element was an array ref of keys
  my @keys = @{_wash($ks)};
  my @vals;
  foreach my $key (@keys) {
    if (exists $kh->{$key}) {
      my $vi = $kh->{$key};
      delete $kh->{$key};
      unshift @vals, $vh->{$vi};
      delete $sh->{$vi}->{$key};
      unless (keys %{$sh->{$vi}}) {	# if last element in set
	delete $sh->{$vi};		# delete set values and keys
	delete $vh->{$vi};
	$self->[7]->{DELETE}->($self,[$key],[$vi]) if $self->[7];	# delete last key extension
      } else {
	$self->[7]->{DELKEY}->($self,$key,$vi) if $self->[7];	# not last key
      }
    } else {	# bogus key
      unshift @vals, undef;
    }
  }
  return wantarray ? @vals : $vals[0];
  $ks = \&delkey;			# never reached, suppress warning
}

=item * @ordered_keys = $thm->keylist('foo');

=item * @allkeys_by_order = $thm->keylist();

Returns all the keys in the group that includes the KEY 'foo' in the order
that they were added to the %hash;

If no argument is specified, returns all the keys in the %hash in the order
that they were added to the %hash

  input:	key or EMPTY
  returns:	@ordered_keys

  returns:	() if $key is not in the %hash

=cut

sub keylist {
  my($self,$key) = @_;
  $self->[5] = undef;
  my($kh,$vh,$sh) = @{$self};
  if (defined $key) {
    return () unless exists $kh->{$key};
    my $vi = $kh->{$key};
    return sort { $sh->{$vi}->{$a} <=> $sh->{$vi}->{$b} } keys %{$sh->{$vi}};
  }
  my %ak;			# key => order
  foreach(keys %{$sh}) {
    my @keys = keys %{$sh->{$_}};
    @ak{@keys} = @{$sh->{$_}}{@keys};
  }
  return sort { $ak{$a} <=> $ak{$b} } keys %ak;
}

=item * @keys = $thm->slotlist($i);

Returns one key from each key group in position B<$i>.

  i.e.
	$thm = tie %hash, 'Tie::Hash::MultiKey';

	$hash{['a','b','c']} = 'one';
	$hash{['d','e','f']} = 'two';
	$hash{'g'}           = 'three';
	$hash{['h','i','j']} = 'four';

	@slotkeys = $thm->slotlist(1);

  will produce ('b','e', undef, 'i')

All the keys at index '1' for the groups to which they were added, in the
order which the FIRST KEY in the group was added to the %hash. If there is no key in the
specified slot, an undef is returned for that position.

=cut

sub slotlist($$) {
  my($self,$i) = @_;
  $self->[5] = undef;
  my($kh,$vh,$sh) = @{$self};
  my %kbs;			# order => key
  foreach(keys %{$sh}) {
    my $slot = $sh->{$_};
    my @keys = sort { $slot->{$a} <=> $slot->{$b} } keys %{$slot};
    my $key = $keys[$i];
    $kbs{$slot->{pop @keys}} = $key; # undef is there is no key
  }
  my @order = sort { $a <=> $b } keys %kbs;
  return @kbs{@order};
}

=item * $thm->size;

Returns the number of ITEMS in the hash (not the number of keys). Should be
faster than ... scalar @values

=cut

sub size {
  $_[0]->[5] = undef;
  return scalar values %{$_[0]->[1]};
}

=item * $thm->consolidate;

USE WITH CAUTION

Consolidate all keys with the same values into common groups.

  returns: number of consolidated key groups

=cut

# added 3 sorts to keep key order constant across multiple platforms for testing purposes
# while this is inefficient, this method should rarely be used by competent developers

sub consolidate {
  my $self = shift;
  $self->[5] = undef;
  my($kh,$vh,$sh) = @{$self};
# $kbv  value => [keys]
# $ko   keys => order
# $ovm  value => [old vi order]
  my (%kbv,%ko,%ovm);	# keys by value, key order, old vi order by value
  foreach my $vi (sort keys %$vh) {	# sort for cross platform testing	***
    my $v = $vh->{$vi};
#  while (my($vi,$v) = each %$vh) {
# consolidate key sets of shared keys
    if (exists $ovm{$v}) {
      push @{$ovm{$v}}, $vi;
    } else {
      $ovm{$v} = [$vi];
    }
    my @keys = sort keys %{$sh->{$vi}};	# sort for cross platform testing	***
    @ko{@keys} = @{$sh->{$vi}}{@keys};	# preserve key order
    if (exists $kbv{$v}) {		# have key group?
      push @{$kbv{$v}}, @keys;		# add keys
    } else {
      $kbv{$v} = [@keys]; 	# start new key group
    }
  }
  my $ko = $self->[4];		# save next key order number
  _clear($self);
  my %nvi2ovi;
  foreach my $v (sort keys %kbv) {	# sort for cross platform testing	***
    my @k = @{$kbv{$v}};
#  while (my($v,$k) = each %kbv) {	# values by key
    my $indx = $self->[3]++;
    $nvi2ovi{$indx} = $ovm{$v};		# create new => [old] map
    $vh->{$indx} = $v;			# value
    @{$sh->{$indx}}{@k} = @ko{@k};	# restore shared keys and order
    map { $kh->{$_} = $indx } @k;
  }
  $self->[4] = $ko;
  $self->[7]->{CONSOLD}->($self,\%kbv,\%ko,\%nvi2ovi) if $self->[7];
  $self->_rordkeys() if $self->[3] > $indexmax;
  $self->[3];
}

=item @ordered_vals = $thm->vals();

Return a list of values in the order they were added.

=cut

sub vals {
  $_[0]->[5] = undef;
  map { $_[0]->[1]->{$_} } sort { $a <=> $b } keys %{$_[0]->[1]};
}

=item * ($href,$thm) = $thm->clone();

This method returns an UNBLESSED reference to an anonymous tied %hash that
is a deep copy of the parent object.

  input:	none
  returns:	unblessed tied %hash reference,
		object handle

To get the object handle from \%hash use this.

	$thm = tied %{$href};

In SCALAR context it returns the unblessed %hash pointer. In ARRAY context it returns
the unblessed %hash pointer and the package object/method  pointer.

  i.e.
	$newRef = $thm->clone();

	$newRref->{'a','b'} = 'content'

	$newThm = tied %{$newRef};

=item * $new_thm = $thm->copy(tie %new,'Tie::Hash::MultiKey');

This method deep copies a MultiKey %hash to another B<new> %hash. It may
be invoked on an existing tied object handle or a reference to a tied %hash.

  input:	object handle OR reference to tied %hash
  returns:	object handle / method pointer

  i.e
	$thm = tie %hash,'Tie::Hash::MultiKey';
	$newThm = $thm->copy(tie %new,'Tie::Hash::MultiKey');
  or
	tie %new,'Tie::Hash::MultiKey');
	$newThm = $thm->copy(\%new);

NOTE: this method duplicates the data stored in the parent %hash,
overwriting and destroying anything that may have been stored in the copy
target.

=back

=cut

sub copy {
  my($self,$copy) = @_;
  croak "no target specified\n"
	unless defined $copy;
  croak "argument is not a ", (ref $self) ," object\n"
	unless ref $copy eq ref $self || (ref $copy eq 'HASH' && ref ($copy = tied %$copy) eq ref $self);
  CLEAR($copy) unless $copy->[3] == 0;	# skip if empty hash
  _copy($self,$copy);
}

sub clone {
  my($href,$copy) = &new;
  _copy($_[0],$copy);
  return wantarray ? ($href,$copy) : $href;
}

sub _copy {
  my($self,$copy) = @_;
  $self->[5] = undef;
  my($kh,$vh,$sh) = @{$self};
  my @keys = keys %$kh;
  my @vals = @{$kh}{@keys};
  my($ckh,$cvh,$csh) = @{$copy};
  @{$ckh}{@keys} = @vals;		# clone keys
  @{$cvh}{@vals} = @{$vh}{@vals};	# clone value index
  foreach (@vals) {
    @keys = keys %{$sh->{$_}};
    @{$csh->{$_}}{@keys} = @{$sh->{$_}}{@keys};
  }
  @{$copy}[3,4,5] = @{$self}[3,4,5];
  if ($self->[7]) {			# if extensions
#    $copy->[7] = $self->[7];		# copy extension pointers
    @vals = keys %{$vh};
    $self->[7]->{COPY}->($self,$copy,\@vals);
  }
  $copy;
}

# belt and suspenders routines in case the indices or order index get to big

sub _rordkeys {
  my $self = shift;
  my $nord = 0;				# new order
  my $sh = $self->[2];
  my $osh = {};				# a hash of all old shared keys with their order
  foreach (keys %$sh) {
    my @keys = keys %{$sh->{$_}};
    @{$osh}{@keys} = @{$sh->{$_}}{@keys};
  }
  my %rsh = reverse %$osh;		# reverse array to reorder unique numeric order numbers
  my $nsh = {};				# new shared order hash
  %$nsh = map { ($rsh{$_}, $nord++) } sort { $a <=> $b } keys %rsh;
  foreach (keys %$sh) {
    my @keys = keys %{$sh->{$_}};
    @{$sh->{$_}}{@keys} = @{$nsh}{@keys};	# replace old order with new order
  }
  $self->[7]->{REORDERK}->($self,$nsh) if $self->[7];
  $self->[4] = $nord;
}

sub _rordvals {
  my $self = shift;
  my $ni = 0;				# new index
  my($kh,$vh,$sh) = @{$self};
  my $nvh = {};				# new value hash
  my $nsh = {};				# new shared key hash
  my %kmap;				# map for primary key hash and value hash
  foreach (sort keys %$vh) {		# vh and sh share common keys
    $nvh->{$ni} = $vh->{$_};
    $nsh->{$ni} = $sh->{$_};
    $kmap{$_} = $ni++;
  }
  foreach(keys %$kh) {
    $kh->{$_} = $kmap{$kh->{$_}};	# replace old index pointer with new index pointer
  }
  @{$self}[1,2,3] = ($nvh,$nsh,$ni);
  $self->[7]->{REORDERV}->($self,\%kmap) if $self->[7];	# if extensions
}

sub DESTROY {}

1;

__END__

=head1 COMMON OPERATIONS

A tied multikey %hash behave like a regular %hash for most operations;

B<$value = $hash{$key}> returns the key group value

B<$hash{$key} = $value> sets the value for the key group

  i.e. all keys in the group will return that value

B<$hash{$key1,$key2} = $value> assigns $value to the key
key group consisting of $key1, $key2 if they do not.
If at least one of the keys already exists, the remaining
keys are assigned to the key group and the value is set
for the entire group.

B<Better> syntax $hash{[$key,$key]} = $value;

B<delete $hash{$key}> deletes the ENTIRE key group
to which B<$key> belongs.

B<delete $hash($key1,$key2)> deletes ALL groups
to which $key1 and $key2 belong.

B<Better> syntax delete $hash{[$key1,$key2]};

B<keys %hash> returns all keys.

B<values %hash> returns all values

NOTE: that this will not be the same number of
items as returned by B<keys> unless there are no
key groups containing more than one key.

B<($k,$v) = each %hash> behaves as expected.

References to tied %hash behave in the same manner as regular %hash's except
as noted for multiple key values above.

=head1 LIMITATIONS

SLICE operations will produce unusual results if you try to use regular
ARRAYS to specify key groups in the slice. Tie::Hash::MultiKey %hash's only
accept SCALAR or ARRAY_REF arguments for SLICE and direct assigment.

  i.e.
	%WRONG = (
		one	=> 1,
		two	=> 2,
		(3,4,5)	=> 12 # expands to 3 => 4, 5 => 12
	);

	%hash = ( # OK
		one	=> 1,
		two	=> 2,
		[3,4,5]	=> 12
	);

will produce a psuedo hash of the form:

	%hash = (
		one	=> 1,
		two	=> 2,
		3	=> 12, --|
		4	=> 12, --|
		5	=> 12  --|
	);

where the operation B<$hash{4} = 99> will change the hash to:

	%hash = (
		one	=> 1,
		two	=> 2,
		3	=> 99, --|
		4	=> 99, --|
		5	=> 99  --|
	);

Example: $hp = \%hash;

  @{$hp}{'one','two','[3,4,5]} = (1,2,12);

produces the same result as above. If the hash already contains a KEY of the
same name, the value will be changed for all other shared keys.

 --------------------------

If you are using ARRAY_REF's as keys (not as pointers to keys as above) they
must be blessed into some other package so that 

	ref $key ne 'ARRAY'

i.e.	bless $key, 'KEY'; # or anything other than 'ARRAY'

 --------------------------

Example SLICE assignments

TO tied hash

	@tiedhash{@keys} = @values;

	$hp = \%tiedhash;
	@{$hp}{@keys} =  @values;

FROM tied hash

	@values = @tiedhash{@keys};

	$hp = \%tiedhash;
	@values = @{$hp}{@keys};

NOTE: when assigning TO the hash, keys may be ARRAY_REF's as described
above.

=head1 Extension of this module

This module has extension capabilities that allow adding features to the
characteristics of the elements within the tied hash. For example, knowing 
the order that items in the hash are accessed as in a cache where older
items are timed out and removed from the cache.

The extensions can be customized to a particular instance of a tied object.
This means that extensions can be embodied as a new module or as
customization within a Perl program for a particular object instance.

Requirements:

An extension 6 B<R>equired and 7 B<O>ptional callback subrefs to support the following operations:

  TIE	    O	create the tied object extension
  FETCH	    R	recall value operations
  STORE	    R	save and update operations
  DELETE    R	delete key set + value operations
  EXISTS    O	checking to see if key exists
  NEXT	    O	iterative operations (Perl each)
  COPY	    R	hash copy and clone operations
  CLEAR	    R	hash clear operations
  ADDKEY    O	add a key to existing key set
  DELKEY    O	delete a key from an existing key set
  REORDERK  O	operation to re-order the key indices
		that tracks the order that keys are
		added to the tied hash
  REORDERV  R	operation to re-order the value indices
		for values belonging to unique key sets
  ...one or more data elements with any key name
     as required by the extension
  CONSOLD   O	operation to consolidate keys that
		have a common value

  DATAn		any scalar, array_ref, hash_ref

Usage:

  require Tie::Hash::MultiKey;

  tie %x, 'Tie::Hash::MultiKey',
	TIE	 =>	$subref_tie,
	FETCH	 =>	$subref_fetch,
	STORE	 =>	$subref_store,
	DELETE	 =>	$subref_delete,
	EXISTS	 =>	$subref_exists,
	NEXT	 =>	$subref_next,
	CLEAR	 =>	$subref_clear
	COPY	 =>	$subref_copy,
	ADDKEY	 =>	$subref_addkey,
	DELKEY	 =>	$subref_delkey
	REORDERK =>	$subref_Korder,
	REORDERV =>	$subref_Vorder,
	CONSOLD	 =>	$subref_consolidate;

  The extension may also be provisioned as a hash_ref.

NOTE: about internal re-ordering.

If the tied object has new keys or key sets added more than 2^48 times, the
internal accounting mechanism will re-order the indices to prevent the
pointers from converting from unique integer value to floats. Extensions
that are tied either to the order of key addition or values for a key set
must correct their associated pointers to match internal re-ordering.

  See:	t/Extension.t for usage and testing examples
  See:	Tie::Hash::MultiKeyCache for implementation

The callbacks return the following arguments:

	$sub___tie->($self)
	$sub_clear->($self)

  A pointer to pre-extension blessed tied hash object

  IMPORTANT: add extension storage to

	$self->[16] and beyond
 -
	$sub_fetch->($self,$key,$valueindex)
	$sub__next->($self,$key,$valueindex)

  next is called ONLY if the key exists and
  is immediately followed by a call to the internal
  FETCH method. Normally no action should be done.

  A pointer to the the tied hash object
  The original key used for the call to fetch
  The internal value index hash key

NOTE: the primary key hash $self->[0] must not be touched by the
$sub_next extension or it will mess up the Perl iterator.

 -
	$sub_store->($self,\@keys,$valueindex)

  A pointer to the tied hash object
  A pointer to an array of the keys for the store
  The internal value index hash pointer
 -
	$sub_delete->($self,$kp,$vp)

  A pointer to the tied hash object
  A pointer to an ordered array of the deleted keys
  A pointer to an ordered array of the deleted values
 -
	$sub_exists->($self,$key)

  exists is called ONLY if the key exists;

  A pointer to the the tied hash object
  The original key used for the operation
 -

	$sub_addkey->($self,$key,$valueindex,\@newkeys)

  A pointer to the tied hash object
  The reference key used to identify the key set
  The internal value index for key set
  A list of new keys added
 -

	$sub_delkey->($self,$key,$vi)

  A pointer to the tied hash object
  The value of the key being deleted
  The internal value index for the key set
  else false

Calls extension_sub_delete if the key is the last key of a key set.

 -
	$sub_copy->($self,$copy,\@valueindex)

  A pointer to the tied hash object
  A pointer to the tied hash copy object
  A pointer to an array internal value index keys
 -
	$sub_Korder->{$self,\%reorderK)

  A pointer to the tied hash object
  A pointer to a hash of the reorder
  key order transfomation

	key => new_order_value
 -
	$sub_Vorder->($self,\%reorderV)

  A pointer to the tied hash object
  A pointer to a hash of the reorder to
	value hash transformation

	old_order => new_ord

 -
	$sub_consolidate->($self,\%kbo,\%ko,\%n2o)

  A pointer to the tied hash object
  A pointer to a hash as consolidated of
	value => [keys]
  A pointer to hash as consolidated of 
	keys => order
  A pointer to hash of
	new vi => [old vi order]
  %n2o is a map of new value indices after
  consolidation to an array of old value
  indices. i.e. if there were tow values
  belonging to different key sets then there
  would be two vi's in the old order array
  represented by the single vi key.
 -

The internal structure of the tied hash object is as follows:

[

 0  =>	{	# $kh
	key	=> vi     # value index for 1 & 2 below
	},
 1  =>	{	# $vh
	vi	=> value, # contains value for the key set
	},
 2  =>	{	# $sh	pointer to hash list keys in a key set
	vi	= {key1 => order1, key2 => order2, ...},
	},
 3  =>	vi,	# numeric value of next value index
 4  =>	or,	# numeric value of next key order
 5  =>	crumbs	# STORE key value
 6  =>	reserved
 7  =>  {	# extensions
   FETCH    => subref,	# required
   STORE    => subref,	# required
   DELETE   => subref,	# required
   COPY     => subref,	# required
   CLEAR    => subref,	# required
   REORDERV => subref,	# required
   TIE      => subref,	# optional
   EXISTS   => subref,	# optional
   NEXT     => subref,	# optional
   ADDKEY   => subref,	# optional
   DELKEY   => subref,	# optional
   REORDERK => subref,	# optional
   CONSOLD  => subref, # optional
 ... one or more data keys
   DATAn     => scalar, array_ref, hash_ref
 }
];

Extension writers should store new information in the indices 16 and up.

Developers of extensions are encouraged to read the code.

=head1 AUTHOR

Michael Robinton, <miker@cpan.org>

=head1 COPYRIGHT

Copyright 2014, Michael Robinton

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;
