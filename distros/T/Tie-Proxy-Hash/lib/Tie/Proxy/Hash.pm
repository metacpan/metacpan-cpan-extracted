# (X)Emacs mode: -*- cperl -*-

package Tie::Proxy::Hash;

=head1 NAME

Tie::Proxy::Hash - Effieciently merge & translate hashes.

=head1 SYNOPSIS

  my (%hash, $ref);
  $ref = tie %hash, 'Tie::Proxy::Hash', (bart   => +{a =>  1,
                                                     b =>  2},
                                         maggie => +{a =>  5,
                                                     c =>  6,
                                                     e => 10},
                                                   );
  $hash{a} ==  1;     # true
  $hash{b} ==  2;     # true (bart supercedes maggie)
  $hash{c} ==  6;     # true
  ! defined $hash{d}; # true
  $hash{e} == 10;     # true

  $hash{c} = 9;       # set in maggie
  $hash{d} = 12;      # set in default
  $hash{f} = 11;      # set in default

  $ref->add_hash('lisa', +{d => 3, b => 4});
  $hash{c} == 9;      # true
  $hash{b} == 2;      # true (bart overrides lisa)
  $hash{d} == 3;      # true (lisa overrides default)
  $hash{f} == 11;     # true (only default knows 'f')


=head1 DESCRIPTION

Proxy hash requests for one or more other hashes, with intermediate value
translation.

Tie::Proxy::Hash 'merges' hashes by maintaining a list of hashes to look up,
and each key requested is looked up in each hash in order until a hit is
found.  Resultant values may be subject to a translating subr.  In this way,
hashes may be merged without the cost of by-value copying.

A default backing hash is provided to store values not present in other
hashes.

=cut

# ----------------------------------------------------------------------------

# Pragmas -----------------------------

require 5.005_62;
use strict;
use warnings;

# Inheritance -------------------------

use base qw( Exporter );
our @EXPORT_OK = qw( $PACKAGE $VERSION );

# Utility -----------------------------

use Carp                    qw( carp croak );

# ----------------------------------------------------------------------------

# CLASS METHODS --------------------------------------------------------------

# -------------------------------------
# CLASS CONSTANTS
# -------------------------------------

our $PACKAGE = 'Tie-Proxy-Hash';
our $VERSION = '1.01';

# -------------------------------------
# CLASS CONSTRUCTION
# -------------------------------------

# -------------------------------------
# CLASS COMPONENTS
# -------------------------------------

# -------------------------------------
# CLASS HIGHER-LEVEL FUNCTIONS
# -------------------------------------

=head2 Tying

 $ref = tie %hash, 'Tie::Proxy::Hash',
          bart   => +{a =>  1, b =>  2},
          maggie => +{a =>  5, c =>  6, e => 10} => sub {10*$_[0]},
        ;

Any arguments passed to C<tie> are palmed off onto L<add_hash|add_hash>.

=cut

sub TIEHASH {
  my $instance = $_[0]->new;

  for (my $i=1; $i < @_; $i+=2) {
    croak sprintf('TIEHASH (%s): trailing arg found: %s',
                  $_[0],
                  ref($_[$i]) ||
                    (defined($_[$i]) ? "Simple value '$_[$i]'" : '*undef*'))
      if $i+1 >= @_;

    if ( $i+2 <= $#_ and  UNIVERSAL::isa($_[$i+2], 'CODE') ) {
      $instance->add_hash(@_[$i..$i+2]);
      $i++;
    } else {
      $instance->add_hash(@_[$i..$i+1]);
    }
  }

  return $instance;
}

# -------------------------------------
# CLASS HIGHER-LEVEL PROCEDURES
# -------------------------------------

# INSTANCE METHODS -----------------------------------------------------------

# -------------------------------------
# INSTANCE CONSTRUCTION
# -------------------------------------

sub new {
  my $class = ref $_[0] || $_[0];

  return bless +{' default' => +{},' order' => [],' translate' => +{}}, $class;
}

# -------------------------------------
# INSTANCE FINALIZATION
# -------------------------------------

# -------------------------------------
# INSTANCE COMPONENTS
# -------------------------------------

# -------------------------------------
# INSTANCE HIGHER-LEVEL FUNCTIONS
# -------------------------------------

