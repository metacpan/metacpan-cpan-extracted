###########################################################################
#
#  Tree::Ternary
#
#  Copyright (C) 1999, Mark Rogaski; all rights reserved.
#
#  This module is free software.  You can redistribute it and/or
#  modify it under the terms of the Artistic License 2.0.
# 
#  This program is distributed in the hope that it will be useful,
#  but without any warranty; without even the implied warranty of
#  merchantability or fitness for a particular purpose.
#
###########################################################################

package Tree::Ternary;

use 5;
use strict;
use vars qw(
    @ISA
    @EXPORT_OK
    %EXPORT_TAGS
    @ATTRIBUTES
);

require Exporter;

our $VERSION = '0.04';
$VERSION = eval $VERSION;

@ISA = qw(Exporter);

# Export the attribute names
@EXPORT_OK = @ATTRIBUTES;
%EXPORT_TAGS = (attrib => [ @ATTRIBUTES ]);

BEGIN {

    #
    # I'm using Greg Bacon's design for array-based objects.
    # SPLIT_CHAR, LO_KID, EQ_KID, and HI_KID are the only ones that 
    # will be used in every node, the others will only be defined
    # in the root.
    #
    @ATTRIBUTES = qw(
        SPLIT_CHAR
        LO_KID
        EQ_KID
        HI_KID
        PAYLOAD
        NODE_COUNT
        TERMINAL_COUNT
    );

    #
    # Construct the code to declare our constants, execute, and check for
    # errors (this was so much simpler in Pascal!)
    #
    my $attrcode = join "\n",
			map qq[ sub $ATTRIBUTES[$_] () { $_ } ],
			0..$#ATTRIBUTES;

    eval $attrcode;

    if ($@) {
    	require Carp;
    	Carp::croak("Failed to initialize module index: $@\n");
    }
};

#
# Here is the terminal character.  '00' was chosen since it is not equal to
# any 8 bit character.  This is actually an improvement over the original
# C code, in that it permits the methods to be 8 bit clean.  If I include
# Unicode support, this may be replaced with some Ultra Mega meta-character.
#
sub TERM_CHAR () { '00'; }

#
# Public Methods
#

sub new {
    #
    # Create a new Tree::Ternary object
    # 
    my $class = shift;
    my $self = [];

    bless $self, $class;

    # initialize the counters
    $self->[NODE_COUNT] = 0;
    $self->[TERMINAL_COUNT] = 0;

    $self;
}


sub nodes {
    #
    # Returns the total number of nodes
    #
    my $self = shift;
    $self->[NODE_COUNT];
}


sub terminals {
    #
    # Returns the total number of terminal nodes
    #
    my $self = shift;
    $self->[TERMINAL_COUNT];
}

