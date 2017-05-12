package Text::Glob::Expand;
use Text::Glob::Expand::Segment;
use Text::Glob::Expand::Permutation;
use warnings;
use strict;
use Carp;
use Scalar::Util qw(refaddr);
use Sub::Exporter -setup => {
    exports => {
        explode => sub { \&_explode_list },
        explode_format => sub { \&_explode_format_list },
    },
};


our $VERSION = '1.1.1'; # VERSION

# Cache ->_explode results here
our %CACHE;

# and queue cached items for deletion
our @CACHE_QUEUE;

# when the number of cached items exceeds this.
our $MAX_CACHING = 100;

######################################################################
# Private functions - read the POD to understand the terms.


# @partitions = _partition $depth, @segments;
#
# This function groups a list of segments (Text::Glob::Expand::Segment
# instances) by the brace-expression they came from, using their depth
# attributes to infer which segments go together.
#
# It works by discarding elements below the desired $depth value,
# and using the gaps to split the remainder into groups.
#
# For example, if we ignore the segments' string attribute for the
# moment and just consider their depths, given an expression like
# this:
#
#     a{a{a,a}a}a{a}a{a{a}a}a
#
# We get depths like this:
#
#     @segments = (0, 1, 2, 2, 1, 0, 1, 0, 1, 2, 1, 0)
#
# and results like this:
#
#    _partition 0, @segments # -> ([1, 2, 2, 1], [1], [1, 2, 1])
#    _partition 1, @segments # -> ([2, 2], [2])
#    _partition 2, @segments # -> ()
#
# Note, this is designed to be used internally by the ->_transform
# method, and so it does not try to check the validity and consistency
# of the data.
sub _partition {
    my $depth = shift;

    my @partitions; # An accumulator for partitions
    my $partition = [];  # The current partition under construction

    foreach my $elem (@_) {
        if ($elem->depth > $depth) {
            # Add element this to the current partition
            push @$partition, $elem;
        }
        else {
            # Start a new partition. If there is a non-empty
            # partition in construction, save it, then empty it.
            push @partitions, $partition
                if $partition
                && @$partition;
            $partition = [];
        }
    }

    # Save the last partition, if not empty
    push @partitions, $partition
        if @$partition;

    return @partitions;
}

######################################################################
# Private methods

# $permutations = $obj->_traverse(@expression)
#
# This method traverses a sub-expression and recursively expands them
# into all possible permutations, returning an arrayref to the
# resulting list of lists (of Text::Glob::Expand::Segment instances).
#
# If no arguments are given, it returns an empty arrayref.
sub _traverse {
    my $self = shift;

    # Trivial case.
    return [] unless @_;

    # Since @expression contains the elements of a glob expression,
    # each parameter param can be one of two things: a string segment
    # or a brace-expression.

    # Take the first element, and process the rest recursively.
    my $first = shift;

    if (ref $first eq 'Text::Glob::Expand::Segment') {
        # $first is a string segment - in which case we recursively
        # expand the the remaining arguments (if any) into their
        # permutations and prepend $first to each of the permutations.

        return [[$first]] unless @_;

        my $exploded = $self->_traverse(@_);
        unshift @$_, $first for @$exploded;
        return $exploded;
    }
    else {
        # $first is an brace-expression (an arrayref of alternative
        # sub-expressions) - in which case we take out each
        # alternative sub-expression $seq, concatenate it with with
        # the remaining arguments into a new expression, and
        # recursively expand the permutations of that expression.
        #
        # After processing them all, we return a concatenated list of
        # all the permutations.
        my @exploded;
        foreach my $seq (@$first) {
            die "unexpected scalar '$seq'" if !ref $seq;
            my $exploded2 = $self->_traverse(@$seq, @_);
            push @exploded, @$exploded2;
        }
        return \@exploded;
    }
}


