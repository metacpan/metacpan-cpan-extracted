package Unicode::SetAutomaton;

use strict;
use warnings;
use Set::IntSpan;
use Set::IntSpan::Partition;
use Storable qw(freeze);

our $VERSION = '0.01';

our @utf8hs  = (0x00000000, 0x00000000, 0x0000c080, 0x00e08080, 0xf0808080);
our @utf8min = (0x00000000, 0x00000000, 0x0000C280, 0x00E0A080, 0xF0908080);
our @utf8max = (0x00000000, 0x0000007F, 0x0000DFBF, 0x00EFBFBF, 0xF48FBFBF);

sub _u8enc {

  my $cp = shift;
  my $ln = 4;

  # Encodes code points as utf-8 integers;
  # for example, U+00F6 becomes 0x0000C3B6

  return $cp if $cp <= 0x7F;

  # Spread the bits to their target locations
  my $ret = (($cp << 0) & 0x0000003f) |
            (($cp << 2) & 0x00003f00) |
            (($cp << 4) & 0x003f0000) |
            (($cp << 6) & 0x3f000000) ;

  # Count the length
  $ln -= $cp <= 0xFFFF;
  $ln -= $cp <= 0x07FF;

  # Merge the spread bits with the mode bits
  return $ret | $utf8hs[$ln];
}

sub _get_info {

  my $u8 = shift;

  my $width = 4;
  $width -= $u8 <= 0xFFFFFF;
  $width -= $u8 <= 0xFFFF;
  $width -= $u8 <= 0xFF;

  my $s1 = ($width - 1) * 8;
  my $s2 = (4 - $width) * 8;
  my $ml = 0x00808080 >> $s2;
  my $mh = 0x00BFBFBF >> $s2;
  my $xl = 0x00800000 >> $s2;
  my $xh = 0x00BF0000 >> $s2;

  # The first byte in the partial utf-8 sequence in u8.
  my $head  = $u8 >> $s1;
  
  # All bytes after the first, or zero if there are none.
  my $tail  = ($u8 & $mh);

  # Indicates whether the first byte after head is 0x80.
  my $islow = ($u8 & $xh) == $xl;
  
  # Indicates whether the first byte after head is 0xBF.
  my $isupp = ($u8 & $xh) == $xh;

  # Last partial sequence before sequences with head
  my $pmax  = ($head - 1) << $s1 | $mh;
  
  # First partial sequence for sequences with head
  my $pmin  = ($head + 0) << $s1 | $ml;
  
  # Last partial sequence for sequences with head
  my $hmax  = ($head + 0) << $s1 | $mh;
  
  # First partial sequence after sequences with head
  my $hmin  = ($head + 1) << $s1 | $ml;

  # There are a few special cases for the min,max items
  # if the respective head is not a continuation octet.
  # E.g., for 0xE0 pmin should be E0A080 but is E08080.
  # The caller handles them indirectly by splitting.

  my $i = {
    width => $width, head  => $head,  tail  => $tail,
    isLow => $islow, isUpp => $isupp, hmin  => $hmin,
    hmax  => $hmax,  pmin  => $pmin,  pmax  => $pmax,
  };
                
  return $i;
}