=head2 Retrieving Values

Values are retrieved by checking each hash in the order of insertion; the
first hash found in which a given key exists supplies the value.  The value is
subject to translation if the given hash has an associated translator.

=cut

sub FETCH {
  for (@{$_[0]->{' order'}}, ' default') {
    return exists $_[0]->{' translate'}->{$_}                  ?
           $_[0]->{' translate'}->{$_}->($_[0]->{$_}->{$_[1]}) :
           $_[0]->{$_}->{$_[1]}
      if exists $_[0]->{$_}->{$_[1]};
  }

  return;
}

sub EXISTS {
  for (@{$_[0]->{' order'}}, ' default') {
    return 1
      if exists $_[0]->{$_}->{$_[1]};
  }

  return;
}

sub FIRSTKEY {
  $_[0]->{' iterate'} = @{$_[0]->{' order'}} ? 0 : -1;
  $_[0]->{' keys'}    = +{};
  return $_[0]->NEXTKEY;
}

sub NEXTKEY {
  my $self = shift;

  my $counter = $self->{' iterate'};

  my $hash = ($counter > -1                          ?
              $self->{$self->{' order'}->[$counter]} :
              $self->{' default'});

  my $key;
  $key = each %$hash
    if defined $hash;

  while ( ! defined $hash                or
          ! defined $key                 or
          exists $self->{' keys'}->{$key} ) {
    if ( $counter > -1 and $counter < @{$self->{' order'}} - 1 ) {
      $counter++;
      $hash = $self->{$self->{' order'}->[$counter]};
    } elsif ( $counter != -1 ) {
      $counter = -1;
      $hash = $self->{' default'};
    }

    if ( defined $hash ) {
      do {
        $key = each %$hash;
      } until ((! defined $key) or (! exists $self->{' keys'}->{$key}));
    }

    last if ! defined $key and $counter == -1;
  }

  if ( ! defined $key ) {
    delete $self->{' iterate'};
  } else {
    $self->{' iterate'} = $counter;
    $self->{' keys'}->{$key} = undef;
  }

  return $key;
}

# -------------------------------------
# INSTANCE HIGHER-LEVEL PROCEDURES
# -------------------------------------

=head1 INSTANCE HIGHER-LEVEL PROCEDURES

Z<>

=cut

=head2 add_hash

=over 4

=item SYNOPSIS

  $ref->add_hash('bart', +{ a => 1, b => 2 });
  $ref->add_hash('lisa', +{ c => 3, b => 4 }, sub { $_[0] * 20 });

=item ARGUMENTS

=over 4

=item name

The name by which to refer to the hash (for future manipulations, e.g.,
L<remove_hash|remove_hash>).  The name must be a valid perl identifier --- a
non-empty string of word characters not beginning with a digit.

If a member with the given name already exists, the hash is updated (and the
translator is updated/inserted/removed accordingly), but the order does not
change.  Hence, following the synopsis by calling

  $ref->add_hash('bart', +{ a => 5, b => 6 });

(without an intervening C<remove_hash>) will set the effective value of C<b>
to 6, for the new 'bart' hash will still be checked before the 'lisa' hash.

If a member with the given name does not already exist (including if it was
deleted with L<remove_hash|remove_hash>), the hash is added at the end of the
queue.

Hashes inserted with C<add_hash> are always checked before the default hash,
even if the default hash has values that were set prior to the named hash(es)
being inserted.

=item hash

The hash to add in, as a hashref.  For efficiency, this hash is stored within
as is.  Therefore, if a reference to the same hash is manipulated externally,
these manipulations will be visible to the Proxy Hash.  Caveat Emptor.

=item translator

B<Optional>.  If defined, all values retrieved from this hash are run through
the given code ref before being returned to the caller.  The subr is called
with a single argument, the hash value, and is expected to return a single
value (which is passed back to the caller).

The translator is only called to translate values for which keys exist in the
given hash; the translator is never called to create new values.

