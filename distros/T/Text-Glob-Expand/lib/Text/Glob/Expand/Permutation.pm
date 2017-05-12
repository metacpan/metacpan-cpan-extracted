package Text::Glob::Expand::Permutation;
use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '1.1.1'; # VERSION

######################################################################
# Private methods

sub _percent_expand {
    my $self = shift;
    my $match = shift;

    if ($match eq "%") {
        return "%";
    }

    if ($match eq "0") {
        return $self->[0];
    }

    my $curr = $self;
    my @digits = split /[.]/, $1;

    while(@digits) {
        my $digit = shift @digits;

        die "invalid capture name %$1 (contains zero)"
            unless $digit > 0;
        $curr = $curr->[$digit];
        die "invalid capture name %$1 (reference to non-existent brace)\n"
            unless $curr && ref $curr;
    }
    return $curr->[0]
}


######################################################################
# Public methods - see POD for documentation

sub text { shift->[0] }

sub expand {
    my ($self, $format) = @_;
    croak "you must supply a format string to expand"
        unless defined $format;

    eval {
        # This regex-matches each capture name and replace with the
        # appropriate string.
        $format =~
            s{
                 %
                 (
                     % # An an escaped % character
                 |
                     (?: \d+ [.] )* # any number of decimals followed by a period
                     \d+            # a final decimal
                 )
             }
             {
                 $self->_percent_expand($1)
             }gex;
        1;
    }
    or do {
        # Something went wrong, report the error
        chomp(my $error = $@);
        croak "$error when expanding '$format' with '$self->[0]'";
    };

    return $format;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Text::Glob::Expand::Permutation - describes one possible expansion of a glob pattern

=head1 VERSION

version 1.1.1

=head1 SYNOPSIS

This is an internal class, in that there is no public
constructor. However, C<< Text::Glob::Expand->explode >> returns an
arrayref containing objects of this class which the user can access.

An instance's methods can be used to get the permutation text, or a
formatted version of the permutation's components. For example:

   ($first, @rest) = Text::Glob::Expand->parse("a{b,c}");
   print $first->text;
   # "ab"

   print $first->expand("text is %0 and first brace is %1");
   # "text is ab and first brace is b"

=head1 PUBLIC INSTANCE METHODS

In addition to the methods below, an instance can also be
de-referenced as an arrayref to get sub-nodes of the tree and their
values. See L</STRUCTURE>.

=head2 C<< $str = $obj->text >>

Returns the unembellished text of this permutation.

=head2 C<< $str = $obj->expand($format) >>>

Returns the string C<$format> expanded with the components of the permutation.

The following expansions are made:

=over 4

=item C<%%>

An escaped percent, expands to C<%>

=item C<%0>

Expands to the whole permutation text, the same as returned by C<< ->text >>.

=item C<%n>

(Where C<n> is a positive decimal number.)  Expands to this permutation's
contribution from the nth brace (numbering starts at 1).

This may throw an exception if the number is larger than the number of braces.

=item C<%n.n>

(Where C<n.n> is a sequence of positive decimal numbers, delimited by
periods.)  Expands to this permutations contribution from a nested
brace, if it exists (otherwise an error will be thrown).

So, for example, C<%1.1> is the first nested brace within the first
brace, and C<%10,3,2> is the second brace within the third brace
within the 10th brace.

=back


=head1 STRUCTURE

C<<Text::Glob::Expand->explode>> returns an array of
C<Text::Glob::Expand::Permutation> instances, one for each permutation
generated from the glob expression.

A C<Text::Glob::Expand::Permutation> instance is a blessed arrayref
representing the root node of a tree describing the structure of a
single permutation. This tree is designed to allow the placeholders in
string formats to be mapped to expansions (see
L<<Text::Glob::Expand->explode_format|Text::Glob::Expand/INTERFACE>>)

Each node of the tree is an arrayref, and represents a
L<brace-expression|Text::Glob::Expand/"PARSING RULES"> which
contributes a string to this permutation (except for the root node,
which corresponds to the entire
L<expression|Text::Glob::Expand/"PARSING RULES">).

The first element of a node arrayref is the node value, and the rest
are sub-trees for any nested braces with the same recursive structure, i.e.

    [$value, @subtrees]

Or in leaf nodes, more simply:

    [$value]

The indexing of tree-nodes corresponds to indexing of braces in the
expansion. For example, this glob expression:

    $glob = Text::Glob::Expand->parse("a{b,c}d{e{f{g,h},i{j,k},},l}m");

generates a set of permutations:

    print "$_->[0]\n" for @{ $glob->explode }

as follows

    'abdefgm'
    'abdefhm'
    'abdeijm'
    'abdeikm'
    'abdem'
    'abdlm'
    'acdefgm'
    'acdefhm'
    'acdeijm'
    'acdeikm'
    'acdem'
    'acdlm'

The first permutation would be expressed as a
C<Text::Glob::Expand::Permutation> with this tree structure (omitting
blessings for readability):

    ["abdefgm", ["b"], ["efg" ["fg", ["g"]]]]

You can access nodes and values using array dereferencing. To get the
node for the first brace in the second brace in the example, you might
do:

    $node = $glob->explode->[2][1] # = ["fg", ["g"]]

And to get the value of this node, get the first element:

     $value = $glob->explode->[2][1][0] # = "fg"

When using C<<Text::Glob::Expand->explode_format>>, you would refer to
this value as C<%2.1>, and it would be replaced with C<fg> for this
permutation.  C<%2.1.1> would be replaced with the value of C<g>.

So that a this:

    $glob->explode->[0]->expand("%0 %1 %2.1 %2.1.1")

Evaluates to:

   'abdefgm b fg g'

Note that not all braces contribute to all permutations, so you must
be careful when expanding format strings.  Therefore although there is a
brace corresponding to C<%2.1.1> in the first permutation, there is none
in the final one.  i.e. This will fail:

    $glob->explode->[11]->expand("%2.1.1")

    # Gets: invalid capture name %2.1.1 (reference to non-existent
    # brace) when expanding '%2.1.1' with 'acdlm'..

=head1 DIAGNOSTICS

The following errors may result when invoking the C<< ->expamd >>
method.

=over 4

=item "... when expanding '...' with '...'";

This means that the expansion mechanism failed in some way, when
expanding a format string with the given permutation.  The reason
might be one of the errors below, or something else unanticipated.

=item "invalid capture name %... (contains zero)"

Capture names must have the form described above - and in particular
cannot contain zeros except in the special case C<%0>.

=item "invalid capture name %... (reference to non-existent brace)"

Capture names may be invalid because there is no contribution from the
corresponding brace in this permutation. See L</STRUCTURE>

=item "you must supply a format string to expand"

This means you've not supplied a value to C<< ->expand >>.

=back

=head1 AUTHOR

Nick Stokoe  C<< <wulee@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, Nick Stokoe C<< <wulee@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