sub _get_next {

  my $iter = shift;
  my ($clas, $cmin, $cmax, $nmin, $min, $max);
  
  if ($iter->{splitix}) {
    
    # When splitting ranges a separate array is used to keep
    # track of artificial ranges. If there any, use them first.
    $cmax = $iter->{split}->[ -- $iter->{splitix} ];
    $cmin = $iter->{split}->[ -- $iter->{splitix} ];
    $clas = $iter->{split}->[ -- $iter->{splitix} ];

  } elsif ( $iter->{derivix} <= $iter->{end} ) {
    
    # If there are none, we pick a new range from the input.
    $clas = $iter->{deriv}->[ $iter->{derivix} ++ ];
    $cmin = $iter->{deriv}->[ $iter->{derivix} ++ ];
    $cmax = $iter->{deriv}->[ $iter->{derivix} ++ ];
    
  } else {
    return
  }
  
  # Compute various properties of the partial sequences.
  $min = _get_info($cmin);
  $max = _get_info($cmax);

  if ($min->{width} != $max->{width}) {

    # The range crosses width boundaries, so split it.
    $nmin = $utf8min[ $min->{width} + 1 ];
    $iter->{split}->[ $iter->{splitix} ++ ] = $clas;
    $iter->{split}->[ $iter->{splitix} ++ ] = $nmin;
    $iter->{split}->[ $iter->{splitix} ++ ] = $cmax;
    $cmax = $utf8max[ $min->{width} ];
  }

  if ($cmin >= 0x00eda080 and $cmax <= 0x00edbfbf) {
    
    # The current range contains only surrogate code points
    # which are not allowed. So get the next range, if any.
    return _get_next( $iter );
    
  } elsif ($cmin >= 0x00eda080 and $cmin <= 0x00edbfbf) {
    
    # cmin is somewhere inside the surrogate range and cmax
    # is not. So we set cmin to the first non-surrogate.
    $cmin = 0x00ee8080;
    
  } elsif ($cmax >= 0x00eda080 and $cmax <= 0x00edbfbf) {
    
    # cmax is somewhere inside the surrogate range and cmin
    # is not. So we set cmax to the last non-surrogate.
    $cmax = 0x00ed9fbf;
    
  } elsif ($cmin < 0x00eda080 and $cmax > 0x00edbfbf) {
    
    # The range includes code points before and after the
    # surrogate range. So we have to split it into two.
    $nmin = 0x00ee8080;
    $iter->{split}->[ $iter->{splitix} ++ ] = $clas;
    $iter->{split}->[ $iter->{splitix} ++ ] = $nmin;
    $iter->{split}->[ $iter->{splitix} ++ ] = $cmax;
    $cmax = 0x00ed9fbf;
  }
  
  # cmin and cmax may have changed so recompute the info
  $min = _get_info($cmin);
  $max = _get_info($cmax);

  if (!($min->{head} == $max->{head}) && !($min->{isLow} && $max->{isUpp})) {

    if ($min->{isLow}) {

      # min is a lower and but max is not an upper end, so we split
      # the range into two, one going from min to "one" before max,
      # and the other going from the beginning of max's range to max.
      $nmin = $max->{pmin};
      $iter->{split}->[ $iter->{splitix} ++ ] = $clas;
      $iter->{split}->[ $iter->{splitix} ++ ] = $nmin;
      $iter->{split}->[ $iter->{splitix} ++ ] = $cmax;
      $cmax = $max->{pmax};

    } else {

      # if the heads are different and min is not a lower end then
      # we have to complete min's range first, so split the range.
      $nmin = $min->{hmin};
      $iter->{split}->[ $iter->{splitix} ++ ] = $clas;
      $iter->{split}->[ $iter->{splitix} ++ ] = $nmin;
      $iter->{split}->[ $iter->{splitix} ++ ] = $cmax;
      $cmax = $min->{hmax};

    }
  }
  
  # cmax may have changed so recompute the info
  $max = _get_info($cmax);
  
  return $clas, $min, $max;
}

