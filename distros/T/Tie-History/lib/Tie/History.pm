package Tie::History;

use 5.008; # Data::Dumper's use of Sortkeys requires 5.8 or higher
use strict;
use warnings;
use warnings::register;
use Data::Dumper;
use Carp;

our $VERSION = '0.03';

sub TIESCALAR {
  my $self = shift;
  my $args = shift;

  if ($args) {
    unless (ref $args eq 'HASH') {
      croak('->TIESCALAR: First argument to TIESCALAR constructor should be a hash reference');
    }
  }

  my $data = {
    CURRENT    => "",
    PREVIOUS   => [],
    RECENT     => 1, # not really, but we want to prevent a commit on nothing
    ENTRYS     => 0,
    TYPE       => "SCALAR",
    AUTOCOMMIT => $args->{AutoCommit} || 0,
  };
  return bless $data, $self;
}

sub TIEARRAY {
  my $self = shift;
  my $args = shift;

  if ($args) {
    unless (ref $args eq 'HASH') {
      croak('->TIESCALAR: First argument to TIESCALAR constructor should be a hash reference');
    }
  }

  my $data = {
    CURRENT    => [],
    PREVIOUS   => [],
    RECENT     => 1, # not really, but we want to prevent a commit on nothing
    ENTRYS     => 0,
    TYPE       => "ARRAY",
    AUTOCOMMIT => $args->{AutoCommit} || 0,
  };
  return bless $data, $self;
}

sub TIEHASH {
  my $self = shift;
  my $args = shift;

  if ($args) {
    unless (ref $args eq 'HASH') {
      croak('->TIESCALAR: First argument to TIESCALAR constructor should be a hash reference');
    }
  }

  my $data = {
    CURRENT    => {},
    PREVIOUS   => [],
    RECENT     => 1, # not really, but we want to prevent a commit on nothing
    ENTRYS     => 0,
    TYPE       => "HASH",
    AUTOCOMMIT => $args->{AutoCommit} || 0,
  };
  return bless $data, $self;
}

sub commit {
  my $self = shift;
  if ($self->{TYPE} eq "SCALAR") {
    $self->{RECENT} = ($self->{CURRENT} eq ($self->{PREVIOUS}->[-1] || "")) ? 1 : 0;
  }
  elsif ($self->{TYPE} eq "ARRAY") {
    $self->_cmp;
    $self->{RECENT} = 1 if (scalar(@{$self->{CURRENT}}) == 0);
  }
  elsif ($self->{TYPE} eq "HASH") {
    $self->_cmp;
    $self->{RECENT} = 1 if (scalar(keys(%{$self->{CURRENT}})) == 0);
  }
  if ($self->{RECENT} == 1) {
    carp "You can't commit something that has not changed" if (warnings::enabled());
    return 0;
  }
  else {
    if ($self->{TYPE} eq "HASH") {
      push(@{$self->{PREVIOUS}}, {%{$self->{CURRENT}}});
    }
    else{
      push(@{$self->{PREVIOUS}}, $self->{CURRENT});
    }
    $self->{RECENT} = 1;
    $self->{ENTRYS}++;
    return 1;
  }
}

sub setautocommit {
  my $self = shift;
  my $value = shift;
  if ($value == 0) {
    $self->{AUTOCOMMIT} = 0;
  }
  elsif ($value == 1) {
    $self->{AUTOCOMMIT} = 1;
  }
  else {
    croak " ->setautocommit takes either 1 or 0";
  }
}

sub _cmp {
  my $self = shift;
  my $current  = $self->{CURRENT};
  my $previous = $self->{PREVIOUS}->[-1] || "";
  my $c = new Data::Dumper([$current])->Deepcopy(1)->Terse(1)->Purity(1);
  my $p = new Data::Dumper([$previous])->Deepcopy(1)->Terse(1)->Purity(1);
  $c->Sortkeys(1) if ($self->{TYPE} eq "HASH");
  $p->Sortkeys(1) if ($self->{TYPE} eq "HASH");
  $self->{RECENT} = ($p->Dump eq $c->Dump) ? 1 : 0;
}