The presence of a translator prevents any values being set in the hash (via
the C<Tie::Proxy::Hash> interface) (since there is no reverse translation
facility).  Therefore, if a value is set that would otherwise be stored in a
translated hash, the key in that hash is deleted instead (to maintain the
identity C<$h{c} = $x; $h{c} == $x>).  The storage then falls through to the
next untranslated hash (possibly the default hash).  This is why the default
hash has no translator.

  my ($ref, %hash);
  $ref = tie %hash, 'Tie::Proxy::Hash';
  $ref->add_hash('bart', +{ a => 1, b => 2 });
  $ref->add_hash('lisa', +{ c => 3, b => 4 }, sub { $_[0] * 20 });
  $hash{c} = 5; # Sets c in the default hash, deletes 3 from lisa.

=back

=back

The order of calling C<add_hash> is relevant; each hash is checked in order of
insertion via C<add_hash>.  Therefore, given the example in the synopsis, the
'bart' hash is checked for values before the 'lisa' hash.  Hence the effective
value of C<b> is 2.

=cut

sub add_hash {
  croak "add_hash: Illegal hash name: '$_[1]'"
    unless $_[1] =~ /^(?!\d)\w+$/;
  croak sprintf('add_hash: Arg 2 must be a hashref (got %s)',
                defined $_[2] ?
                (ref $_[2] || "Simple value: '$_[2]'") : '*undef*')
    unless UNIVERSAL::isa($_[2], 'HASH');
  croak sprintf('add_hash: Arg 3 must be a code ref (if defined) (got %s)',
                ref $_[2] || "Simple value: '$_[2]'")
    if defined $_[3] and ! UNIVERSAL::isa($_[3], 'CODE');

  my $exists = exists $_[0]->{$_[1]};
  $_[0]->{$_[1]} = $_[2];
  unless ( $exists ) { # Don't re$-add existing hashes
    push @{$_[0]->{' order'}}, $_[1];
  }
  if ( defined $_[3] ) {
    $_[0]->{' translate'}->{$_[1]} = $_[3];
  } else {
    delete $_[0]->{' translate'}->{$_[1]};
  }
}

# -------------------------------------

=head2 remove_hash

=over 4

=item SYNOPSIS

  $ref->remove_hash('bart');

=item ARGUMENTS

=over 4

=item name

Name of the member hash to remove.  An exception will be raised if no such
member exists.

=back

Removing a hash wipes any present translation, and the named hash loses its
place in the queue.

=back

=cut

sub remove_hash {
  croak "remove_hash: Illegal hash name: '$_[1]'"
    unless $_[1] =~ /^(?!\d)\w+$/;
  croak "remove_hash: No such member: '$_[1]'"
    unless exists $_[0]->{$_[1]};

  delete $_[0]->{$_[1]};
  my $count = @{$_[0]->{' order'}};
  for (grep $_[0]->{' order'}->[$_] eq $_[1], map $count - $_, 1..$count) {
    splice @{$_[0]->{' order'}}, $_, 1;
  }
  delete $_[0]->{' translate'}->{$_[1]};
}

sub STORE {
  for (@{$_[0]->{' order'}}) {
    if ( exists $_[0]->{$_}->{$_[1]} ) {
      if ( exists $_[0]->{' translate'}->{$_} ) {
        delete $_[0]->{$_}->{$_[1]};
      } else {
        $_[0]->{$_}->{$_[1]} = $_[2];
        return;
      }
    }
  }

  $_[0]->{' default'}->{$_[1]} = $_[2];
  return;
}

sub DELETE {
  for (@{$_[0]->{' order'}}) {
    delete $_[0]->{$_}->{$_[1]}, return
      if exists $_[0]->{$_}->{$_[1]} and ! exists $_[0]->{' translate'}->{$_};
  }

  delete $_[0]->{' default'}->{$_[1]};
  return;
}

sub CLEAR {
  for (@{$_[0]->{' order'}}) {
    delete $_[0]->{$_};
  }

  $_[0]->{' order'}     = [];
  $_[0]->{' default'}   = +{};
  $_[0]->{' translate'} = +{};
}

# ----------------------------------------------------------------------------

=head1 EXAMPLES

Z<>

=head1 BUGS

Z<>

=head1 REPORTING BUGS

Email the author.

=head1 AUTHOR

Martyn J. Pearce C<fluffy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003 Martyn J. Pearce.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Z<>

=cut

1; # keep require happy.

__END__