sub _triples_to_dfa {

  my @triples = @_;
  my (@d, @todo, $d2s, $s2d);
  
  # The deriv array stores all character class, or rather, utf-8 range
  # information. Each class stores the length of the subsequent data as
  # first item. For classes representing end states the next value is
  # the number of the class. For other classes a list of <class min max>
  # triples follows. Array references and other structures could be
  # used instead, however this structure mirrors the C implementation.
  
  my @deriv = ( scalar(@triples), @triples );
  my $lengthix = scalar @deriv;
  my $nextix = scalar @deriv + 1;
  my $nextnum = 0;
  my $start = $nextnum++;
  my $obj2num = { freeze(\@triples), $start };

  $deriv[$lengthix] = 0;

  push @todo, [ $start, $start ];

  while (@todo) {

    my ($index, $currentS) = @{ pop @todo };
    
    # A special iterator is used to go over the utf-8 ranges in a class.
    # The basic idea of this algorithm is to compute all derivatives of
    # a given class of utf-8 ranges; the iterator automatically splits
    # these ranges such that we can take the "heads" of a range as label
    # for a transition, and the "tails" as range for the next class.
    
    # As an example, consider a simple class from U+00E4 to U+00F6. The
    # range is utf-8 encoded to 0x0000C3A4 .. 0x0000C3B6. Here the head
    # range would be 0xC3 .. 0xC3 and the tail range 0xA4 .. 0xB6. Then
    # <S> -- 0xC3 .. 0xC3 --> <1>, <1> -- 0xA4 .. 0xB6 --> <F> would be
    # the automaton. See the _get_next routine for details on splitting.
    
    my $iter = {
      split   => [],
      splitix => 0,
      deriv   => \@deriv,
      derivix => $index + 1,
      end     => $index + $deriv[$index],
    };
    
    my $prev;

    while (1) {

      my $success = my ($cls, $min, $max) = _get_next($iter);

      # If there are no more ranges in the current class, or if the latest
      # head range is not equal to the previous one, we found the end of
      # a new class. Note that head ranges can only be the same if min,max
      # are equal for both the previous and the current range, so we only
      # have to check the two min values.
      if ((not $success) or (defined $prev && $prev->[1] ne $min->{head})) {

        # The hash table obj2num is used to ensure that the same classes
        # are assigned the same state number; not doing so would result
        # an automaton that is not minimal in the number of states, and
        # minimizing it later would be considerably more costly.

        my @new = @deriv[($lengthix + 1) .. ($lengthix + $deriv[$lengthix])];
        my $ice = freeze(\@new);
        my $num = $obj2num->{$ice};
        
        if (not defined $num) {
          $num = $obj2num->{$ice} = $nextnum++;
          
          # End states store only the number of the associated class;
          # end states do not have outgoing transitions so we do not
          # add them to the todo list. Other classes are added to it.
         
          if ($deriv[$lengthix] > 1) {
            push @todo, [$lengthix, $num]
          } else {
            $s2d->{ $num } = $deriv[$lengthix + 1];
            $d2s->[ $deriv[$lengthix + 1] ] = $num;
          }
        }

        # Record the newly found transition in the transition table
        # as four-tuple <source-state, min byte, max byte, dst-state>.
        push @d, [ $currentS, $prev->[1], $prev->[2], $num ];
        
        $lengthix = $nextix++;
        $deriv[$lengthix] = 0;
        last unless $success;
      }

      # min and max always have the same width. If the width of the
      # current range is one then we are moving to an end state. If
      # it is greater than one, we are creating a new partial class.
      
      if ($min->{width} != 1) {
        $deriv[ $nextix++ ]  = $cls;
        $deriv[ $nextix++ ]  = $min->{tail};
        $deriv[ $nextix++ ]  = $max->{tail};
        $deriv[ $lengthix ] += 3;
      } else {
        $deriv[ $nextix++ ]  = $cls;
        $deriv[ $lengthix ] += 1;
      }

      $prev = [ $cls, $min->{head}, $max->{head} ]
    }
  }
  
  return $start, \@d, $d2s, $s2d;
}

sub new {
  my $class = shift;
  my %param = @_;
  my $self = bless { }, $class;
  my @input = @{$param{classes}};
  my @spans;

  # A deterministic finite automaton can only be in a single state
  # at a time, so split the input classes minimally such that each
  # code point belongs to at most a single class, not multiple ones.
  my @disjoint = intspan_partition(@input);
  
  # intspan_partition unfortunately does not keep track of how it
  # splits classes; we'd like to know, so restore the information.
  for (my $i = 0; $i <= $#disjoint; $i++) {
    for (my $j = 0; $j <= $#input; $j++) {
      next unless $disjoint[$i]->subset($input[$j]);
      push @{$self->{disjoint_to_input}->[$i]}, $j;
    }
  }

  # The construction algorithm considers all spans at once, so we
  # collect all into a single array, noting where each belongs.
  for (my $i = 0; $i <= $#disjoint; $i++) {
    foreach my $span ($disjoint[$i]->spans) {
      push @spans, [ $i, @$span ];
    }
  }
  
  # While not strictly necessary, it is better to sort the spans,
  # so we do that here. Note that spans are disjoint, so we only
  # have to compare the relevant minimum value for each span pair.
  my @sorted = sort { $a->[1] <=> $b->[1] } @spans;
  
  # Now we can generate a single list for all <class, min, max>
  # triples where min and max are utf-8 integers. It is easier to
  # do this here then telling a complete class apart from partial
  # classes generated later; the spans are not array references
  # mainly because that mirrors the C implementation more closely.
  my @u8triples = map {
    $_->[0], _u8enc($_->[1]), _u8enc($_->[2])
  } @sorted;

  my ($start, $d, $d2s, $s2d) = _triples_to_dfa(@u8triples);
  
  $self->{state_to_disjoint} = $s2d;
  $self->{disjoint_to_state} = $d2s;
  $self->{disjoint_classes} = \@disjoint;
  $self->{input_classes} = \@input;
  $self->{start_state} = $start;
  $self->{transitions} = $d;
 
  return $self; 
}

