package UML::State;
use strict; use warnings;

our $VERSION = "0.02";

=head1 NAME

UML::State - an object oriented module which draws simple state diagrams

=head1 VERSION

This documentation covers version 0.01, the initial release made in May 2003.

=head1 SYNOPSIS

    use UML::State;

    my $diagram = UML::State->new(
        $node_array,
        $start_list,
        $accept_list,
        $edges
    );

    # You may change these defaults (doing so may even work):
    $UML::State::ROW_SPACING = 75;  # all numbers are in pixels
    $UML::State::LEFT_MARGIN = 20;
    $UML::State::WIDTH       = 800;
    $UML::State::HEIGHT      = 800;

    print $diagram->draw();

=head1 ABSTRACT

Are you tired of pointing and clicking to make simple diagrams?  Do your
wrists hurt thinking about making the pretty UML your boss likes so well?
Consider using UML::State and UML::Sequence to make your life easier.

UML::State together with drawstate.pl allows you to easily generate
state diagrams.  You enter them in something like a cross between ASCII
art and school room algebra.  They come out looking like something from
a drawing program like Visio.  See drawstate.pl in the distribution for
details about the input format and the samples directory for some
examples of input and output.

=head1 DESCRIPTION

You will probably use this class by running drawstate.pl or drawstatexml.pl
which are included in the distribution.  But you can use this package
directly to gain control over the appearance of your pictures.

