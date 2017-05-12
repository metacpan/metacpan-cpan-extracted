# Text::Tree - format a simple tree of strings into a textual tree graph

#----------------------------------------------------------------------------
#
# Copyright (C) 2003-2004 Ron Isaacson
# Portions Copyright (C) 2003 Mark Jason Dominus
# Portions Copyright (C) 2004 Ed Halley
#
#----------------------------------------------------------------------------

package Text::Tree;
use vars qw($VERSION);
$VERSION = 1.0;

=head1 NAME

Text::Tree - format a simple tree of strings into a textual tree graph

=head1 SYNOPSIS

    use Text::Tree;

    my $tree = new Text::Tree( "root",
                               [ "left\nnode" ],
			       [ "right", [ "1" ], [ "2" ] ] );
    print $tree->layout("boxed");

    __OUTPUT__

        +----+
        |root|
        +----+
      .---^---.
    +----+ +-----+
    |left| |right|
    |node| +-----+
    +----+  .-^-.
           +-+ +-+
           |1| |2|
           +-+ +-+

=cut

#----------------------------------------------------------------------------

use strict;
use warnings;

sub NBSP() { "\x01" }

=head1 METHODS

=head2 new()

    my $tree = new Text::Tree( "label",
                               [ "left child label", [ ... ] ],
			       [ "right child label", [ ... ] );

Create a new tree object from a nested set of array references.  The
first element of each array must be a string used as a node label.  The
remaining elements must each be an array reference for a child of the
node.  Labels may contain newlines to support multiple lines of text.

=cut

sub new
{
    my ($pack, $label, @subnodes) = @_;
    my @subobjects = map { $pack->new(@$_) } @subnodes;
    bless [ $label, @subobjects ] => $pack;
}

=head2 layout()

    my @lines = $tree->layout( "centered in boxes" );
    print @lines;

Lays out the tree into an array of newline-terminated strings, ready for
printing or displaying.  The optional style argument may contain various
keywords such as 'center', 'box', 'line', 'oval' and/or 'space'.  These
style keywords affect how the tree nodes are formatted.

=cut

sub layout
{
    my $tree = shift;
    my $style = shift || undef;
    my @lines = layout_tree($tree, $style);
    return map { s/\Q@{[NBSP]}/ /g; s/\s+$//; "$_\n" } @lines;
}

#----------------------------------------------------------------------------

# Support routines.

# Return the length of longest line in all arguments.  Assumes arguments
# are chomped and contain a single line of text.

sub longest
{
    return (sort { $b <=> $a } map { length } @_)[0];
}

# Ensure all lines match given width (or longest line if 0).
sub pad
{
    my $want = shift;
    $want = longest(@_) if not $want;
    my @lines = @_;
    for (@lines)
    {
	$_ .= ' ' x ($want-length($_))
	    if $want > length($_);
    }
    return @lines if wantarray;
    return $lines[0];
}

# Center and pad to the given width (or longest line if 0).
sub center
{
    my $want = shift;
    $want = longest(@_) if not $want;
    my @lines = @_;
    for (@lines)
    {
	$_ = ' ' x (($want-length($_))/2) . $_
	    if $want > length($_);
	$_ = pad($want, $_);
    }
    return @lines if wantarray;
    return $lines[0];
}

# Add box-border characters according to an 8-char style string.
# The characters are the four corners and four edges of the border.
sub border
{
    my $style = shift;
    my @style = split //, $style;
    my @lines = pad(0, @_);

    my $want = longest(@lines);
    for (@lines)
    {
	$_ = $style[5] . $_ . $style[7];
    }
    unshift(@lines, $style[0] . $style[4]x$want . $style[1]);
    push(@lines, $style[2] . $style[6]x$want . $style[3]);
    return @lines;
}

# Turn the single string label (which may have newlines) into a properly
# centered and/or padded array. The style argument may contain keywords
# to specify different aspects of the formatting.  All spaces in the
# label are turned into special NBSP characters during layout processing.

sub text
{
    my $self = shift;
    my $label = $self->[0];
    my $style = shift || '';

    # pad with spaces to width 5
    my @lines = split /\n/, $label;

    if ($style =~ /center/)
        { @lines = center(0, @lines); }
    else
        { @lines = pad(0, @lines); }

    @lines = border("        ", @lines) if $style =~ /space/;
    @lines = border('++++-|-|', @lines) if $style =~ /line|box/;
    @lines = border("..`'-|-|", @lines) if $style =~ /oval|round/;

    s/ /@{[NBSP]}/g for @lines;
    return \@lines;
}

# Return list of children trees.
sub children
{
    my $self = shift;
    my @children = @$self;

    # throw away the label
    shift @children;
    return @children;
}

# Lay out one subtree into a space-padded rectangle.
sub layout_tree
{
    my $tree = shift;
    my $style = shift;
    my @text = @{text($tree, $style)};
    my @children = children($tree);

    # recurse depth-first, left-right through $tree, returning a
    # downward view of the tree at each stop

    # if we're at a leaf node, then just return it; this is where the
    # recursion stops
    return @text unless @children;

    # build a picture of this node's children
    my @out = ();
    my $shift_len = 0;
    foreach my $child (@children)
    {
	if (@out)
	{
	    # find the length of the longest line seen so far (in the
	    # picture of this node's children), and pad all the lines seen
	    # so far to that length
	    my $pad_len = longest(@out);
	    @out = map { pad($pad_len, $_) } @out;

	    # get the downward picture from this child, and tack each line
	    # of that picture on to the right of the current picture
	    my @child = layout_tree($child, $style);
	    for (0 .. $#child)
	    {
		$out[$_] = ' ' x $shift_len if not $out[$_];
		$out[$_] .= ' ' . $child[$_];
	    }
	}
	else
	{
	    # this is the first child seen
	    @out = layout_tree($child, $style);
	}

	$shift_len += longest(@out);
    }

    # now we have the picture of all of this node's children, so we need
    # to add the text of the node itself to the top

    # we're going to want to center this node above the picture of its
    # children, but there may be additional padding on the left side if
    # any of those children have children of their own; so for the
    # purposes of centering, find the space occupied only by this node's
    # immediate children, and center the text over that

    my $blank = ($out[0] =~ /^( *)/)[0];
    my $len0 = length $out[0];
    my $center = $len0 - length($blank);

    if (@children == 1)
    {
	# if this node has only one child, then just center a "|" above it
	unshift (@out, pad($len0, $blank . center($center, "|")));
    }
    else
    {
	# if this node has multiple children, then we're not so lucky...
	# we're going to take the first line of the existing output,
	# duplicate it, and transform all of the cell borders into
	# connection points

	# start by stripping off any whitespace to the left, and holding
	# it for later
	my ($pad, $lines) = ($out[0] =~ /^( *)(.*)$/);

	# replace each block of non-whitespace (ie, a cell border) with a
	# ".", centered in the space where the border was
	$lines =~ s/(\S+)/center(length($1), ".")/ge;

	# this is going to make some additional whitespace on the left, so
	# strip that off too (and add it to what we've saved). any
	# remaining spaces are part of the connection lines, so turn them
	# into "-"'s.
	$pad .= $1 if ($lines =~ s/^( *)//);
	$lines =~ s/ *$//;
	$lines =~ s/ /-/g;

	# now we have a line that connects all of the children; figure out
	# where to attach it to its parent
	my $text0 = $blank . center($center, $text[-1]);
	$text0 =~ s/(\S+)/center(length($1), "x")/e;
	my $pos = index($text0, "x") - length($pad);

	# attach it with a reasonable character ("+" if directly over a
	# child's connection point, "^" otherwise)
	substr($lines, $pos, 1) =
	    (substr($lines, $pos, 1) eq '.' ? '+' : '^');

	# add this mess to the output
	unshift @out, pad($len0, $pad . $lines);
    }

    # now add this cell itself, properly positioned, to the output, and
    # we're done

    unshift(@out, $blank . center($center, $_)) for reverse @text;
    return @out;
}

#----------------------------------------------------------------------------

sub _test
{
    my $s = new Text::Tree( "5",
			    [ "4 1", 
			      [ "3 1\n1", 
				[ "2 1\n1 1 1", [ "1 1 1 1 1" ], ], ],
			      ] );
    my $t = Text::Tree->new( "5",
			     [ "4 1", 
			       [ "3 1\n1", 
				 [ "2 1\n1 1 1", [ "1 1 1 1 1" ], ], ],
			       [ "2 2 1", [ "1" ], $s ],
			       ], 
			     [ "3 2\n1" ] );

    my $u = Text::Tree->new( "5",
			     [ "4 1", 
			       [ "2 2 1", [ "1" ] ],
			       [ "3 1\n1", 
				 [ "2 1\n1 1 1", [ "1 1 1 1 1" ], ], ],
			       ],
			     [ "3 2\n1" ] );
    my $v = Text::Tree->new( "0", $t, $u );
    print $v->layout();
    print $/;

    my $tree = new Text::Tree( "root node",
			       [ "left node\nfunny node\nnode" ],
			       [ "right node", [ "r 1" ], [ "r 2" ] ] );
    print $tree->layout("spaced and centered in ovals");
}

1;
__END__
#----------------------------------------------------------------------------

=head1 DESCRIPTION

Allows the caller to develop a tree structure, using nested arrays of
strings and references.  Once developed, the whole tree can be printed as
a diagram, with the root of the tree at the top, and child nodes
formatted horizontally below them.

The string labels are printed as-is, or optionally surrounded with a
simple outlining style using printable ASCII characters.

This module may be used with object-oriented or simple function calls.

=head1 HISTORY

Mark Jason Dominus (aka MJD) asked for this functionality on his
Expert-level "Perl Quiz of the Week" Number 5.  You can find out more
about the QOTW discussion forum at http://perl.plover.com/qotw/

The central formatting routine was submitted by Ron Isaacson to the Quiz
forum as one possible solution to the general problem.

Ed Halley adapted the Ron Isaacson entry (with permission), to correct
some tree structures not originally handled, and to allow more formatting
options for the box styles.

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2004 by Ron Isaacson

Portions Copyright 2003 by Mark Jason Dominus

Portions Copyright 2004 by Ed Halley

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
