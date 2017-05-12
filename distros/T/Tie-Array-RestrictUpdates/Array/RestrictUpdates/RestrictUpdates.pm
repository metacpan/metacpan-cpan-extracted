package Tie::Array::RestrictUpdates;

use strict;
use Tie::Array;
use vars qw($VERSION @ISA);

$VERSION = '0.01';
@ISA = qw(Tie::Array);

sub TIEARRAY { 
 my $proto = shift;
 my $class = ref($proto) || $proto;
 my $self = {};
 $self->{_COUNTER} = 0;
 $self->{_DATA} = []; # Array Data
 $self->{_LIST} = []; # List of limit numbers
 $self->{_RESTORE} = []; # Restore $self->{_LIST} after some CLEAR cases
 bless $self, $class; 
 my $t = shift;
 if (!ref $t) { $self->{_COUNTER} = $t || 1; }
 if (ref $t eq "ARRAY") { push(@{$self->{_LIST}},@{$t}); }
 return $self;
}

sub STORE { 
 my $self = shift; 
 my $index = shift;
 my $value = shift;
 if (@{$self->{_RESTORE}}) { @{$self->{_RESTORE}} = (); }
 if (!defined $self->{_LIST}[$index]) 
 { $self->{_LIST}[$index] = $self->{_COUNTER}; }
 if ($self->{_LIST}[$index]) { 
   $self->{_DATA}[$index] = $value;
   $self->{_LIST}[$index]--; 
  } 
  else { warn "Cannot set element at index $index again !"; }
}

sub FETCH { 
 my $self = shift; 
 my $index = shift; 
 if (@{$self->{_RESTORE}}) { @{$self->{_RESTORE}} = (); }
 return $self->{_DATA}[$index]; 
}

sub PUSH { 
 my $self = shift;
 if (@{$self->{_RESTORE}})
 { @{$self->{_LIST}} = @{$self->{_RESTORE}};
   @{$self->{_RESTORE}} = ();
 }
 for(0..$#_) { 
  if ($self->{_LIST}[$_] && !defined $self->{_DATA}[$_]) 
  { $self->{_DATA}[$_] = shift; 
    $self->{_LIST}[$_]--;
  } 
  if (!defined $self->{_LIST}[$_] && !defined $self->{_DATA}[$_] && $self->{_COUNTER}) 
  { $self->{_DATA}[$_] = shift; 
    $self->{_LIST}[$_] = $self->{_COUNTER}-1;
  } 
  if (!defined $self->{_LIST}[$_] && !defined $self->{_DATA}[$_] && !$self->{_COUNTER}) 
  { warn "Cannot set element at index $_ again !"; }
 }
}

sub STORESIZE { 
 my $self = shift; 
 if (@{$self->{_RESTORE}}) { @{$self->{_RESTORE}} = (); }
 my $size = shift; 
 $#{$self->{_DATA}} = $size;
}

sub FETCHSIZE { 
  my $self = shift; 
  if (@{$self->{_RESTORE}}) { @{$self->{_RESTORE}} = (); }
  return scalar @{$self->{_DATA}};
}

sub CLEAR { 
  my $self = shift; 
  @{$self->{_DATA}} = ();
  @{$self->{_RESTORE}} = @{$self->{_LIST}};
  @{$self->{_LIST}} = ();
}

1;
__END__
=head1 NAME

Tie::Array::RestrictUpdates - Limit the number of times you change elements in an array.

=head1 SYNOPSIS

  use Tie::Array::RestrictUpdates;

  tie @foo,"Tie::Array::RestrictUpdates",1;
  # Default limit is 1.
  # Every element from the array can only be changed once
  @foo = qw(A B C D E);
  for(0..4) { $foo[$_] = lc $foo[$_]; }
  print join("-",@foo);
  # This will print A-B-C-D-E and a bunch of warnings

  -or-

  use Tie::Array::RestrictUpdates;

  tie @foo,"Tie::Array::RestrictUpdates",[1,2,3,4];
  # This forces the limits of the first 3 indexes
  # This also forces any extra elements from the array to have a 0 limit
  # and therefor be unchangable/unsettable
  @foo = qw(A B C D E);
  for(0..3) { $foo[$_] = lc $foo[$_]; }
  for(0..3) { $foo[$_] = uc $foo[$_]; }
  for(0..3) { $foo[$_] = lc $foo[$_]; }
  for(0..3) { $foo[$_] = uc $foo[$_]; }
  print join("-",@foo);
  # This will print A-b-C-d and a bunch of warnings

=head1 DESCRIPTION

This module limits the number of times a value can be stored in a array.

=head1 TODO

Loads probably. This is a very early draft.

=head1 DISCLAIMER

This code is released under GPL (GNU Public License). More information can be 
found on http://www.gnu.org/copyleft/gpl.html

=head1 VERSION

This is Tie::Array::RestrictUpdates 0.0.1.

=head1 AUTHOR

Hendrik Van Belleghem (beatnik@quickndirty.org)

=head1 SEE ALSO

GNU & GPL - http://www.gnu.org/copyleft/gpl.html

=cut