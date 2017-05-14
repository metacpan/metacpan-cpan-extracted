package Text::Trie;

use integer;
require 5.000;
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(Trie walkTrie);

$step = 1 unless defined $step;	# Length of unit. All the arguments should 
				# have length that is multiple of this.
				# Length of any cell in trie will be multiple
				# too.

sub Trie {
  my @list = @_;
  return shift if @_ == 1;
  my %first;
  my @ans;
  foreach (@list) {
    $c = substr $_, 0, $step;
    $first{$c} = [] unless defined $first{$c};
    push @{$first{$c}}, $_;
  }
  foreach (keys %first) {
    # Find common substring
    my $substr = $first{$_}->[0];
    (push @ans, $substr), next if @{$first{$_}} == 1;
    $l = length($substr) / $step * $step;
    foreach (@{$first{$_}}) {
      $l -= $step while substr($_, 0, $l) ne substr($substr, 0, $l);
    }
    $substr = substr $substr, 0, $l;
    # Return value
    @list = map {substr $_, $l} @{$first{$_}};
    push @ans, [$substr, Trie(@list)];
  }
  @ans;
}

sub walkTrie {
  my ($singlesub,$headsub,$notsinglesub,$sepsub,$opensub,$closesub,@trie) = @_;
  my $num = 0;
  foreach (@trie) {
    &$sepsub($_) if $num++ and defined $sepsub;
    if (defined ref $_ and ref $_ eq 'ARRAY') {
      &$opensub($_) if defined $opensub;
      &$headsub(@$_[0]) if defined $headsub;
      if ($#$_ > 1) {
	&$notsinglesub($_) if defined $notsinglesub;
	walkTrie($singlesub, $headsub, $notsinglesub, $sepsub, $opensub, 
		 $closesub, @{$_}[1 .. $#$_]);
      }
      &$closesub($_) if defined $closesub;
    } else {
      &$singlesub($_) if defined $singlesub;
    }
  }
}

1;
__END__

=head1 Name

Text::Trie

=head2 Usage

  use Text::Trie qw(Trie walkTrie);
  @trie = Trie 'abc', 'ab', 'ad';
  walkTrie sub {print("[",shift,"]")}, sub {print(shift)}, sub {print "->"}, 
    sub {print ","}, sub {print "("}, sub {print ")"}, @trie;

=over 9

=item C<Trie>

Given list of strings returns an array that consists of common heads
and tails of strings. Element of an array is a string or an array
reference. Each element corresponds to a I<group> of arguments.

Arguments are split into I<groups> according to the first letter. If
group consists of one element, it results in the string element in
the output array. If group consists of several elements, then the
corresponding element of output array looks like

  [$head, ...]

where $head is the common head of the group, the rest is the result of
recursive application of C<Trie> to tails of elements of the group.

=item C<walkTrie>

Takes 6 references to subroutines and an array as arguments. Array is
interpreted as output of C<Trie>, the routine walks over the tree
depth-first. If element of the array is a reference to array, it is
interpreted as a node, and the C<walkTrie> is applied to the
corresponding array (without the first element) recursively. Otherwise the
element is interpreted as a leaf of the tree.

Subroutines are executed when (in the order of arguments of C<walkTrie>):

=over 4

=item *

a leaf of the tree is met, argument is the corresponding element of array;

=item *

a node is met, argument is the first element of the corresponding array;

=item *

a node that is not-empty is met, argument is the reference to the
corresponding array; is called I<after> the previous one;

=item *

between two sibling nodes or leafs, argument is the next node or leaf;

=item *

I<before> executing any other code for a node, argument is the node;

=item *

I<after> executing any other code for a node, argument is the node;

=back

Any one of the first six arguments can be C<undef> instead of being a
reference to a subroutine.

=back

=head2 Exports

None by default, C<Trie> and C<walkTrie> are @EXPORTABLE.

=head2 Configuration

Variable $Text::Trie::step can be set to a value bigger than 1 to
set the length of smallest units arguments can be broken into.

=head1 AUTHOR

Contact Ilya Zakharevich, I<ilya@math.ohio-state.edu>.

=cut