sub insert {
    #
    # Iterative implementation of string insertion.
    #
    # Arguments:
    #     a string to be inserted into the array
    #
    # Return value:
    #     Returns a reference to a scalar on successful insert,
    #     returns undef if the string is already in the tree.
    #
    my($self, $str) = @_;

    #
    # We can keep this implementation relatively simple and still
    # be 8 bit clean if we split the string into an array and use
    # TERM_CHAR as a terminator.
    #
    my(@char) = (split(//, $str), TERM_CHAR);

    my $ref = $self;
    my $retval = undef;

    while (@char) {

	my $char = $char[0];

        if (! defined $ref->[SPLIT_CHAR]) { # We use defined() to avoid
					    # auto-vivification.

            # create a new node
            $ref->[LO_KID] = [];
            $ref->[EQ_KID] = [];
            $ref->[HI_KID] = [];
            if (($ref->[SPLIT_CHAR] = $char) eq TERM_CHAR) {
                $self->[TERMINAL_COUNT]++;
                $ref->[PAYLOAD] = '';
                $retval = \$ref->[PAYLOAD];
            } else {
                $self->[NODE_COUNT]++;
            }

        } else {

            # here be the guts
            if ($char lt $ref->[SPLIT_CHAR]) {
                $ref = $ref->[LO_KID];
            } elsif ($char gt $ref->[SPLIT_CHAR]) {
                $ref = $ref->[HI_KID];
            } else {
                $ref = $ref->[EQ_KID];
	    	shift @char;
            }

        }

    }

    $retval;
}

sub search {
    #
    # Iterative implementation of the string search.
    #
    # Arguments:
    #     string - string to search for in the tree
    #
    # Return value:
    #     Returns a reference to the scalar payload if the string is found,
    #     returns undef if the string is not found
    #
    my($self, $str) = @_;
    my(@char) = (split(//, $str), TERM_CHAR);
    my $ref = $self;

    while (defined $ref->[SPLIT_CHAR]) {

	my $char = $char[0];

        if ($char lt $ref->[SPLIT_CHAR]) {
            $ref = $ref->[LO_KID];
        } elsif ($char gt $ref->[SPLIT_CHAR]) {
            $ref = $ref->[HI_KID];
        } else {
            if ($char eq TERM_CHAR) {
                return \$ref->[PAYLOAD];
            }
            $ref = $ref->[EQ_KID];
            shift @char;
        }
    
    }

    undef;
}

sub rinsert {
    #
    # Recursive implementation of string insertion.
    #
    # Arguments:
    #     a string to be inserted into the array
    #
    # Return value:
    #     Returns a reference to a scalar on successful insert,
    #     returns undef if the string is already in the tree.
    #
    my($self, $str) = @_;
    my(@char) = (split(//, $str), TERM_CHAR);

    return ($self->_rinsert_core($self, @char))[1];

}

sub _rinsert_core {
    #
    # Core of the rinsert() function.  This allows us to do some
    # "clean" recursion without clubbing the user over the head
    # with the gory details.
    #
    my($self, $ref, @char) = @_;
    my $retval = undef;
    my $char = $char[0];

    if (! defined($ref->[SPLIT_CHAR])) {
    
        # create a new node
        $ref->[LO_KID] = [];
        $ref->[EQ_KID] = [];
        $ref->[HI_KID] = [];
        if (($ref->[SPLIT_CHAR] = $char) eq TERM_CHAR) {
            $self->[TERMINAL_COUNT]++;
            $ref->[PAYLOAD] = '';
            $retval = \$ref->[PAYLOAD];
        } else {
            $self->[NODE_COUNT]++;
        }

    }

    if ($char lt $ref->[SPLIT_CHAR]) {
        ($ref->[LO_KID], $retval) =
	    $self->_rinsert_core($ref->[LO_KID], @char);
    } elsif ($char eq $ref->[SPLIT_CHAR]) {
        if ($char ne TERM_CHAR) {
            ($ref->[EQ_KID], $retval) =
		$self->_rinsert_core($ref->[EQ_KID], @char[1..$#char]);
        }
    } else {
        ($ref->[HI_KID], $retval) =
	    $self->_rinsert_core($ref->[HI_KID], @char);
    }

    ($ref, $retval);

}

sub rsearch {
    #
    # Recursive implementation of the string search.
    #
    # Arguments:
    #     string - string to search for in the tree
    #
    # Return value:
    #     Returns a reference to the scalar payload if the string is found,
    #     returns undef if the string is not found
    #
    my($self, $str) = @_;
    my(@char) = (split(//, $str), TERM_CHAR);

    if (defined $self->[SPLIT_CHAR]) {
	return $self->_rsearch_core($self, @char);
    } else {
	return undef;
    }

}

sub _rsearch_core {
    #
    # Core recursive function for research().
    #
    my($self, $ref, @char) = @_;
    my $char = $char[0];

    if ($char lt $ref->[SPLIT_CHAR]) {
	if (defined $ref->[LO_KID]->[SPLIT_CHAR]) {
	    return $self->_rsearch_core($ref->[LO_KID], @char);
	} else {
	    return undef;
	}
    } elsif ($char eq $ref->[SPLIT_CHAR]) {
        if ($char eq TERM_CHAR) {
            return \$ref->[PAYLOAD];
        }
	if (defined $ref->[EQ_KID]->[SPLIT_CHAR]) {
	    return $self->_rsearch_core($ref->[EQ_KID], @char[1..$#char]);
	} else {
	    return undef;
	}
    } else {
	if (defined $ref->[HI_KID]->[SPLIT_CHAR]) {
	    return $self->_rsearch_core($ref->[HI_KID], @char);
	} else {
	    return undef;
	}
    }
}

sub pmsearch {
    #
    # Pattern match function
    #
    # Arguments:
    #     wildcard - the character that is used as the wildcard
    #                in the search string
    #     string - string to search for in the tree, including
    #              wildcard replacements
    #
    # Return value:
    #     scalar context:  returns a count of strings that match
    #     array context:  returns a list of the matched strings
    #
    my($self, $wildcard, $str) = @_;
    my(@char) = (split(//, $str), TERM_CHAR);
    my(@result);

    if (defined $self->[SPLIT_CHAR]) {
    	@result = $self->_pmsearch_core($self, $wildcard, '', @char);
    }

    wantarray ? @result : scalar(@result);
}

sub _pmsearch_core {
    #
    # Core recursive function for pmsearch().
    #
    my($self, $ref, $wildcard, $candidate, @char) = @_;
    my $char = $char[0];
    my(@hitlist) = ();

    if ($char eq $wildcard or $char lt $ref->[SPLIT_CHAR]) {
	if (defined $ref->[LO_KID]->[SPLIT_CHAR]) {
        	push(@hitlist, $self->_pmsearch_core(   $ref->[LO_KID],
							$wildcard,
							$candidate,
							@char));
	}
    }

    if ($char eq $wildcard or $char eq $ref->[SPLIT_CHAR]) {
        if ($ref->[SPLIT_CHAR] ne TERM_CHAR and $char ne TERM_CHAR) {
	    if (defined $ref->[EQ_KID]->[SPLIT_CHAR]) {
		push(@hitlist,
		    $self->_pmsearch_core(  $ref->[EQ_KID],
			    		    $wildcard,
	    				    $candidate . $ref->[SPLIT_CHAR],
					    @char[1..$#char]));
	    }
        }
    }

    if ($char eq TERM_CHAR and $ref->[SPLIT_CHAR] eq TERM_CHAR) {
        push(@hitlist, $candidate);
    }

    if ($char eq $wildcard or $char gt $ref->[SPLIT_CHAR]) {
	if (defined $ref->[HI_KID]->[SPLIT_CHAR]) {
	    push(@hitlist, $self->_pmsearch_core(   $ref->[HI_KID],
						    $wildcard,
						    $candidate,
						    @char));
	}
    }

    @hitlist;

}

sub nearsearch {
    #
    # Function to find member strings within a difference-distance from
    # a specified string.
    #
    # Arguments:
    #     max_distance - the maximum number of differences between the
    #                    source string and the matched string
    #     string - string to search for in the tree
    #
    # Return value:
    #     scalar context:  returns a count of strings that match
    #     array context:  returns a list of the matched strings
    #
    my($self, $dist, $str) = @_;
    my(@char) = (split(//, $str), TERM_CHAR);
    my(@result);

    if (defined $self->[SPLIT_CHAR]) {
	@result = $self->_nearsearch_core($self, $dist, '', @char);
    }

    wantarray ? @result : scalar(@result);
}

sub _nearsearch_core {
    my($self, $ref, $dist, $candidate, @char) = @_;
    my $char = $char[0];
    my(@hitlist) = ();

    #
    # Still need this, as explained below.
    #
    if (! defined($ref->[SPLIT_CHAR]) or $dist < 0) {
        return;
    }

    if ($dist > 0 or $char lt $ref->[SPLIT_CHAR]) {
	unless (! defined($ref->[LO_KID]->[SPLIT_CHAR]) or $dist < 0) {
	    push(@hitlist, $self->_nearsearch_core( $ref->[LO_KID],
						    $dist,
						    $candidate,
						    @char));
	}
    }

    if ($ref->[SPLIT_CHAR] eq TERM_CHAR) {
        if ($#char <= $dist) {
            push(@hitlist, $candidate);
        }
    } else {
	#
	# I'm allowing this one to perform some unecessary recursion,
	# to save some recursion overhead would seriously hurt any
	# semblance of readability.  This may change in the future
	# if there is a need for this method to be a speed demon.
	#
	push(@hitlist,
    	    $self->_nearsearch_core($ref->[EQ_KID],
    		(($char eq $ref->[SPLIT_CHAR]) ? $dist : $dist - 1),
    		$candidate . (($char[0] eq TERM_CHAR) ? ''
    		    : $ref->[SPLIT_CHAR]),
    		@char[(($char eq TERM_CHAR) ? 0 : 1)..$#char]));
    }

    if ($dist > 0 or $char gt $ref->[SPLIT_CHAR]) {
	unless (! defined($ref->[HI_KID]->[SPLIT_CHAR]) or $dist < 0) {
	    push(@hitlist, $self->_nearsearch_core( $ref->[HI_KID],
						    $dist,
						    $candidate,
						    @char));
	}
    }

    @hitlist;

}

sub traverse {
    #
    # Pattern match function
    #
    # Arguments:
    #     none
    #
    # Return value:
    #     returns a sorted list of the contents of the tree
    #
    my($self, $ref, $candidate) = @_;
    my(@hitlist) = ();

    unless (defined $ref) {
        $ref = $self; # keep the method compact
        $candidate = '';
    }

    if (defined $ref->[LO_KID]->[SPLIT_CHAR]) {
	push(@hitlist, $self->traverse($ref->[LO_KID], $candidate));
    }

    if (defined $ref->[SPLIT_CHAR]) {
	if ($ref->[SPLIT_CHAR] eq TERM_CHAR) {
	    push(@hitlist, $candidate);
	}
    }

    if (defined $ref->[EQ_KID]->[SPLIT_CHAR]) {
	push(@hitlist, $self->traverse( $ref->[EQ_KID],
					$candidate . $ref->[SPLIT_CHAR]));
    }

    if (defined $ref->[HI_KID]->[SPLIT_CHAR]) {
	push(@hitlist, $self->traverse($ref->[HI_KID], $candidate));
    }

    @hitlist;

}

1;

__END__

=head1 NAME

Tree::Ternary - Perl implementation of ternary search trees.

=head1 SYNOPSIS

  use Tree::Ternary;

  $obj = new Tree::Ternary;

  $ref = $obj->insert($str);
  $ref = $obj->rinsert($str);

  $ref = $obj->search($str);
  $ref = $obj->rsearch($str);

  $cnt = $obj->nodes();
  $cnt = $obj->terminals();

  $cnt = $obj->pmsearch($char, $str);
  @list = $obj->pmsearch($char, $str);

  $cnt = $obj->nearsearch($dist, $str);
  @list = $obj->nearsearch($dist, $str);

  @list = $obj->traverse();

=head1 DESCRIPTION

Tree::Ternary is a pure Perl implementation of ternary search trees as
described by Jon Bentley and Robert Sedgewick.  

Ternary search trees are interesting data structures that provide a means
of storing and accessing strings.  They combine the time efficiency of 
digital tries with the space efficiency of binary search trees.  Unlike a
hash, they also maintain information about
relative order.

For more information on ternary search trees, visit:

L<http://www.cs.princeton.edu/~rs/strings/>

This module is a translation (albeit not a direct one) from the C 
implementation published in Bentley and Sedgewick's article in the 
April 1998 issue of Dr. Dobb's Journal (see SEE ALSO).

=head1 METHODS

=head2 new()

Creates a new Tree::Ternary object. 

=head2 insert( STRING )

Inserts STRING into the tree.  When a string is inserted, a scalar variable
is created to hold whatever data you may wish to associate with the string.
A reference to this scalar is returned on a successful insert.  If the
string is already in the tree, undef is returned.

=head2 rinsert( STRING )

This is a recursive implementation of the insert function.  It behaves
the same as insert(), except it is slower and will carp about deep 
recursion for strings near 100 characters in length.

This is included for reference purposes only and may eventually deprecated
as an alias for insert().

=head2 search( STRING )

Searches for the presence of STRING in the tree.  If the string is found, a
reference to the associated scalar is returned, otherwise undef is returned.

=head2 rsearch( STRING )

A recursive implementation of search(), suffers the same drawbacks as
rinsert().

This is included for reference purposes only and may eventually deprecated
as an alias for search().

=head2 nodes()

Returns the total number of nodes in the tree.  This count does not include
terminal nodes.

=head2 terminals()

Returns the total number of terminal nodes in the tree.

=head2 pmsearch( CHAR, STRING )

Performs a pattern match for STRING against the tree, using CHAR as a wildcard
character.  The wildcard will match any characters.  For example, if '.' was
specified as the wildcard, and STRING was the pattern ".a.a.a." would match
"bananas" and "pajamas" (if they were both stored in the tree).  In a scalar
context, returns the count of matches found.  In an array context, returns
a list of the matched strings.

=head2 nearsearch( DISTANCE, STRING )

Searches for all strings in a tree that differ from STRING by DISTANCE or fewer
characters.  In a scalar context, returns the count of matches found.  In an
array context, returns a list of the matched strings.

=head2 traverse()

Simply returns a sorted list of the strings stored in the tree.  This 
method will do more tricks in the future.

=head1 NOTES

=head2 Character Set

Tree::Ternary currently only has support for strings of 8-bit characters.
Since it uses a 2 character string to represent termination of the input
strings, it will handle any 8-bit character properly.

In the future, I plan to expand the scope of its character handling, and 
even include Unicode support.

=head2 Attributes

Specifying the :attrib tag as an argument to the use statement will export
the following internal constants for debugging purposes.  Tree::Ternary was
built using Greg Bacon's array-based object design, and these constants are
used as attribute indices.  

  SPLIT_CHAR
  LO_KID
  EQ_KID
  HI_KID
  PAYLOAD
  NODE_COUNT
  TERMINAL_COUNT

=head1 AUTHOR

Mark Rogaski <mrogaski@cpan.org>

=head1 CREDITS

Many thanks to Tom Phoenix for his invaluable advice and critique.

=head1 COPYRIGHT

Copyright (C) 1999, Mark Rogaski; all rights reserved.

This package is free software and is provided "as is" without express or
implied warranty.  It may be used, redistributed and/or modified under the
same terms as Perl itself.

=head1 SEE ALSO

Bentley, Jon and Sedgewick, Robert.  "Ternary Search Trees".  Dr. Dobbs Journal,
April 1998.  
L<http://www.drdobbs.com/database/ternary-search-trees/184410528>

Bentley, Jon and Sedgewick, Robert.  "Fast Algorithms for Sorting and
Searching Strings".  Eighth Annual ACM-SIAM Symposium on Discrete Algorithms
New Orleans, January, 1997.  
L<http://www.cs.princeton.edu/~rs/strings/>

=cut