# $root = $obj->_transform($depth, $permutation)
#
# $permutation is an arrayref of segments (Text::Glob::Expand::Segment
# instances) representing a permutation generated from a
# Text::Glob::Expand expression (i.e. one of the elements in the
# result from from _traverse).
#
# $depth is a depth to partition it by (in hindsight, perhaps this
# could be computed from the first element's depth?).
#
# The result $root is the root node of a tree structure describing the
# structure of the permutation (a Text::Glob::Expand::Permutation
# instance), by using the segments' depth attribute.  This tree is
# designed to allow the placeholders in formats to be mapped to
# expansions.
#
# See the POD within Text::Glob::Expand::Permutation for a description of 
# the structure of this result.
#
# For example, this glob expression:
#
#     "a{b{c,d,}e,f}g"
#
# Generates this set of permutations:
#
#    "abceg", "abdeg", "abeg", "afg"
#
# Permutations are generated by _traverse in terms of arrays of
# Text::Glob::Expand::Segment instances. The first permutation above
# would look like this (omitting blessings):
#
#    $permutation = [['a', 0], ['b', 1], ['c', 2], ['e', 1], ['g', 0]]
#
# This then gets passed to _transform to turn it into a
# Text::Glob::Expand::Permutation instance:
#
#     $root = $glob->_transform(0, $permutation)
#
# The structure of $root would be:
#
#    ["abceg", ["bce", ["c"]]]
#
# This is then relatively easily used to expand a format like "%1 %1.1
# %1.1.1" into "abcdeg bce c".
#
sub _transform {
    my $self = shift;
    my $depth = shift;
    my $permutation = shift;

    # Concatenate the strings from all the Text::Glob::Expand::Segment
    # instances in $permutation into one.
    my $flat =  join '', map { $_->[0] } @$permutation;

    # Group the segments deeper than $depth recursively
    if (my @deeper = _partition $depth, @$permutation) {
        return bless (
            [$flat, map { $self->_transform($depth+1, $_)} @deeper],
            'Text::Glob::Expand::Permutation',
        );
    }

    # Bless the result, to add convenience methods for the user.
    return bless [$flat], 'Text::Glob::Expand::Permutation';
}


# $permutations = $obj->_explode
#
# This generates all the permutations implied by the parsed glob
# expression.
#
# The return value is an array of Text::Glob::Expand::Permutation
# instances.
sub _explode {
    my $self = shift;

    # Permute all the alternatives in the parsed glob expression
    # into a giant list of permutations of segments.
    my $exploded = $self->_traverse(@$self);

    # Transform that into an array of tree descriptions of each
    # permutation's composition (i.e. Text::Glob::Expand::Permutation
    # instances).
    return [map { $self->_transform(0, $_) } @$exploded];
}


######################################################################
# Public methods - see POD for documentation.