sub _regex_append {
  my $node = shift;
  my $type = shift;
  
  if (UNIVERSAL::isa($node, 'Set::IntSpan')) {

    if ($node->size == 1) {
      $_[0] .= sprintf "\\x%02x", $node->elements
      
    } else {
      $_[0] .= "[";
      
      foreach my $span ($node->spans) {
        if ($span->[0] == $span->[1]) {
          $_[0] .= sprintf "\\x%02x", $span->[0]
        } else {
          $_[0] .= sprintf "\\x%02x-\\x%02x", @$span
        }
      }
      
      $_[0] .= "]";
    }
    
  } elsif ($node->[0] eq 'Group') {
    _regex_append($node->[1], 'Group', $_[0]);
    _regex_append($node->[2], 'Group', $_[0]);
    
  } elsif ($node->[0] eq 'Choice' and $type eq 'Group') {
    $_[0] .= "(";
    _regex_append($node->[1], 'Choice', $_[0]);
    $_[0] .= "|";
    _regex_append($node->[2], 'Choice', $_[0]);
    $_[0] .= ")";
    
  } elsif ($node->[0] eq 'Choice') {
    _regex_append($node->[1], 'Choice', $_[0]);
    $_[0] .= "|";
    _regex_append($node->[2], 'Choice', $_[0]);

  } else {
    die
  }
  
}

sub as_expressions {
  my $self = shift;
  my $last = 0;
  my @m;

  require Graph::Directed;
  my $g = Graph::Directed->new;
  
  # Convert the transitions into a matrix using Set::IntSpan objects
  # to represent byte classes and use a graph to keep track of the
  # predecessors and successors of each state. Would be nice if the
  # Set::IntSpan::union method accepted undef as set to avoid the if.

  foreach my $transition (@{ $self->{transitions} }) {
    my ($src, $min, $max, $dst) = @$transition;
    
    if (defined $m[$src][$dst]) {
      $m[$src][$dst] = $m[$src][$dst]->union([[$min,$max]]);
    } else {
      $m[$src][$dst] = Set::IntSpan->new([[$min,$max]]);
    }
    
    $g->add_edge($src, $dst);
    $last = $dst > $last ? $dst : $last;
  }
  
  # States will be eliminated in the reverse order of their creation.
  # I am unsure if that produces the best result but could so far not
  # find counter-examples. A more elaborate algorithm would make sure
  # a state is removed before any, if that is possible, that must be
  # visited before or after when going from start state to final state.
  
  my @order = grep {
    
    # We only remove a state if it is neither the start state nor
    # a final state. $self->{state_to_disjoint} holds final ones.
    
    $_ != $self->{start_state} and
      not exists $self->{state_to_disjoint}->{$_}

  } (0 .. $last);
  
  while (@order) {

    my $curr = pop @order;
    my @pred = $g->predecessors($curr);
    my @succ = $g->successors($curr);
    
    # A state is eliminated by connecting all predecessors with all
    # successors by an increasingly complex regular expression. We
    # store the regular expression as a binary tree to ease adding
    # needed braces later. Note that the transition graph does not
    # have cycles, otherwise we would have to encode the cycle too.
    
    foreach my $pred (@pred) {
      foreach my $succ (@succ) {

        my $group = [ Group => $m[$pred][$curr], $m[$curr][$succ] ];
        if ($m[$pred][$succ]) {
          $m[$pred][$succ] = [ Choice => $m[$pred][$succ], $group ];
        } else {
          $m[$pred][$succ] = $group;
          $g->add_edge($pred, $succ);
        }
      }
    }
    
    $g->delete_vertex($curr);
  }
  
  # Now the matrix has a regular expression for each of the dis-
  # joint classes at m[start_state][final_state]. We iterate over
  # the disjoint classes, pretty print the expression, and return
  # them in the order of the disjoint classes.
  
  my @expressions;
  
  for (my $i = 0; $i <= $#{ $self->{disjoint_to_state} }; $i++) {
    my $final = $self->{disjoint_to_state}->[$i];
    my $regex = "";
    _regex_append($m[$self->{start_state}][$final], 'Root', $regex);
    push @expressions, $regex;
  }
  
  return @expressions;
}

1;

__END__

=head1 NAME

Unicode::SetAutomaton - UTF-8 based DFAs and Regexps from Unicode sets

=head1 SYNOPSIS

  use Unicode::SetAutomaton;
  use Set::IntSpan;

  my $set = Set::IntSpan->new([[0x000000, 0x10FFFF]]);
  my $dfa = Unicode::SetAutomaton->new(classes => [$set]);
  print $dfa->as_expressions;

=head1 DESCRIPTION

This module takes sets of Unicode characters and turns them into UTF-8
based minimal deterministic finite automata and regular expressions. 
Applications include making byte-oriented regular expression and finite
automata tools compatible with Unicode input, and possibly performance
optimizations.

