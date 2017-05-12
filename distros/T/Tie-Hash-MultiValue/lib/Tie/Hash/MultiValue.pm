package Tie::Hash::MultiValue;
use strict;
use Tie::Hash;
@Tie::Hash::MultiValue::ISA = qw(Tie::ExtraHash);

BEGIN {
	use vars qw ($VERSION);
	$VERSION     = 1.02;
}

=head1 NAME

Tie::Hash::MultiValue - store multiple values per key

=head1 SYNOPSIS

  use Tie::Hash::MultiValue;
  my $controller = tie %hash, 'Tie::Hash::MultiValue';
  $hash{'foo'} = 'one';
  $hash{'bar'} = 'two';
  $hash{'bar'} = 'three';

  # Fetch the values as references to arrays.
  $controller->refs;
  my @values  = @{$hash{'foo'}};   # @values = ('one');
  my @more    = @{$hash{'bar'}};   # @more   = ('two', 'three');
  my @nothing = @{$hash{'baz'}};   # empty list if nothing there

  # You can tie an anonymous hash as well.
  my $hashref = {};
  tie %$hashref, 'Tie::Hash::MultiValue';
  $hashref->{'sample'} = 'one';
  $hashref->{'sample'} = 'two';
  # $hashref->{'sample'} now contains ['one','two']

  # Iterate over the items stored under a key.
  $controller->iterators;
  while(my $value = $hash{bar}) {
    print "bar: $value\n";
  }
  # prints
  #   bar: two
  #   bar: three

=head1 DESCRIPTION

C<Tie::Hash::MultiValue> allows you to have hashes which store their values
in anonymous arrays, appending any new value to the already-existing ones.

This means that you can store as many items as you like under a single key,
and access them all at once by accessing the value stored under the key.

=head1 USAGE

See the synopsis for a typical usage.

=head1 BUGS

None currently known.

=head1 SUPPORT

Contact the author for support.

=head1 AUTHOR

	Joe McMahon
        CPAN ID: MCMAHON
	mcmahon@ibiblio.org
	http://ibiblio.org/mcmahon

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Tie::Hash, perl(1), Perl Cookbook (1st version) recipe 13.15, program 13-5.

=head1 METHODS

This class is a subclass of C<Tie::ExtraHash>; it needs to override the 
C<TIEHASH> method to save the instance data (in $self->[1]), and the C<STORE>
method to actually save the values in an anonymous array.

=head2 TIEHASH

If the 'unique' argument is supplied, we check to see if it supplies a 
subroutine reference to be used to compare items. If it does, we store that 
reference in the object describing this tie; if not, we supply a function 
which simply uses 'eq' to test for equality.

=head3 The 'unique' function

This funtion will receive two scalar arguments. No assumption is made about
whether or not either argument is defined, nor whether these are simple
scalars or references. You can make any of these assumptions if you choose,
but you are responsible for checking your input.

You can perform whatever tests you like in your routine; you should return 
a true value if the arguments are determined to be equal, and a false one
if they are not.

=cut

sub TIEHASH {
  my $class = shift;
  my $self = [{},{}];
  bless $self, $class;

  push @_, undef if @_ % 2 == 1;

  $self->refs;


  my %args = @_;
  if (exists $args{'unique'}) {
    if (defined $args{'unique'} and ref $args{'unique'} eq 'CODE') {
      $self->[1]->{Unique} = $args{'unique'};
    }
    else {
      $self->[1]->{Unique} = sub { 
                                   my ($foo, $bar) = @_;
                                   $foo eq $bar;
                                 };
    }
  }
  return $self;
}

=head2 STORE

Push the value(s) supplied onto the list of values stored here. The anonymous 
array is created automatically if it doesn't yet exist.