sub previous {
  my $self = shift;
  return 0 unless $self->_checkentries();
  my $index = ($self->{RECENT}) ? -2 : -1;
  return $self->{PREVIOUS}->[$index];
}

sub current {
  my $self = shift;
  return $self->{CURRENT};
}

sub getall {
  my $self = shift;
  return 0 unless $self->_checkentries();
  return $self->{PREVIOUS};
}

sub get {
  my $self  = shift;
  my $index = shift;
  return 0 unless $self->_checkentries($index);
  return $self->{PREVIOUS}->[$index];
}

sub revert {
  my $self = shift;
  my $index = shift || ($self->{RECENT}) ? -2 : -1;
  return 0 unless $self->_checkentries($index);
  $self->{CURRENT} = $self->{PREVIOUS}->[$index];
  return 1;
}

sub _checkentries {
  my $self  = shift;
  my $index = shift || "NULL";
  if ($self->{ENTRYS} == 0) {
    carp "There are no previous entries" if (warnings::enabled());
    return 0;
  }
  if ($index ne "NULL") {
    if ($index >= $self->{ENTRYS}) {
      carp "Invalid entry" if (warnings::enabled());
      return 0;
    }
  }
  return 1;
}

sub FETCH {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my $indexkey = shift;
  return $self->{CURRENT}              if ($self->{TYPE} eq "SCALAR");
  return $self->{CURRENT}->[$indexkey] if ($self->{TYPE} eq "ARRAY");
  return $self->{CURRENT}->{$indexkey} if ($self->{TYPE} eq "HASH");
}

sub STORE {
  my $self  = shift;
  confess "I am not a class method" unless ref $self;
  if ($self->{TYPE} eq "SCALAR") {
    my $value = shift;
    return $self->{CURRENT} = $value;
  }
  elsif ($self->{TYPE} eq "ARRAY") {
    my $index = shift;
    my $value = shift;
    return $self->{CURRENT}->[$index] = $value;
  }
  elsif ($self->{TYPE} eq "HASH") {
    my $key   = shift;
    my $value = shift;
    return $self->{CURRENT}->{$key} = $value;
  }
  if ($self->{AUTOCOMMIT}) {
    $self->commit;
  }
}

sub UNTIE {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  undef($self->{PREVIOUS});
  return $self->{CURRENT}    if ($self->{TYPE} eq "SCALAR");
  return @{$self->{CURRENT}} if ($self->{TYPE} eq "ARRAY");
  return %{$self->{CURRENT}} if ($self->{TYPE} eq "HASH");
}

sub DESTROY {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
}

sub EXISTS {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my $key = shift;
  if ($self->{TYPE} eq "ARRAY") {
    return 0 if (!defined $self->{CURRENT}->[$key]);
    return 1;
  }
  elsif ($self->{TYPE} eq "HASH") {
    return exists $self->{CURRENT}->{$key};
  }
}

sub CLEAR {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  return $self->{CURRENT} = []    if ($self->{TYPE} eq "ARRAY");
  return %{$self->{CURRENT}} = () if ($self->{TYPE} eq "HASH");
}

sub DELETE {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my $key = shift;
  return $self->STORE($key, undef)       if ($self->{TYPE} eq "ARRAY");
  return delete $self->{CURRENT}->{$key} if ($self->{TYPE} eq "HASH");
}

sub FIRSTKEY {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my $a = scalar keys %{$self->{CURRENT}};
  each %{$self->{CURRENT}};
}

sub NEXTKEY {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my $lastkey = shift;
  each %{$self->{CURRENT}}
}

sub FETCHSIZE {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  return scalar(@{$self->{CURRENT}});
}

sub STORESIZE {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my $count = shift;
  if ($count > $self->FETCHSIZE()) {
    foreach ($count - $self->FETCHSIZE() .. $count - 1) {
      $self->STORE($_, undef);
    }
  }
  elsif ($count < $self->FETCHSIZE()) {
    foreach (0 .. $self->FETCHSIZE() - $count - 2) {
      $self->POP();
    }
  }
}