The author's motivation in writing this module was a search for a fast
method to associate characters in UTF-8 encoded strings with character
classes. Ignoring memory access performance, automata produced by this
module offer a simple, general, near-optimal solution to this problem.

=head1 METHODS

=over 

=item Unicode::SetAutomaton->new(classes => [$set1, $set2, ...])

Creates a new automaton from the C<Set::IntSpan> objects. Classes must
by in the Unicode range U+0000 .. U+10FFFF. Surrogate code points may
be included but have no effect on the output as the definition of UTF-8
disallows their encoding. Sets should not be empty.

The data of the automaton can be accessed through the returned hash
reference. The following keys are available:

=over

=item start_state

The automaton's start state.

=item transitions

An array of four-tuples representing a transition. The tuples are
encoded as array reference. The items are: source state, first byte,
last byte, destination state. The automaton moves from the source
state to the destination state iff $input_byte >= $first and
$input_byte <= $last.

The set of transitions omits illegal moves, if a character is not
in any of the input sets, or if the input is not a valid UTF-8
sequence, then that is indicated by the absence of corresponding
transitions.

Accepting states do not have outgoing transitions, meaning the
automaton will never accept more than a single code point. Copying
the transitions of the start state to each accepting state yields
an automaton for strings.

For instance, the transitions for the automaton that accepts any
valid single-character UTF-8 sequence, as generated by the code in
the synopsis, might look like this:

  [ 0, 0x00, 0x7F, 1 ], [ 0, 0xC2, 0xDF, 2 ],
  [ 0, 0xE0, 0xE0, 3 ], [ 0, 0xE1, 0xEC, 4 ],
  [ 0, 0xED, 0xED, 5 ], [ 0, 0xEE, 0xEF, 4 ],
  [ 0, 0xF0, 0xF0, 6 ], [ 0, 0xF1, 0xF3, 7 ],
  [ 0, 0xF4, 0xF4, 8 ], [ 2, 0x80, 0xBF, 1 ],
  [ 3, 0xA0, 0xBF, 2 ], [ 4, 0x80, 0xBF, 2 ],
  [ 5, 0x80, 0x9F, 2 ], [ 6, 0x90, 0xBF, 4 ],
  [ 7, 0x80, 0xBF, 4 ], [ 8, 0x80, 0x8F, 4 ],

=item input_classes

An array reference of C<Set::IntSpan> objects, exactly as they have
been passed to the constructor.

=item disjoint_classes

An array reference of C<Set::IntSpan> objects. This is the smallest
set of classes such that each character in the input classes belongs
to exactly one class. Each object is a subset of an input class.

=item state_to_disjoint

A hash reference that maps a state to one of the disjoint character
classes. If there is such mapping, the state is an accepting state,
otherwise it is not in an accepting state.

=item disjoint_to_state

An array reference that maps a disjoint class to a state. Mapping
between disjoint classes and states is bijective, so this holds the
same information as the state_to_disjoint hash reference.

=item disjoint_to_input

An array reference that maps a disjoint class to one or more input
classes. For example:

  if (exists $dfa->{state_to_disjoint}->{$state}) {
    my $dset = $dfa->{state_to_disjoint}->{$state};
    my $sets = $dfa->{disjoint_to_input}->[$dset];
    print "The matched code point is in these sets: ",
      join ',', @$sets;
  }

=back

Practical applications will likely have to encode the automaton in
a different form. For example, using a binary search as transition
function the list of transitions would have to be sorted by source
state and range, and it may be beneficial to rename accepting
states so that the state numbers corresponds to the number of the
disjoint classes.

Applications that encode the transition information in arrays should
note that if the input is known to be valid UTF-8, perhaps by using
a separate DFA that ensures just that in parrallel, only the start
state has transitions from most bytes. Other states move only over
bytes in the range 0x80 .. 0xBF. So to save space, two arrays could
be used.

=item as_expressions()

Returns a list of regular expressions, one for each disjoint class,
in the order of the disjoint classes. For instance, the code in the
synopsis might print (wrapped to meet length restrictions):

  [\x00-\x7f]|([\xc2-\xdf]|\xed[\x80-\x9f]|
  ([\xe1-\xec\xee-\xef]|\xf4[\x80-\x8f]|
  [\xf1-\xf3][\x80-\xbf]|\xf0[\x90-\xbf]
  )[\x80-\xbf]|\xe0[\xa0-\xbf])[\x80-\xbf]

=back

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2008-2009 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
