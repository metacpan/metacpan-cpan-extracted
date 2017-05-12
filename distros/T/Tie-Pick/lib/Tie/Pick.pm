package Tie::Pick;

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

our $VERSION = '2009110701';


sub TIESCALAR {
    my $class  =   shift;
    do { require Carp;
         Carp::croak ("tie needs more arguments")
    } unless @_;
    bless [@_] => $class;
}

sub FETCH     {
    my $values = shift;
    return undef unless @$values;
    my $index  = int rand @$values;
    unless ($index == $#$values) {
        @{$values} [$index, $#$values] = @{$values} [$#$values, $index];
    }
    pop @$values;
}

sub STORE     {
    my $self = shift;
    do { require Carp;
         Carp::croak ("assignment needs reference to non empty array")
    } unless 1 == @_ && 'ARRAY' eq ref $_ [0] && @{$_ [0]};
      @$self = @{$_ [0]};
}


1;

__END__

=pod

=head1 NAME

Tie::Pick - Randomly pick (and remove) an element from a set.

=head1 SYNOPSIS

    use Tie::Pick;

    tie my $beatle => Tie::Pick => qw /Paul Ringo George John/;

    print "My favourite beatles are $beatle and $beatle.\n";
    # Prints: My favourite beatles are John and Ringo.

=head1 DESCRIPTION

C<Tie::Pick> lets you randomly pick an element from a set, and have
that element removed from the set.

The set to pick from is given as an list of extra parameters on tieing
the scalar. If the set is exhausted, the scalar will have the undefined
value. A new set to pick from can be given by assigning a reference to
an array of the values of the set to the scalar.

The algorithm used for picking values of the set is a variant of the
Fisher-Yates algorithm, as discussed in Knuth [3]. It was first published
by Fisher and Yates [2], and later by Durstenfeld [1]. The difference
is that we only perform one iteration on each look up.

If you want to pick elements from a set, without removing the element
after picking it, see the C<Tie::Select> module.

=head1 CAVEAT

Salfi [4] points to a big caveat. If the outcome of a random generator
is solely based on the value of the previous outcome, like a linear
congruential method, then the outcome of a shuffle depends on exactly
three things: the shuffling algorithm, the input and the seed of the
random generator. Hence, for a given list and a given algorithm, the
outcome of the shuffle is purely based on the seed. Many modern computers
have 32 bit random numbers, hence a 32 bit seed. Hence, there are at
most 2^32 possible shuffles of a list, foreach of the possible algorithms.
But for a list of n elements, there are n! possible permutations.
Which means that a shuffle of a list of 13 elements will not generate
certain permutations, as 13! > 2^32.

=head1 REFERENCES

=over

=item [1]

R. Durstenfeld: I<CACM>, B<7>, 1964. pp 420.

=item [2] 

R. A. Fisher and F. Yates: I<Statistical Tables>. London, 1938.
Example 12.

=item [3]

D. E. Knuth: I<The Art of Computer Programming>, Volume 2, Third edition.
Section 3.4.2, Algorithm P, pp 145. Reading: Addison-Wesley, 1997.
ISBN: 0-201-89684-2.

=item [4]

R. Salfi: I<COMPSTAT 1974>. Vienna: 1974, pp 28 - 35.

=back

=head1 DEVELOPMENT
 
The current sources of this module are found on github,
L<< git://github.com/Abigail/tie--pick.git >>.

=head1 AUTHOR
    
Abigail L<< <cpan@abigail.be> >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 1999, 2009 by Abigail

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