The two methods you need are new and draw (see below).  If you want, you
may change the dimensions by setting the package global variables as shown
in the SYNOPSIS.  Obviously, no error checking is done, so be careful to
use reasonable values (positive numbers are good).  All numbers are in pixels
(sorry by Bezier's in SVG seem to require pixels).  I have not tried changing
the numbers, so I don't have any idea if doing so makes reasonable changes
to the output.

=head1 EXPORT

Nothing, this module is object oriented.

=head1 METHODS

=cut

our $ROW_SPACING      = 75;
our $LEFT_MARGIN      = 20;
our $WIDTH            = 800;
our $HEIGHT           = 800;

=head2 new

This constructor expects the following things:

=over 4

=item $node_array

A reference to a two dimensional array holding the names (and implicit
positions) of the nodes in your state graph.  If you want to leave a blank
space in the diagram, include the empty string as the name of a node you
want to omit.

Example:

    $nodes = [ [ "A", "B", "C"],
               [ "D",  "", "E"] ];

This is six nodes labeled A-E arranged in two rows with three nodes in
each row.  The middle node of the second row is omitted.

=item $start_list

A reference to an array listing the start state edge(s).  Each arrow should
be of the form: col,row,head_direction tail_direction.  The entry
$node_array->[col][row] must be defined.  The directions can be any of
N, S, E, or W representing compass points on the centers of the sides of
the node's box.  N is the top center, S is the bottom center, etc.
The head_direction is the one the arrow points to.  0,0,N N is a common
start edge.

=item $accept_list

A reference to an array listing the accepting states in your graph.  Each
entry in the array should be an ordered pair col,row.  The entry
$node_array->[col][row] must be defined.  The only affect of a node being
in the accept list is to make a doubled box around its name.

=item $edges

A reference to a hash.  Each key in the hash is an edge label.  The
corresponding value is a list of edges.  Each edge is a string with
two or three parts.  The first two parts are positions and are required.
The third element is optional.  It controls curving edges.  If absent
the edge is straight.  If present it may match /Counter.*/ for
counterclockwise, or anything else for clockwise.  Trying some examples will
make more sense than what I might write.

The positions are of the same form as starting edges: col,row,direction.
The tail is listed first, then the head.  If you must include a self
referencing edge, use exactly the same entry for tail and head.
Currently this makes a small circle at that point.  Self reference circles
have no arrow head.

Examples:

    0,0,S 0,1,N Counter
    0,1,W 1,1,E
    1,1,N 1,1,N

The first edge connects the south side of the node at 0,0 to the north side
of the node at 0,1 with an arc curved in the counter-clockwise direction.
The second edge connects the west side of the node at 0,1 to the east side
of the node at 1,1.  The third edge is a self reference drawn on the north
side of node 1,1.

=back

=cut

sub new {
    my $class     = shift;

    my $self      = {
        nodes     => shift,
        starters  => shift,
        accepting => shift,
        edges     => shift,
        cols      => undef,
        rows      => undef,
        widths    => undef,
        col_pos   => undef,
        boxes     => undef,
    };
    bless $self, $class;

    $self->_count_rows_etc();
    $self->_find_col_positions();

    return $self;
}

=head1 draw

This method can be called any time after the constructor.  It returns
a string containing the svg for your state graph.  You can print that,
or parse it with standard XML techniques.

=cut
sub draw {
    my $self = shift;
    my $answer;

    $answer  = _print_header($WIDTH, $HEIGHT)
             . $self->_print_nodes()
             . $self->_print_start_arrows()
             . $self->_print_accepting();

    foreach my $edge_label (keys %{$self->{edges}}) {
        $answer .= _print_arrows(
            $edge_label,
            $self->{boxes},
            $self->{edges}{$edge_label}
        );
    }

    $answer  .= _print_footer();
    return $answer;
}

sub _count_rows_etc {
    my $self   = shift;
    my $rows   = 0;
    my $cols   = 0;
    my $widths = [];

    foreach my $row (@{$self->{nodes}}) {
        $rows++;
        if ($cols < @$row) {
            $cols = @$row;
        }
        _update_widest_of($widths, $row);
    }
    $self->{rows}   = $rows;
    $self->{cols}   = $cols;
    $self->{widths} = $widths;
}

# Note Well:  This is not a class or instance method, DON'T use -> to call it.
sub _print_header {
    my $width  = shift;
    my $height = shift;

    return <<EOJ;
<?xml version="1.0" encoding="UTF-8"?>
  <svg xmlns="http://www.w3.org/2000/svg" height="$height" width="$width">
    <defs>
      <style type='text/css'>
        rect, line, path { stroke-width: 1; stroke: black; fill: none }
      </style>
      <marker orient="auto" refY="2.5" refX="4"
              markerHeight="5" markerWidth="4" id="mArrow">
        <path style="fill: black; stroke: none" d="M 0 0 4 2 0 5"/>
      </marker>
    </defs>
EOJ
}

sub _print_nodes {
    my $self       = shift;
    my $boxes      = [];
    my $answer     = "";;

    my $row_count  = 0;
    my $box_height = $ROW_SPACING / 2;
    foreach my $row (@{$self->{nodes}}) {
        my $col_count = 0;
        my $text_y    = (1 + $row_count) * $ROW_SPACING;
        my $box_y     = $text_y - $ROW_SPACING * .25 - .05;
        my $next_x;
        foreach my $node (@$row) {
            my $x = $self->{col_pos}[$col_count];
            $next_x = $self->{col_pos}[$col_count + 1] || $LEFT_MARGIN + $WIDTH;
            my $width = .65 * ($next_x - $x); # .25; #$x - $old_x;
            unless ($node eq '') {
                my $text_x = $x + 5;
                $answer .= "<text x='$text_x' y='$text_y'>$node</text>\n";
                $x -= .1;
                $answer .= "<rect ry='10' height='$box_height' "
                        . "width='$width' y='$box_y' x='$x' />\n";
            }
            $boxes->[$col_count][$row_count] = {
                top    => $box_y,
                left   => $x,
                height => $box_height,
                width  => $width,
            };
            $col_count++;
        }
        $row_count++;
    }
    $self->{boxes} = $boxes;
    return $answer;
}

sub _print_start_arrows {
    my $self   = shift;
    my $answer = "";

    foreach my $starter (@{$self->{starters}}) {
        my ($head_end, $direction) = split /\s+/, $starter;
        my ($head_x, $head_y)      = _find_end($head_end, $self->{boxes});
        if (not defined $head_x) {
            print STDERR "Bad starting node: $starter: no such node\n";
            next;
        }
        my $length = 20;
        my ($tail_x, $tail_y);
        if    ($direction eq 'N') {
            $tail_x = $head_x;
            $tail_y = $head_y - $length;
        }
        elsif ($direction eq 'W') {
            $tail_x = $head_x - $length;
            $tail_y = $head_y;
        }
        elsif ($direction eq 'S') {
            $tail_x = $head_x;
            $tail_y = $head_y + $length;
        }
        else {      # must be East
            $tail_x = $head_x + $length;
            $tail_y = $head_y;
        }
        $answer .= "<line x1='$tail_x' y1='$tail_y' x2='$head_x' y2='$head_y' "
                .  "style='marker-end: url(#mArrow);'/>\n";
    }
    return $answer;
}

sub _print_accepting {
    my $self = shift;
    my $answer;

    foreach my $accepting_state (@{$self->{accepting}}) {
        my ($col, $row) = split /,/, $accepting_state;
        if (not defined $self->{boxes}[$col][$row]{left}) {
            print STDERR "Bad accepting state: ($col, $row): no such node\n";
            next;
        }
        my $x      = $self->{boxes}[$col][$row]{left}   +  2;
        my $y      = $self->{boxes}[$col][$row]{top}    +  2;
        my $width  = $self->{boxes}[$col][$row]{width}  -  4;
        my $height = $self->{boxes}[$col][$row]{height} -  4;
        $answer .= "<rect ry='10' height='$height' "
                . "width='$width' y='$y' x='$x' />\n";
    }
    return $answer;
}

sub _print_arrows {
    my $label  = shift;
    my $boxes  = shift;
    my $arrows = shift;
    my $answer = "";

    foreach my $arrow (@$arrows) {
        # bez is short for Bezier.
        my ($tail_desc, $head_desc, $bez) = split /\s+/, $arrow;
        my ($tail_x, $tail_y) = _find_end($tail_desc, $boxes);
        my ($head_x, $head_y) = _find_end($head_desc, $boxes);
        unless (defined $head_x and defined $tail_x) {
            print STDERR "Bad arrow: $arrow: missing node\n";
            next;
        }
        my ($text_x, $text_y) = _find_label_pos(
            $tail_x, $tail_y, $head_x, $head_y
        );
        if ($bez) {
            my ($cx, $cy, $t_control, $t_text);
            if ($bez =~ /Counter/i) { # counter clockwise
                $t_control = .25;
            }
            else {  # clockwise
                $t_control = -.25;
            }
            $t_text = $t_control / 2;

            # To calculate the quadratic Bezier control point, I use the
            # parametric equations of the line perpendicular to the line
            # joining the end points.  In those equations I make t = .25
            # or -.25 depending on the user's desired rotation (see the
            # if directly above).
            $cx = ($tail_y - $head_y) * $t_control + .5 * ($head_x + $tail_x);
            $cy = ($head_x - $tail_x) * $t_control + .5 * ($head_y + $tail_y);

            # Drawing as you read the following will be helpful.
            # Positioning the text requires three steps.  First, I find
            # the point at the intersection of the Bezier curve and the
            # perpendicular bisector of the line segment joining the end
            # points.  (That line also passes through the control point.)
            # The point I want is the midpoint along the perpendicular
            # bisector between the control point and the midpoint of
            # the segment connecting the end points.  Second, since SVG
            # text boxes are controlled by the LOWER LEFT corner, I must
            # translate the label to center it on the point I found in
            # step 1.  Third, I need to translate the label off of the curve
            # by a fixed distance along the line used in part 1 in the
            # direction of the control point.  In practice step 2 is easy
            # and I do it in combination with the translation for step 3.

            # Step 1.  Find the tangent point on the Bezier curve.
            $text_x = ($tail_y - $head_y) * $t_text + .5 * ($head_x + $tail_x);
            $text_y = ($head_x - $tail_x) * $t_text + .5 * ($head_y + $tail_y);
            # ($text_x, $text_y) is now on the tangent to the curve on the
            # line between the control point and the midpoint between the
            # end points of the curve.  Since text is fixed at the bottom
            # left point in SVG, we must translate the point to keep it
            # off the curve, but close to it.

            # Find the midpoint of the segment connecting the end points.
            my ($mid_x, $mid_y);
            $mid_x = ($head_x + $tail_x) / 2;
            $mid_y = ($head_y + $tail_y) / 2;

            # Make a unit vector from the mid point I just found,
            # to the control point.
            my ($text_vector_x, $text_vector_y);
            my $len = sqrt(($mid_x - $cx)**2 + ($mid_y - $cy)**2);
            $text_vector_x = ($cx - $mid_x) / $len;
            $text_vector_y = ($cy - $mid_y) / $len;

            # $text_vector now has a unit vector from the midpoint between the
            # connected points and the control point.

            # Steps 2 and 3.  Apply the translations.
            # Note that y increases down the screen, x increases in the
            # usual direction to the right.
            $text_x -= 4 - 10 * $text_vector_x;
            $text_y += 4 + 10 * $text_vector_y;
            $answer .= "<path d='M$tail_x $tail_y Q $cx $cy, $head_x $head_y' "
                    . "style='marker-end: url(#mArrow);' />\n";
        }
        elsif ($tail_desc eq $head_desc) {
            my ($center_x, $center_y) = _find_self_center($tail_desc, $boxes);
            $answer .= "<circle cx='$center_x' cy='$center_y' r='15' "
                    .  "style='stroke: black; fill: none;' />\n";
        }
        else {
            $answer .= "<line x1='$tail_x' y1='$tail_y' "
                    . "x2='$head_x' y2='$head_y' "
                    . "style='marker-end: url(#mArrow);'/>\n";
        }
        $answer .= "<text x='$text_x' y='$text_y'>$label</text>\n";
    }
    return $answer;
}

# Note Well:  This is not a class or instance method, DON'T use -> to call it.
sub _find_self_center {
    my $desc  = shift;
    my $boxes = shift;
    my (undef, undef, $direction) = split /,/, $desc;
    my ($x, $y) = _find_end($desc, $boxes);

    if    ($direction eq 'N') { return ($x, $y - 15); }
    elsif ($direction eq 'S') { return ($x, $y + 15); }
    elsif ($direction eq 'W') { return ($x - 15, $y); }
    else                      { return ($x + 15, $y); }
    # else is for E which is the default
}

# Note Well:  This is not a class or instance method, DON'T use -> to call it.
sub _print_footer {
    return "</svg>\n";
}

sub _find_end {
    my $desc               = shift;
    my $boxes              = shift;
    my ($col, $row, $side) = split /,/, $desc;
    my ($x, $y);

    return (undef, undef) unless (defined $boxes->[$col][$row]);
    if ($side eq 'N') {
        $x = $boxes->[$col][$row]{left} + .5 * $boxes->[$col][$row]{width};
        $y = $boxes->[$col][$row]{top};
    }
    elsif ($side eq 'W') {
        $x = $boxes->[$col][$row]{left};
        $y = $boxes->[$col][$row]{top}  + .5 * $boxes->[$col][$row]{height};
    }
    elsif ($side eq 'S') {
        $x = $boxes->[$col][$row]{left} + .5 * $boxes->[$col][$row]{width};
        $y = $boxes->[$col][$row]{top}  +      $boxes->[$col][$row]{height};
    }
    else {  # assume they want E
        $x = $boxes->[$col][$row]{left} +      $boxes->[$col][$row]{width};
        $y = $boxes->[$col][$row]{top}  + .5 * $boxes->[$col][$row]{height};
    }
    return ($x, $y);
}

sub _find_label_pos {
    my $x1 = shift;
    my $y1 = shift;
    my $x2 = shift;
    my $y2 = shift;
    my $midx = ($x1 + $x2) * .5 - 10;
    my $midy = ($y1 + $y2) * .5 - 3;

    return ($midx, $midy);
}

sub _update_widest_of {
    my $widths   = shift;
    my $elements = shift;

    for (my $i = 0; $i < @$elements; $i++) {
        my $width_guess = 20 + .5 * length $elements->[$i];
        if (not defined $widths->[$i] or $widths->[$i] < $width_guess) {
            $widths->[$i] = $width_guess;
        }
    }
}

sub _sum_widths {
    my $widths = shift;
    my $total  = 0;

    foreach my $width (@$widths) {
        $total += $width;
    }
    return $total;
}

sub _find_col_positions {
    my $self          = shift;
    my $col_positions = [];

    my $char_width = _sum_widths($self->{widths});

    my $x = $LEFT_MARGIN;
    foreach my $col (1..$self->{cols}) {
        $col_positions->[$col - 1] = $x;
        my $allocation = $self->{widths}[$col - 1]/$char_width;
        $x += $WIDTH * $allocation;
        $x = int($x * 100) / 100.0;
    }
    $self->{col_pos} = $col_positions;
}

1;

=head1 BUGS

Self reference edges are just circles, they don't have arrows.

There is no way to control the placement of labels.

Only one letter labels look good.

Resizing (changing the class constants) is unreliable.

=head1 AUTHOR

Phil Crow E<lt>philcrow2000@yahoo.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Phil Crow.  All rights reserved.  This is free software.
You may modify and/or redistribute it under the same terms as Perl 5.8.0.

=cut
