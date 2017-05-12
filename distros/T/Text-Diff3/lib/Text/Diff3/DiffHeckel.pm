package Text::Diff3::DiffHeckel;
# two-way diff plug-in
use 5.006;
use strict;
use warnings;
use base qw(Text::Diff3::Base);

use version; our $VERSION = '0.08';

sub diff {
    my($self, $A, $B) = @_;
    my $f = $self->factory;
    if (! $self->_is_a_text($A)) {
        $A = $f->create_text($A);
    }
    if (! $self->_is_a_text($B)) {
        $B = $f->create_text($B);
    }
    my $diff = $f->create_list2;
    my @uniq = (
        [$A->first_index - 1, $B->first_index - 1],
        [$A->last_index  + 1, $B->last_index  + 1]
    );
    my(%freq, %ap, %bp);
    for my $lineno ($A->range) {
        my $s = $A->at($lineno);
        $freq{$s} += 2;
        $ap{$s} = $lineno;
    }
    for my $lineno ($B->range) {
        my $s = $B->at($lineno);
        $freq{$s} += 3;
        $bp{$s} = $lineno;
    }
    while (my($s, $x) = each %freq) {
        next if $x != 5;
        push @uniq, [$ap{$s}, $bp{$s}];
    }
    @uniq = sort { $a->[0] <=> $b->[0] } @uniq;
    my($AL, $BL) = ($A->last_index,  $B->last_index);
    my($a1, $b1) = ($A->first_index, $B->first_index);
    while ($a1 <= $AL && $b1 <= $BL && $A->eq_at($a1, $B->at($b1))) {
        $a1++;
        $b1++;
    }
    my($a0, $b0) = ($a1, $b1);
    for (@uniq) {
        my($auniq, $buniq) = @{$_};
        next if $auniq < $a0 || $buniq < $b0;
        ($a1, $b1) = ($auniq - 1, $buniq - 1);
        while ($a0 <= $a1 && $b0 <= $b1 && $A->eq_at($a1, $B->at($b1))) {
            $a1--;
            $b1--;
        }
        if ($a0 <= $a1 && $b0 <= $b1) {
            $diff->push($f->create_range2('c', $a0, $a1, $b0, $b1));
        } elsif ($a0 <= $a1) {
            $diff->push($f->create_range2('d', $a0, $a1, $b0, $b0 - 1));
        } elsif ($b0 <= $b1) {
            $diff->push($f->create_range2('a', $a0, $a0 - 1, $b0, $b1));
        }
        ($a1, $b1) = ($auniq + 1, $buniq + 1);
        while ($a1 <= $AL && $b1 <= $BL && $A->eq_at($a1, $B->at($b1))) {
            $a1++;
            $b1++;
        }
        ($a0, $b0) = ($a1, $b1);
    }
    return $diff;
}

sub _is_a_text {
    my($self, $x) = @_;
    return eval{ $x->can('first_index') }
        && eval{ $x->can('last_index') }
        && eval{ $x->can('range') }
        && eval{ $x->can('at') }
        && eval{ $x->can('eq_at') };
}

1;

__END__
=pod

=head1 NAME

Text::Diff3::DiffHeckel - two-way diff component

=head1 VERSION

0.08

=head1 SYNOPSIS

  use Text::Diff3;
  my $f = Text::Diff3::Factory->new;
  my $p = $f->create_diff;
  my $mytext   = $f->create_text([map {chomp; $_} <F0> ]);
  my $original = $f->create_text([map {chomp; $_} <F1> ]);
  my $diff2 = $p->diff($original, $mytext);
  $diff2->each(sub{
      my($r) = @_;
      print $r->as_string, "\n";
      if ($r->type ne 'a') { # delete or change
          print '-', $original->as_string_at($_) for $r->rangeA;
      }
      if ($r->type ne 'd') { # append or change
          print '+', $mytext->as_string_at($_) for $r->rangeB;
      }
  });

=head1 DESCRIPTION

This is a package for Text::Diff3 to compute difference sets between
two text buffers based on the P. Heckel's algorithm.
Anyone may change this to an another diff or a its wrapper module
by a your custom Factory instance.

Text::Diff3 needs a support of computing difference sets between
two text buffers (diff). As the diff(1) command, the required diff
module creates a list of tipples recorded an information set of a
change type (such as a, c, or d) and a range of line numbers
between two text buffers.

Since there are several algorithms and their implementations for
the diff computation, Text::Diff3 makes a plan independent on any
specific diff routine. It calls a pluggable diff processor instance
specified in a factory commonly used in Text::Diff3. Anyone may
change diff plug-in according to text properties.

For users convenience, Text::Diff3 includes small diff based on the
P. Heckel's algorithm. On the other hands, many other systems use
the popular Least Common Sequence (LCS) algorithm. The merits for
each algorithm are case by case. In author's experience, two algorithms
generate almost same results for small local changes in the text.
In some cases, such as moving blocks of lines, it happened quite
differences in results.

=head1 METHODS

=over

=item C<< $f->create_diff >>

Author recommends you to create an instance of diff processor
by using with a factory as follows.

  use SomeFactory;
  my $f = SomeFactory->new;
  my $p = $f->create_diff;

Text::Diff3::Factory is a class to packaging several classes
for the building diff processor.

=item C<< $p->diff($origial, $mytext) >>

Performing the diff process, we send a `diff' message with two
text instances to the receiver,

  my $diff2 = $p->diff($origial, $mytext);

where the parameters of text are a kind as follows.

=over 2

=item *

Scalar string separated by "\n".

=item *

References of a one-dimensional array.

=item *

An already blessed instance by Text::Diff3::Text or an equivalent
type as one.

=back

After the process, the receiver returns the list as difference sets.

=back

=head1 SEE ALSO

P. Heckel. ``A technique for isolating differences between files.''
Communications of the ACM, Vol. 21, No. 4, page 264, April 1978.

Text::Diff3::Diff3

=head1 COMPATIBILITY

Use new function style interfaces introduced from version 0.08.
This module remained for backward compatibility before version 0.07.
This module is no longer maintenance after version 0.08.

=head1 AUTHOR

MIZUTANI Tociyuki C<< <tociyuki@gmail.com> >>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 MIZUTANI Tociyuki

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

=cut

