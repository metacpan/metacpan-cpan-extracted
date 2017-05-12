package XML::DTD::Automaton;

use XML::DTD::FAState;
use XML::DTD::Error;

use 5.008;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.09';


# Constructor
sub new {
  my $proto = shift; # Class name or object reference

  my $cls = ref($proto) || $proto;
  my $obj = ref($proto) && $proto;

  my $self;
  if ($obj) {
    # Called as a copy constructor
    $self = { %$obj };
    bless $self, $cls;
  } else {
    # Called as the main constructor
    $self = {
	     'initl' => XML::DTD::FAState->new('Initial'), # Initial index
	     'final' => {}, # Final states
	     'index' => {}, # Lookup state from index number
	     'state' => {}  # Lookup index number from state
	    };
    $self->{'index'}->{0} = $self->{'initl'};
    $self->{'state'}->{$self->{'initl'}} = 0;
    $self->{'count'} = 1;
    bless $self, $cls;
  }
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


# Get a state reference from an index number
sub state {
  my $self = shift;
  my $n = shift;    # State index number

  return $self->{'index'}->{$n};
}


# Get an index number from a state reference
sub index {
  my $self = shift;
  my $state = shift;  # State reference

  return $self->{'state'}->{$state};
}


# Determine whether a state is marked final
sub final {
  my $self = shift;
  my $n = shift;    # State index number

  return $self->{'final'}->{$self->state($n)};
}


# Mark a state as final
sub setfinal {
  my $self = shift;
  my $n = shift;    # State index number

  $self->{'final'}->{$self->state($n)} = 1;
}


# Make a new state
sub mkstate {
  my $self = shift;
  my $label = shift; # Label for new state
  my $final = shift; # Final flag for new state

  # Construct state
  my $state = XML::DTD::FAState->new($label, $final);
  # Assign and record new state index number
  $self->{'index'}->{$self->{'count'}} = $state;
  # Set hash for lookup of index from state
  $self->{'state'}->{$state} = $self->{'count'};
  # Add to record of final states if final flag set
  $self->{'final'}->{$state} = 1 if ($final);
  # Increment state counter
  return $self->{'count'}++;
}


# Make a new transition
sub mktrans {
  my $self = shift;
  my $srcn = shift; # Source state number
  my $dstn = shift; # Destination state number
  my $symb = shift; # Transition symbol

  my $srcs = $self->state($srcn);
  my $dsts = $self->state($dstn);
  $srcs->settrans($dsts, $symb);
}


# Remove a transition
sub rmtrans {
  my $self = shift;
  my $srcn = shift; # Source state number
  my $dstn = shift; # Destination state number
  my $symb = shift; # Transition symbol

  my $srcs = $self->state($srcn);
  my $dsts = $self->state($dstn);
  $srcs->clrtrans($dsts, $symb);
}


# Eliminate epsilon transitions
sub epselim {
  my $self = shift;

  my ($n, $d, $e, $elst, $t, $tlst, $m, $epsn);
  # Repeat process until no epsilon transitions encountered
  do {
    # Initialise epsilon transition counter
    $epsn = 0;
    # Iterate over all states
    for ($n = 0; $n < $self->{'count'}; $n++) {
      # Get state associated with current state index
      $d = $self->state($n);
      # Get list of all destination states along epsilon transitions
      $elst = $d->deststates('');
      $epsn += scalar @$elst if (defined $elst);
      # Iterate over all epsilon transition destination states
      foreach $e (@$elst) {
	# Get list of all transitions from current epsilon transition dest
	$tlst = $e->transitions;
	# Warn if epsilon transition cannot be eliminated
	if (scalar @$tlst == 0 and !$self->final($self->{'state'}->{$e})) {
	  throw XML::DTD::Error("Cannot eliminate epsilon transition from $n ".
				"to " . $self->{'state'}->{$e}, $self);
	}
	# Mark the current state as final if the epsilon transition
	# destination is final
	if ($self->final($self->{'state'}->{$e})) {
	  $self->setfinal($n);
	}
	# Work through all transitions from current epsilon transition dest
	foreach $t (@$tlst) {
	  # Get state index of destination for current transition
	  $m = $self->{'state'}->{$t->[0]};
	  # Add a transition from current state to the current
	  # transition destination, with the current transition symbol
	  $self->mktrans($n, $m, $t->[1]);
	}
	# Remove the current epsilon transition
	$self->rmtrans($n, $self->{'state'}->{$e}, '');
      }
    }
  } while ($epsn > 0);

}


# Remove unreachable states
sub rmunreach {
  my $self = shift;

  my ($n, $s, $t, $tlst);
  # Initialise hash for reconstructed state indices
  my $index0 = {0 => $self->{'initl'}};
  # Set index counter for reconstructed state indices
  my $c = 1;
  # Iterate over all state indices other than initial state 0
  for ($n = 1; $n < $self->{'count'}; $n++) {
    # Get state associated with current state index
    $s = $self->state($n);
    if (scalar @{$s->backref} != 0) { # Current state is reachable
      # Insert current state into reconstructed state index hash
      $index0->{$c} = $s;
      # Insert current state into reverse lookup hash
      $self->{'state'}->{$s} = $c++;
    } else {                          # Current state is unreachable
      # Get list of all transitions from current state
      $tlst = $s->transitions;
      # Iterate over all transitions from current state
      foreach $t (@$tlst) {
	# Clear the current transition
	$s->clrtrans($t->[0], $t->[1]);
      }
      # Delete the reverse lookup entry for current state
      delete $self->{'state'}->{$s};
      # Delete the final flag hash entry for current state
      delete $self->{'final'}->{$s};
    }
  }
  # Set the state index hash to the reconstructed one
  $self->{'index'} = $index0;
  # Set the state index counter to the new value
  $self->{'count'} = $c;
}


# Check whether an FSA is deterministic
sub isdeterministic {
  my $self = shift;

  my ($n, $d, $dlst, $slst, $s, $elst);
  # Iterate over all state indices
  for ($n = 0; $n < $self->{'count'}; $n++) {
    # Get state associated with current state index
    $d = $self->state($n);
    # Get list of all destination states along epsilon transitions
    $elst = $d->deststates('');
    # Return false status if any epsilon transitions present
    return 0 if (defined $elst and scalar @$elst > 0);
    # Get list of all outbound transition symbols
    $slst = $d->outsymbols;
    # Loop over all transition symbols
    foreach $s (@$slst) {
      # Get list of destination states associated with current symbol
      $dlst = $d->deststates($s);
      # Return false status if any symbol has a transition to more
      # than one destination
      return 0 if (scalar @$dlst > 1);
    }
  }
  return 1;
}


# Determine whether a symbol sequence is accepted by the automaton (if
# it is a DFA)
sub accept {
  my $self = shift;
  my $seqn = shift;

  return undef if (!$self->isdeterministic);
  my $sidx = 0;
  my ($symb, $dest);
  while (scalar @$seqn > 0) {
    $symb = shift @$seqn;
    $dest = $self->state($sidx)->deststates($symb);
    return 0 if (!defined $dest or scalar @$dest == 0);
    $sidx = $self->index($dest->[0]);
  }

  return ($self->final($sidx))?1:0;
}


# Build a string representation of the automaton
sub string {
  my $self = shift;

  my $str = '';
  my ($n, $m, $s, $slst, $b, $blst);
  for ($n = 0; $n < $self->{'count'}; $n++) {
    $str .= sprintf("%4d  %-20s", $n, $self->state($n)->label);
    $str .= "\t[Final]" if ($self->final($n));
    $str .= "\n";
    if ($n > 0) {
      $str .= "      Back references: ";
      $blst = $self->state($n)->backref;
      foreach $b (@$blst) {
	print "B: $b\n" if (!defined $self->index($b));
	$str .= $self->index($b) . " ";
      }
      $str .= "\n";
    }
    for ($m = 0; $m < $self->{'count'}; $m++) {
      $slst = $self->state($n)->outsymbols($self->state($m));
      if (defined $slst and scalar @$slst > 0) {
	$str .= sprintf("    %4d  ", $m);
	foreach $s (@$slst) {
	  $str .= (($s eq '')?'epsilon':$s) . ' ';
	}
	$str .= "\n";
      }
    }
  }

  return $str;
}


# Write an XML representation of the automaton
sub writexml {
  my $self = shift;
  my $xmlw = shift;

  $xmlw->open('fsa');
  my ($n, $tlst, $t);
  for ($n = 0; $n < $self->{'count'}; $n++) {
    $xmlw->open('state', {'index' => $n, 'final' => $self->final($n),
			  'label' => $self->state($n)->label});
    $tlst = $self->state($n)->transitions;
    foreach $t (@$tlst) {
      $xmlw->empty('transition', {'symbol' => $t->[1],
				  'destination' => $self->index($t->[0])});
    }
    $xmlw->close;
  }
  $xmlw->close;
}


1;

__END__

=head1 NAME

XML::DTD::Automaton - Perl module representing a finite automaton

=head1 SYNOPSIS

  use XML::DTD::Automaton;

  my $fsa = XML::DTD::Automaton->new;
  my $idxa = $fsa->mkstate('state label A');
  my $idxb = $fsa->mkstate('state label B');
  $fsa->mktrans($idxa, $idxb, 'transition symbol');

=head1 ABSTRACT

  XML::DTD::Automaton is a Perl module representing a finite automaton.

=head1 DESCRIPTION

  XML::DTD::Automaton is a Perl module representing a finite
  automaton. The following methods are provided.

=over 4

=item B<new>

 my $fsa = XML::DTD::Automaton->new;

Construct a new XML::DTD::Automaton object

=item B<isa>

  if (XML::DTD::Automaton->isa($atd)) {
  ...
  }

Test object type

=item B<state>

 my $idx = $fsa->mkstate('state label');
 my $state = $fsa->state($idx);

Get an XML::DTD::FAState object reference from a state index

=item B<index>

 my $state = $fsa->state($idx0);
 ...
 my $idx1 = $fsa->index($state);

Get a state index from an XML::DTD::FAState object reference

=item B<final>

 my $flg = $fsa->final($idx);

Determine whether a state is marked final

=item B<setfinal>

 $fsa->setfinal($idx);

Mark a state as final

=item B<mkstate>

 my $idxa = $fsa->mkstate('state label A');
 my $idxb = $fsa->mkstate('state label B', 1); # A final state

Construct a new state

=item B<mktrans>

 $fsa->mktrans($idxa, $idxb, 'transition symbol');
 $fsa->mktrans($idxa, $idxb, ''); # An epsilon transition

Construct a new transition

=item B<rmtrans>

 $fsa->rmtrans($idxa, $idxb, 'transition symbol');

Remove a transition

=item B<epselim>

 $fsa->epselim;

Eliminate epsilon transitions

=item B<rmunreach>

 $fsa->rmunreach;

Remove unreachable states

=item B<isdeterministic>

 if ($fsa->isdeterministic) {
 ...
 }

Determine with the automaton is deterministic

=item B<accept>

 if ($fsa->accept(['a', 'a', 'b', 'c', 'a'])) {
 ...
 }

If the automaton is deterministic, determine whether the symbol
sequence is accepted

=item B<string>

 print $fsa->string;

Construct a string representation of the automaton

=item B<writexml>

  $xo = new XML::Output({'fh' => *STDOUT});
  $fsa->writexml($xo);

Write an XML representation of the automaton

=back

=head1 SEE ALSO

L<XML::DTD::FAState>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006,2010 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the GPL file included in this distribution.

=cut