If the 'unique' argument was supplied at the time the hash was tied, we will
use the associated function (either yours, if you supplied one; or ours, if
you didn't) and only add the item or items that are not present.

=cut

sub STORE {
  my($self, $key, @values) = @_;

  if ($self->[1]->{Unique}) {
    # The unique test is defined; check the incoming values to see if
    # any of them are unique
    local  $_;
    foreach my $item (@values) {
      next if grep {$self->[1]->{Unique}->($_, $item)} @{$self->[0]->{$key}};
      push @{$self->[0]->{$key}}, $item;
    }
  }
  else {
    push @{$self->[0]->{$key}}, @values;
  }
}

=head2 FETCH

Fetches the current value(s) for a key, depending on the current mode
we're in.

=over 

=item * 'refs' mode

Always returns an anonymous array containing the values stored under this key,
or an empty anonymous array if there are none.

=item * 'iterators' mode

If there is a single entry, acts just like a normal hash fetch. If there are 
multiple entries for a key, we automatically iterate over the items stored 
under the key, returning undef when the last item under that key has been 
fetched. 

Storing more elements into a key while you're iterating over it will result
in the new elements being returned at the end of the list. If you've turned
on 'unique', remember that they won't be stored if they're already in the
value list for the key.

=over

B<NOTE>: If you store undef in your hash, and then store other values, the 
iterator will, when it sees your undef, return it as a normal value. This 
means that you won't be able to tell whether that's I<your> undef, or the 
'I have no more data here' undef. Using 'list' or 'refs' mode is strongly
suggested if you need to store data that may include undefs.

=back

Note that every key has its own iterator, so you can mix accesses across keys
and still get all the values:

  my $controller = tie %hash, 'Tie::Hash::MultiValue';
  $controller->iterators;
  $hash{x} = $_ for qw(a b c);
  $hash{y} = $_ for qw(d e f);
  while ( my($x, $y) = ($hash{x}, $hash{y}) {
     # gets (a,d) (b,e) (c,f)
  }

=back

=cut

sub FETCH {
    my($self) = @_;
    { 'refs'      => \&_FETCH_refs,
      'iterators' => \&_FETCH_iters,
    }->{ $self->[1]->{mode} }->(@_);
}

sub _FETCH_refs {
    my($self, $key) = @_;
    return $self->[0]->{$key};
}

sub _FETCH_iters {
  my($self, $key) = @_;
  # First, the simplest case. If we're fetching a key that doesn't exist,
  # just return undef, and don't bother iterating at all.
  return undef unless exists $self->[0]->{$key};

  # Regular fetch in scalar context. If we are not yet 
  # iterating, set up iteration over this key.
  if (! $self->[1]->{iterators} or ! $self->[1]->{iterators}->{$key}) {
    $self->[1]->{iterators}->{$key}->{iterator_index} = 0;
    $self->[1]->{iterators}->{$key}->{iterating_over} = $key;
  }
  # Iterator either just set up or already running.
  # Fetch the current entry for this key and bump the iterator
  # for next time. If we're out of entries, return an undef
  # and stop the iterator. We've already checked to see if there
  # is anything under this key, so the deref is safe.
  my $highest_index = @{ $self->[0]->{$key} } - 1;
  my $current_index = $self->[1]->{iterators}->{$key}->{iterator_index};
  if ($current_index > $highest_index) {
    # Out of elements (or there are none).
    $self->[1]->{iterators}->{$key} = undef;
    return undef;
  }
  else {
      # Return current value after bumping the iterator.
      $self->[1]->{iterators}->{$key}->{iterator_index} += 1;
      return $self->[0]->{$key}->[$current_index];
  }
}

=head2 iterators

Called on the object returned from tie(). Tells FETCH to return elements 
one at a time each time the key is accessed until no more element remain.

=cut

sub iterators {
    my($self) = @_;
    $self->[1]->{mode} = 'iterators';
    $self->[1]->{iterators} = {};
    return;
}

=head2 refs

Tells FETCH to always return the reference associated with a key. (This allows
you to, for instance, replace all of the values at once with different ones.)

=cut

sub refs {
    my($self) = @_;
    $self->[1]->{mode} = 'refs';
    $self->[1]->{iterators} = {};
    return;
}

=head2 mode

Tells you what mode you're currently in. Does I<not> let you change it!

=cut

sub mode {
    return $_[0]->[1]->{mode};
}

1; #this line is important and will help the module return a true value
__END__

