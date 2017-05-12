#                              -*- Mode: Perl -*- 
# Cache.pm -- 
# Author          : Ulrich Pfeifer
# Created On      : Mon May 13 11:14:06 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Apr  3 11:43:04 2005
# Language        : CPerl
# Update Count    : 17
# Status          : Unknown, Use with caution!

package Text::German::Cache;

sub new {
  my $type = shift;
  my $self = {};
  my %para = @_;

  $self->{Function} = $para{Function} || \&Text::German::reduce;
  $self->{Hold}     = $para{Hold}     || 100;
  $self->{Gc}       = $para{Gc}       || 2 * $self->{Hold};
  $self->{Verbose}  = $para{Verbose}  || 0;
  $self->{Entries}  = 0;
  $self->{Contents} = {};
  $self->{Hit}      = {};
  $self->{Hits}     = 0;
  $self->{Misses}   = 0;
  bless $self, ref($type) || $type;
}

sub get {
  my $self = shift;
  my $key  = shift;

  if (defined $self->{Contents}->{$key}) {
    $self->{Hits}++;
    $self->{Hit}->{$key}++;
  } else {
    $self->{Misses}++;
    $self->{Entries}++;
    if ($self->{Entries} >= $self->{Gc}) {
      $self->gc;
    }
    $self->{Contents}->{$key} = &{$self->{Function}}($key);
  }
  $self->{Contents}->{$key};
}

sub gc {
  my $self = shift;
  my %rank;
  my $rank;
  
  if ($self->{Verbose}) {
    printf (STDERR "Cache: enter garbadge collect %d\n", $self->{Entries});
  }
  for (keys %{$self->{Contents}}) {
    push @{$rank{$self->{Hit}->{$_}}}, $_;
  }
  for $rank (sort {$a <=> $b} keys %rank) {
    for (@{$rank{$rank}}) {
      if ($self->{Verbose}) {
        printf (STDERR "Cache: deleting $_(%d)\n", $rank+1);
      }
       delete $self->{Contents}->{$_};
       delete $self->{Hit}->{$_};
       $self->{Entries}--;
     }
    # We delete a complete rank. this is more than we must do ..
    last if $self->{Entries} <= $self->{Hold};
  }
  if ($self->{Verbose}) {
    printf (STDERR "Cache: leave garbadge collect %d\n", $self->{Entries});
  }
}

sub DESTROY {
  my $self = shift;

  if ($self->{Verbose}) {
    printf (STDERR "\nCache Hits: %d\tMisses: %d\n", $self->{Hits}, $self->{Misses});
  }
}

1;