sub EXTEND {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my $count = shift;
  $self->STORESIZE($count);
}

sub PUSH {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my @list = @_;
  push(@{$self->{CURRENT}}, @list);
  return $self->FETCHSIZE();
}

sub POP {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  return pop @{$self->{CURRENT}};
}

sub SHIFT {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  return shift @{$self->{CURRENT}};
}

sub UNSHIFT {
  my $self = shift;
  confess "I am not a class method" unless ref $self;
  my @list = @_;
  unshift(@{$self->{CURRENT}}, @list);
  return $self->FETCHSIZE();
}

sub SPLICE {
  my $self    = shift;
  confess "I am not a class method" unless ref $self;
  my $size   = $self->FETCHSIZE;
  my $offset = @_ ? shift : 0;
  $offset += $size if $offset < 0;
  my $length = @_ ? shift : $size-$offset;
  return splice(@{$self->{CURRENT}},$offset,$length,@_);
}

1;
__END__

=head1 NAME

Tie::History - Perl extension giving scalars, arrays and hashes a history.

=head1 SYNOPSIS

  use Tie::History;

  my $scalartobj = tie($scalar, 'Tie::History');
  $scalar = "Blah blah blah";
  $tiedobject->commit;
  # If you don't have $tiedobject, you can use tied().
  tied($scalar)->commit; # Commit the change
  $scalar = "More more more";
  $tiedobject->commit; # Commit the change

  my $arraytobj = tie(@array,  'Tie::History');
  @array = qw/one two three/;
  $arraytobj->commit;

  my $hashtobj = tie(%hash,   'Tie::History');
  $hash{key} = "value";
  $hashtobj->commit;

=head1 METHODS

=over

=item commit

  $scalartobj->commit;
  $arraytobj->commit;
  $hashtobj->commit;
  # Or if you don't have an object created
  tied($scalar)->commit;
  tied(@array)->commit;
  tied(%hash)->commit;

Commit the current value into the history.

=item previous

  $previous = $scalartobj->previous;
  @previous = $arraytob->previous;
  %previous = $hashobj->previous;
  # Or if you don't have an object created
  $previous = tied($scalar)->previous;
  @previous = tied(@array)->previous;
  %previous = tied(%hash)->previous;

Return the previous committed copy.

=item current

  $current = $scalartobj->current;
  @current = $arraytobj->current;
  %current = $hashtobj->current;
  # Or if you don't have an object created
  $current = tied($scalar)->current;
  @current = tied(@array)->current;
  %current = tied(%hash)->current;

Return the current copy, even if uncommitted.

=item get

  $first = $scalartobj->get(0);
  @first = $arraytobj->get(0);
  %first = $hashtobj->get(0);
  # Or if you don't have an object created
  $first = tied($scalar)->get(0);
  @first = tied(@array)->get(0);
  %first = tied(%hash)->get(0);

Return the copy in the position passed, starting with 0 as the first,
and -1 as the last.

=item getall

  @all = $scalartobj->getall;
  @all = $arraytobj->getall;
  @all = $hashtobj->getall;
  # Or if you don't have an object created
  @all = tied($scalar)->getall;
  @all = tied(@array)->getall;
  @all = tied(%hash)->getall;

Return an array with all previous versions committed.

=item revert

  $scalartobj->revert(1);
  $arraytobj->revert(1);
  $hashtobj->revert(1);
  # Or if you don't have an object created
  tied($scalar)->revert(1);
  tied(@array)->revert(1);
  tied(%hash)->revert(1);

Will revert the tied variable back to what position passed. If nothing
is passed, it will revert to the last committed item. If the last item
committed item is the same as the current, it will revert to the
previous item. This may change in the future.

=back

=head1 DESCRIPTION

Tie::History will allow you to keep a history of previous versions of
a variable, by means of committed the changes. As this is all stored
in memory, it is not for use in a production system, but best kept for
debugging.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Tie::HashHistory>

L<Tie::RDBM>

=head1 AUTHOR

Larry Shatzer, Jr., E<lt>larrysh@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Larry Shatzer, Jr.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