sub parse {
    my $class = shift;
    my $str = shift; # The expression to parse

    # This function defines a simple state-machine to parse
    # expressions. See the documentation for an explanation of the
    # parsing rules.  The comments below assume you have read that.

    # Each character in the expression is examined in turn in a
    # for-loop. The current value is stored in $_, and the character
    # index in $pos.
    my $pos;

    # The depth of brace-nesting at $pos is stored in $depth.
    my $depth = 0;

    # Empty Text::Glob::Expand::Segment instances are created using
    # this closure. (We use a closure simply as it more convenient
    # than a constructor method.)
    my $new_segment = sub { bless ['', $depth], 'Text::Glob::Expand::Segment' };


    # (Note, expressions and brace-expressions are implemented as
    # arrayrefs, and so the [] constructor is used for them.)


    # The implementation is stack-based. It uses three stacks as follows.

    # First: a stack @c_stack to store intermediate parsed values.  We
    # construct new string segments on the top of this stack as they
    # are encountered.  At the end of an expression the top N are
    # popped off and used to construct the expression data structure.
    #
    # We initialise it with a single empty segment, since the
    # top-level expression always contains at least one.
    my @c_stack = $new_segment->();

    # Second: a stack called @alt_count is used to count how many
    # alternatives have been parsed in the current brace
    # (i.e. comma-delimited sub-expressions).  It determines how many
    # elements on @c_stack belong to it.
    my @alt_count = ();

    # Third and final: a stack called @seq_count is used to count how
    # many sequential elements (segments or brace-expressions) have
    # been parsed in the current sub-expression. As above, it
    # determines how many of the top elements on @c_stack belong to
    # it.
    #
    # We initialise it to 1, since there is always at least one
    # segment in the top level expression.
    my @seq_count = (1);


    # Some helper closures follow.  These are invoked by the state
    # machine to build the data as a side-effect.

    my $add_char = sub {
        # Append the current character ($_) to the segment under
        # construction on the top of @c_stack.  (The string is the
        # zeroth element of the segment array.)

        $c_stack[-1][0] .= $_;
    };


    my $start_brace = sub {
        # Called when an opening brace is seen.

        ++$depth;
        ++$seq_count[-1];                # Increment the current sequence counter,

        push @alt_count, 1;              # Start a new alternative list
        push @c_stack, $new_segment->(); # Start a new sub-expression
        push @seq_count, 1;
    };


    my $new_alternative = sub {
        # Called when a comma delimiter is seen.

        # Finish the last alternative: replace the appropriate number
        # of elements from @c_stack with a sub-expression arrayref
        # created from them.
        my $num_elems = pop @seq_count;
        push @c_stack, [splice @c_stack, -$num_elems];

        ++$alt_count[-1];                # Increment the number of alternatives seen
        push @seq_count, 1;              # and start a new sub-expression
        push @c_stack, $new_segment->();
    };


    my $end_brace = sub {
        # Called when a closing brace is seen.

        --$depth;

        # Finish the current alternative: replace the appropriate
        # number of elements from @c_stack with a sub-expression
        # arrayref created from them.
        my $num_elems = pop @seq_count;
        push @c_stack, [splice @c_stack, -$num_elems];

        # Finish the current brace: replace the appropriate
        # number of elements from @c_stack with a brace-expression
        # arrayref created from them.
        $num_elems = pop @alt_count;
        push @c_stack, [splice @c_stack, -$num_elems], $new_segment->();

        # Increment the sequence counter
        ++$seq_count[-1];
    };


    # Define the states in our parser as a hash.
    #
    # State names are mapped to a hash of transition definitions for
    # that state.
    #
    # Each transition has a single character which triggers it,
    # mapped to a code-ref which returns the name of the next state
    # (and optionally performs some side effect).
    #
    # Except for '' which is the default transition, used when none of
    # the others match.
    #
    # Since the whole expression muse be parsed, there is no terminal
    # state.  Termination is implicit when the end of the string is
    # reached. FIXME this means brace-matching is not properly
    # handled.
    my $states = {
        start => {
            '\\' => sub {
                'escape'
            },
            '{' => sub {
                $start_brace->();
                'start';
            },
            '}' => sub {
                $end_brace->();
                'start';
            },
            ',' => sub {
                @alt_count # This has a value added at the start of each brace
                    or die "unexpected comma outside of a brace-expression";
                $new_alternative->();
                'start';
            },
            '' => sub {
                $add_char->();
                'start';
            }
        },

        # This state is purely to handle escaping.
        escape => {
            '' => sub {
                $add_char->();
                'start';
            },
        }
    };


    my $state = 'start';  # Set the initial state.

    # Iterate over the length of the string
    for $pos (0..length($str)-1) { ## no critic RequireLexicalLoopIterators
        my $table = $states->{$state}
            or die "no such state '$state'";

        # We use this for-loop as a mechanism to alias $_ to the
        # character at $pos
        for (substr $str, $pos, 1) {

            # Get the action for this transition
            my $action =
                $table->{$_} ||
                $table->{''} ||
                die "no handler for state '$state' looking at '$_' pos $pos";

            # Invoke it
            $state = $action->();
        }
    }

    # When we get here, @c_stack will contain the fully-parsed expression.
    return bless \@c_stack, __PACKAGE__;
};



