package XML::DTD::FAState;

use 5.008;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.09';


# Constructor
sub new {
  my $proto = shift; # Class name or object reference
  my $label = shift; # State label
  my $final = shift; # Final state flag

  my $cls = ref($proto) || $proto;
  my $obj = ref($proto) && $proto;

  my $self;
  if ($obj) {
    # Called as a copy constructor
    $self = { %$obj };
  } else {
    # Called as the main constructor
    $self = {
	     'label' => $label,  # State label
	     'final' => $final,  # Final state flag
	     'tdest' => {},      # Transition destinations
	     'tsymb' => {},      # Transition symbols
	     'bckrf' => {}       # Back references
	    };
  }
  bless $self, $cls;
  return $self;
}


# Determine whether object is of this type
sub isa {
  my $cls = shift;
  my $r = shift;

  if (defined($r) && ref($r) eq $cls) {
    return 1;
  } else {
    return 0;
  }
}


# Get state label
sub label {
  my $self = shift;

  return $self->{'label'};
}


# Get list of back references for state
sub backref {
  my $self = shift;

  return [keys %{$self->{'bckrf'}}];
}


# Get all outbound transitions as list of (destination,symbol) pairs
sub transitions {
  my $self = shift;

  # Initialise transition list
  my $trns = [];
  # Get list of all destination states
  my $dest = $self->deststates;
  my ($d, $s, $symb);
  # Work through list of destination states
  foreach $d (@$dest) {
    # Get list of transition symbols for transitions to current destination
    $symb = $self->outsymbols($d);
    # Work through list of transition symbols
    foreach $s (@$symb) {
      # Push (destination state,transition symbol) pair onto list
      push @$trns, [$d, $s];
    }
  }

  return $trns;
}


# Get array of all outbound transition symbols, or just those
# associated with a specified destination state
sub outsymbols {
  my $self = shift;
  my $dest = shift; # Destination state

  if (defined $dest) {
    return [keys %{$self->{'tdest'}->{$dest}}];
  } else {
    return [keys %{$self->{'tsymb'}}];
  }
}


# Get array of all destination states, or just those associated with a
# specified transition symbol
sub deststates {
  my $self = shift;
  my $symb = shift; # Transition symbol

  if (defined $symb) {
    return $self->{'tsymb'}->{$symb};
  } else {
    # Get list of all outbound transition symbols
    my $symb = $self->outsymbols;
    # Initialise hash used to ensure list only contains one occurrence
    # of each state
    my $uniq = {};
    # Initialise result list
    my $dest = [];
    my ($s, $d, $dlst);
    # Loop over all outbound transition symbols
    foreach $s (@$symb) {
      # Get list of destination states associated with current symbol
      $dlst = $self->deststates($s);
      # Loop over all destination states associated with current symbol
      foreach $d (@$dlst) {
	# Push the current state onto the list if not already encountered
	push @$dest, $d if (!$uniq->{$d});
	# Mark the current state as having been encountered
	$uniq->{$d} = 1;
      }
    }

    return $dest;
  }
}


# Add a transition to another state
sub settrans {
  my $self = shift;
  my $dest = shift; # Destination state
  my $symb = shift; # Transition symbol

  # Construct symbol hash for destination if not defined
  $self->{'tdest'}->{$dest} = {} if (!defined $self->{'tdest'}->{$dest});
  # Construct destination array for symbol if not defined
  $self->{'tsymb'}->{$symb} = [] if (!defined $self->{'tsymb'}->{$symb});
  # Push destination node onto list for corresponding symbol if same
  # (destination, symbol) transition not already present
  push @{$self->{'tsymb'}->{$symb}}, $dest
    if (!$self->{'tdest'}->{$dest}->{$symb});
  # Mark symbol in hash for corresponding destination
  $self->{'tdest'}->{$dest}->{$symb} = 1;
  # Mark backreference to transition source state
  $dest->{'bckrf'}->{$self} = 1;
}


# Remove a transition to another node
sub clrtrans {
  my $self = shift;
  my $dest = shift; # Destination state
  my $symb = shift; # Transition symbol

  # Remove symbol from hash for corresponding destination
  delete $self->{'tdest'}->{$dest}->{$symb};

  # Remove destination node from list for corresponding signal
  my ($n, $d);
  my $dlst = [];
  foreach $d (@{$self->{'tsymb'}->{$symb}}) {
    push @$dlst, $d if ($d != $dest);
  }
  $self->{'tsymb'}->{$symb} = $dlst;

  # Delete symbol hash for destination if empty
  delete $self->{'tdest'}->{$dest} if (scalar @$dlst == 0);
  # Delete destination array for symbol if empty
  delete $self->{'tsymb'}->{$symb}
    if (scalar @{$self->deststates($symb)} == 0);

  # Remove backreference to transition source state
  delete $dest->{'bckrf'}->{$self};
}


1;

__END__

=head1 NAME

XML::DTD::FAState - Perl module representing a state of a finite automaton

=head1 SYNOPSIS

  use XML::DTD::FAState;

=head1 DESCRIPTION

XML::DTD::FAState is a Perl module representing a state of a finite
automaton. The following methods are provided.

=over 4

=item B<new>

 my $s = XML::DTD::FAState->new('state label');
 my $sf = XML::DTD::FAState->new('state label', 1); # Final state

Construct a new XML::DTD::FAState object.

=item B<isa>

if (XML::DTD::FAState->isa($obj) {
 ...
 }

Test object type.

=item B<label>

 print $s->label;

Return state label.

=item B<backref>

 my $br = $s->backref;

Get list of back references.

=item B<transitions>

 my $tlst = $s->transitions;

Get all outbound transitions as list of (destination,symbol) pairs.

=item B<outsymbols>

 my $symball = $s->outsymbols;
 my $s1 = XML::DTD::FAState->new('state label');
 my $symbdst = $s->outsymbols(s1);

Get array of all outbound transition symbols, or just those associated
with a specified destination state.

=item B<deststates>

 my $dstall = $s->deststates;
 my $dstsmb = $s->deststates('transition symbol');

Get array of all destination states, or just those associated with a
specified transition symbol.

=item B<settrans>

 my $dst = XML::DTD::FAState->new('state label');
 my $s->settrans($dst, 'transition symbol');

Add a transition to another state.

=item B<clrtrans>

 $s->clrtrans($dst, 'transition symbol');

Remove a transition to another node.

=back

=head1 SEE ALSO

L<XML::DTD::Automaton>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006,2010 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the GPL file included in this distribution.

=cut