# This is a wrapper around the real implementation in ->_explode.  It
# caches the results and re-uses them when possible.
sub explode {
    my $self = shift;

    # This clause handles caching of results from ->_explode
    if ($MAX_CACHING > 0) {
        # Look ourselves up in the cache, are we there?
        my $id = refaddr $self;
        my $exploded = $CACHE{$id};

        # If yes, just return the same as last time.
        return $exploded
            if $exploded;

        # Otherwise delegate to the full implementation
        $exploded = $self->_explode(@$self);

        # And add the results to the cache, unless we've surpassed the
        # limit on caching.
        unshift @CACHE_QUEUE, $id;
        if (@CACHE_QUEUE > $MAX_CACHING) {
            delete @CACHE{splice @CACHE_QUEUE, $MAX_CACHING};
        }

        # Finally, return the new results.
        return $exploded;
    }

    # If we get here, there is no caching, so empty the cache (in case
    # $MAX_CACHING just changed).
    %CACHE = ();
    @CACHE_QUEUE = ();

    # And merely delegate to the full implementation.
    return $self->_explode(@$self);
}


# A convenience method which explodes and expands in one step.
sub explode_format {
    my $self = shift;
    my $format = shift;

    # Get the exploded result, and expand all the values using $format
    my $exploded = $self->explode;
    return {map { $_->text => $_->expand($format) } @$exploded};
}



######################################################################
# Exportable functions

# FIXME document
# FIXME test these

# A convenience function which explodes to a list of strings
sub _explode_list {

    return map {
        my $glob = __PACKAGE__->parse($_);
        map {
            $_->text;
        } @{ $glob->explode };
    } @_;
}


# A convenience function which explodes to a list of formatted strings
sub _explode_format_list {
    @_ or croak "you must supply a format parameter";

    defined (my $format = shift)
        or croak "format parameter is undefined";

    return map {
        my $glob = __PACKAGE__->parse($_);
        map {
            $_->expand($format);
        } @{ $glob->explode };
    } @_;
}


no Scalar::Util;
no Carp;
1; # Magic true value required at end of module
__END__

=head1 NAME

Text::Glob::Expand - permute and expand glob-like text patterns

=head1 VERSION

version 1.1.1

=head1 SYNOPSIS

The original use case was to specify hostname aliases and expansions
thereof.  For example, it supports basic expansion of the glob
expression into its permutations like this:

    use Text::Glob::Expand;

    my $hosts = "{www{1,2,3},mail{1,2},ftp{1,2}}";
    my $glob = Text::Glob::Expand->parse($hosts);

    my $permutations = $glob->explode;
    # result is: [qw(www1 www2 www3 mail1 mail2 ftp1 ftp2)]


But additionally, to generate full hostnames, it supports a method to
expand these permutations using a format string:

    my $permutations = $glob->explode_format("%0.somewhere.co.uk");

    # result is:
    # {
    #     www1 => 'www1.somewhere.co.uk',
    #     www2 => 'www2.somewhere.co.uk',
    #     www3 => 'www3.somewhere.co.uk',
    #     mail1 => 'mail1.somewhere.co.uk',
    #     mail2 => 'mail2.somewhere.co.uk',
    #     ftp1 => 'ftp1.somewhere.co.uk',
    #     ftp2 => 'ftp2.somewhere.co.uk',
    # }


=head1 INTERFACE


=head2 C<< $obj = $class->parse($string) >>

This is the constructor.  It implements a simple state-machine to
parse the expression in C<$string>, and returns a
C<Text::Glob::Expand> object.

You don't really need to understand the structure of this object, just
invoke methods on it.  However, see L</"PARSING RULES"> for more
details of the expression and the internal structure of the object
returned.

=head2 C<< $arrayref = $obj->explode >>

This returns an arrayref containing all the expanded permutations
generated from the string parsed by the constructor.

(The result is cached, and returned again if this is called more than
once.  See C<$MAX_CACHING>.)

=head2 C<< $hashref = $obj->explode_format($format) >>

This returns a hashref mapping each expanded permutation to a string
generated from the C<$format> parameter.

(The return value is not cached, since the result depends on C<$format>.)


=head1 PARSING RULES

Using a notation based on a subset of the Backus Naur Form described
by the
L<HTTP 1.1 RFC|http://www.w3.org/Protocols/rfc2616/rfc2616-sec2.html#sec2.1>
(with the notable exception that white-space is significant here) the
expression syntax expected by the C<< ->parse >> method can be defined
like this:

    expression =
       segment *( brace-expression segment )

A I<segment> is a sequence of zero or more characters or
escaped-characters (i.e. braces and commas must be escaped with a
preceding backslash).

    segment =
       *( escaped-character | <any character except glob-characters> )

Where:

    escaped-character =
       "\" <any char>

    glob-character =
       "{" | "}" | ","

A I<brace-expression> is a sequence of one or more I<expressions>
(which in this context I call 'alternatives'), delimited by commas,
and enclosed in braces.

    brace-expression =
       "{" expression ( "," expression )* "}"


=head1 OBJECT STRUCTURE

An expression such as described in the previous above is parsed into
an arrayref of text I<segments> (represented with
C<Text::Glob::Expand::Segment> instances) and I<brace-expressions>
(represented by arrayrefs).

An I<expression> is represented at the top level by a
C<Text::Glob::Expand> instance, which is a blessed arrayref containing
only C<Text::Glob::Expand::Segment> instances and I<brace-expression>
arrayrefs.

Each I<brace-expression> array contains a list of the
brace-expression's 'alternatives' (the comma-delimited sub-expressions
within the braces).  These are represented by arrayrefs. Apart
from being unblessed, they otherwise have the same structure as the
top-level expression.

C<Text::Glob::Expand::Segment> instances are blessed arrayrefs,
composed of a string plus an integer (>= 0) indicating the number of
brace-pairs enclosing the segment.  The depth is used internally to
preserve the expression structure, and may be ignored by the user.
(See also L<Text::Glob::Expand::Segment>.)


For example, an expression such as:

    "a{b,{c,d}e,}g"

Will be parsed into something analogous to this structure (for better
readability I use a simplified Perl data-structure in which segments
are represented by simple strings instead of blessed arrays, and use
comments to denote types):

    [ # expression
      'a', # segment depth 0
      [ # brace
        [ # expression
          'b' # segment, depth 1
        ],
        [ # expression
          '', # segment, depth 1
          [ # brace
            [ # expression
              'c' # segment, depth 2
            ],
            [ # expression
              'd' # segment, depth 2
            ],
          ],
          'e' # segment, depth 1
        ],
        [ # expression
          '' # segment, depth 1
        ]
      ],
      'g', # segment, depth 0
    ]




=head1 DIAGNOSTICS

The following parsing diagnostics should never actually occur. If they
do it means the internal data structure or code design is
inconsistent.  In this case, please file a bug report with details of
how to replicate the error.

=over 4

=item "unexpected scalar..."

=item "no such state..."

=item "no handler for state '...' looking at '...' pos '...'"

=back


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::Glob::Expand> requires no configuration files or environment
variables.

There is one configurable option in the form of a package variable, as
follows.

=head2 C<$MAX_CACHING>

The package variable C<$Text::Glob::Expand::MAX_CACHING> can be used
to control or disable the caching done by the C<< ->explode >> method.
It should be a positive integer, or zero.

The default value is 100, which means that up to 100
C<Text::Glob::Expand> objects' C<< ->explode >> results will be
cached, but no more.  You can disable caching by setting this to zero
or less.

=head1 DEPENDENCIES

The dependencies should be minimal - I aim to have none.

For a definitive answer, see the Build.PL file included in the
distribution, or use the dependencies tool on
L<http://search.cpan.org>


=head1 BUGS AND LIMITATIONS

Currently the parser will infer closing brackets at the end of an
expression if they are omitted. Probably a syntax error should be
thrown instead.

Also, extra closing brackets with no matching opening bracket will
generate an error.  This is a bug which will be addressed in future
versions.

Please report any bugs or feature requests to
C<bug-Text-Glob-Expand@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 SEE ALSO

Similar libraries I am aware of are:

=over 4

=item L<Text::Glob>

Wildcard matching against strings, which includes alternation (brace
expansion).

=item L<String::Glob::Permute>

A permutation generator similar to this one.  Supports numbered
ranges, but not format string expansion.

=back

Plus there is of course Perl's own C<glob> function, which supports
brace expansions.  That however can be sensitive to unusually-named
files in the current director - and more importantly, like
C<String::Glob::Permute> it does not implement format string
expansions.

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
