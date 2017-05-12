package Text::LookUpTable;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);

$VERSION = 0.05;
use 5.6.1;

use overload q("") => \&as_string;

use Text::Aligner qw(align);
use File::Slurp qw(read_file);

=head1 NAME

Text::LookUpTable - Perl5 module for text based look up table operations

=head1 SYNOPSIS

  $tbl = Text::LookUpTable->load_file('my_table.tbl');
  $tbl = Text::LookUpTable->load($str_tbl);
  $tbl = Text::LookUpTable->load_blank($x_size, $y_size, $x_title, $y_title);

  print $tbl;
  $str_tbl = "$tbl";

  $tbl->save_file();
  $tbl->save_file('my_table.tbl');

  $tbl->set($x, $y, $val);

  @diff_coords = $tbl->diff($tbl2);
  $diffp = $tbl->diff($tbl2, 1);  # true/false no coordinates

  @xdiffs = $tb1->diff_x_coords($tb2);
  @ydiffs = $tb1->diff_y_coords($tb2);

  @x_coords = $tbl->get_x_coords();
  @y_coords = $tbl->get_y_coords();

  $res = $tbl->set_x_coords(@x_coords);
  $res = $tbl->set_y_coords(@y_coords);

  @ys = $tbl->get_y_vals($x_offset);
  @xs = $tbl->get_x_vals($y_offset);

  $str_plot = $tbl->as_plot('R');
  print FILE $str_plot;

=head1 DESCRIPTION

Text::LookUpTable provides operations for creating, storing, displaying,
plotting, loading, and querying a I<look up table> structure.  The format
of the stored structure is designed to be visually easy to understand
so that it can be easily edited using a text editor.

The authors inteded use of this library is to allow a user to edit a
text file representation of a look up table which can then be loaded
in to an embedded controller such as MegaSquirt [http://www.msextra.com].
Additional code would be needed to convert this generic structure
to whatever application specific format is required.

What is a I<look up table> and how is it different than a I<table>?
A I<look up table> is commonly used in embedded controllers to avoid the
use of costly floating pointing operations by looking up a value based
on the input coordiantes.  A function with two inputs (f(x, y)) which
would use floating point operations can be represented (with some loss
in precsion) as a table.

In contrast a I<table> (or spreadsheet) has any number of columns/rows.
The columns can be of different types.  And a table does not try to represent
any sort of function, it just stores data.

=head1 STRING FORMAT

The format of the look up table when stored to a string or file should
look like the example below.

                        rpm
 
              [1000]   [1500]  [2000]  [2500]
       [100]  14.0     15.5    16.4    17.9
  map  [90]   13.0     14.5    15.3    16.8
       [80]   12.0     13.5    14.2    15.7

The x (across top) and y (left column) coordinates have there values
enclosed in square brackets.  All values must be present.
And the titles can only span one line.  There can be any number of
lines and spaces as long as the values can be discerned.
When saving and restoring a table the original spacing will not be
preserved.

The x values start at offset 0 at the left and increase towards the right.
The y values start at offset 0 at the bottom and increase upward.

=head1 OPERATIONS

=cut

#
# DEVNOTE:
# The position offset calculations are quite tedious.
# It is recommended to use only the high level functions already defined
# to access these values and to not access the structure in the object directly.
#

# {{{ load

=head2 Text::LookUpTable->load($string);

  Returns: a new table object on success, FALSE on error

Creates a new look up table object by parsing the given string.
See the section I<STRING FORMAT> for details on format it expects.

If you want to load a table from a I<file> see I<load_file>.

=cut

sub load {
	my $class = shift;
	my $str_tbl = shift;


	#  An example of a displayed look up table.
	#
    #                        rpm
    # 
    #              [1000]   [1500]  [2000]  [2500]
    #       [100]  14.0     15.5    16.4    17.9
    #  map  [90]   13.0     14.5    15.3    16.8
    #       [80]   12.0     13.5    14.2    15.7
	#
	#
	#
	# The text is split on spaces and based on the number of spaces
	# it is determined which data is which.
	#
	# The x title should have 1 value with spaces on either side.
	#
	# The x coordinates should have num_x values in square brackets []
	#
	# A regular row should have num_x values + 1 coordinates in square brackets.
	#
	# The row with the y title should have num_x values + 2
	#

	my @lines = split /\n/, $str_tbl;

	my $x_title;
	my $y_title;
	my @x_coords;
	my @y_coords;
	my $num_x_coords;
	my $num_y_coords = 0;
	my @vals;

	for (my $i = 0; $i < @lines; $i++) {
		my $line = $lines[$i];
		my @raw_parts = split /[\s]+/, $line;

		# split saves some entries even though they are blank.
		# Particularly the title has two values and one is blank.
		# Remove these blank entries.
		my @parts;
		foreach my $part (@raw_parts) {
			if ($part =~ /\w/) {
				push @parts, $part;
			}
		}

		my $num_parts = @parts;

		#print "num_parts: $num_parts\n"; # DEBUG

		# skip blank lines
		next if (0 == $num_parts);

		if (1 == $num_parts) {

			if (defined $x_title) {
				carp "ERROR: Multi line x titles are not supported, error on line " . ($i + 1) . "";
				return;
			}

			$x_title = $parts[0];
			#print "x_title: '$x_title'\n"; # DEBUG

			next;
		}

		# x coordinates line across top with values in square brackets
		if (! defined $num_x_coords) {
			$num_x_coords = $num_parts;

			foreach my $part (@parts) {
				$part =~ s/\[//;
				$part =~ s/\]//;

				push @x_coords, $part;
			}
			#print "x_coord[1]: " . $x_coords[3] . "\n"; # DEBUG

			next;
		}

		# y title, 1 y coordinate, and data
		# Take the title, remove it from @parts and let
		# the data be processed in the next step
		if (($num_x_coords + 2) == $num_parts) {

			if (defined $y_title) {
				carp "ERROR: Multi line y titles are not supported, error on line " . ($i + 1) . "";
				return;
			}

			$y_title = $parts[0];
			#print "y_title: $y_title\n";  # DEBUG

			shift @parts;  # remove the title
			$num_parts--;
		}

		# a normal row
		if (($num_x_coords + 1) == $num_parts) {
			$num_y_coords++;

			my $part = shift @parts;
			$part =~ s/\[//;
			$part =~ s/\]//;

			push @y_coords, $part;

			push @vals, [@parts];

			next;
		}

		# If we got here something is wrong!
		my $line_num = $i + 1;
		carp "ERROR: The data on line " . ($i + 1) . " or before is irregular";
		return;
	}

	bless {
		x_title => $x_title,
		y_title => $y_title,
		x => \@x_coords,
		y => \@y_coords,
		vals => \@vals,
	}, $class;
}
# }}}

# {{{ load_file

=head2 Text::LookUpTable->load_file($file)

  Returns: new object on success, FALSE on error

Works like I<load> but obtains the text from the $file first.

Stores the name of file so that save_file can be used without
having to specify the file again.

=cut

sub load_file {
	my $class = shift;
	my $file = shift;

	unless (-e $file) {
		carp "ERROR: File '$file' does not exist.";
		return;
	}

	my $str_tbl = read_file($file);  # File::Slurp

	my $new_tbl = Text::LookUpTable->load($str_tbl);

	$new_tbl->{file} = $file;

	return $new_tbl;
}
# }}}

# {{{ load_blank

=head2 Text::LookUpTable->load_blank($x_size, $y_size, $x_title, $y_title)

  Returns: new object on success, FALSE on error

Creates a blank object with all values initialized to zero and
dimensions of $x_size and $y_size.

=cut

sub load_blank {
	my $class = shift;
	my $x_size = shift;
	my $y_size = shift;
	my $x_title = shift;
	my $y_title = shift;

	unless (defined $x_size and $x_size > 0) {
		carp "ERROR: x_size must be a value > 0, '$x_size' invalid.";
		return;
	}

	unless (defined $y_size and $y_size > 0) {
		carp "ERROR: y_size must be a value > 0, '$y_size' invalid.";
		return;
	}

	unless (defined $x_title and $x_title ne '') {
		carp "ERROR: x_title must be a non-empty string, '$x_title'.";
		return;
	}

	unless (defined $y_title and $y_title ne '') {
		carp "ERROR: y_title must be a non-empty string, '$y_title'.";
		return;
	}

    my @xs;
    for (my $i = 0; $i < $x_size; $i++) {
        $xs[$i] = 0;
    }

    my @ys;
    for (my $i = 0; $i < $y_size; $i++) {
        $ys[$i] = 0;
    }

    my @vals;
    for (my $i = 0; $i < $y_size; $i++) {
        push @vals, [@xs];
    }

    bless {
        x_title => $x_title,
        y_title => $y_title,
        x => \@xs,
        y => \@ys,
        vals => \@vals,
    }, $class;
}
# }}}

# {{{ as_string

=head2 $tbl->as_string();

  Returns string on success, FALSE on error.

Convert the object to a string representation.

This operation is used to overload the string operation so
the shorthand form can be used.

  print $tbl;         # print the object as a string

  $to_save = "$tbl";  # get the string format to be saved

The long hand form $tbl->as_string(); should not normally be needed.

=cut


#  An example of a displayed look up table.
#
#               rpm
#
#             [12]   [15]  [17]  [35]   (x coordinates title)
#      [100]  3      15    4     2
# map  [120]  10     12    3     4
#      [130]  15.2   12    13    20
#


sub as_string {
	my $self = shift;

	my $SPACE = '  ';
	my $num_y = @{$self->{y}};
	my $num_x = @{$self->{x}};

	# Once it is know how many rows will be displayed
	# it can be determined which row to place the y_title on.
	#
	# The first 3 lines are for the title, so ignore those for
	# these calculations.
	#
    # $c is the line from offset 0, to place the y title on.
	my $c = int($num_y / 2);

	my $num_rows = $num_y + 1;  # add 1 for x coordinates

    # y title column
	my @yt_column;
	for (my $i = 0; $i < $num_rows; $i++) {
		$yt_column[$i] = ($i == $c) ? " " . $self->{y_title} : " ";
	}
	@yt_column = align('left', @yt_column);

	# y coordinates column
	my @y_column;
	$y_column[0] = " ";
	for (my $i = 1; $i < $num_rows; $i++) {
		$y_column[$i] = " [" . $self->{y}[$i - 1] . "] ";
	}
	@y_column = align('left', @y_column);

	# x coordinate and values column
	my @val_cols;
	for (my $i = 0; $i < $num_x; $i++) {
		                                              # XXX
		my @vals = ("[" . $self->{x}[$i] . "]", (reverse $self->get_y_vals($i)));

		my @col = align('left', @vals);

		push @val_cols, \@col;
	}

	my @lines;
	for (my $i = 0; $i < $num_y + 1; $i++) {
		# first the y title and y coordinate values
		my $line = $yt_column[$i] . $SPACE . $y_column[$i];

		# then the rest of the values
		for (my $j = 0; $j < $num_x; $j++) {
			$line .= $SPACE . $val_cols[$j][$i];
		}

		push @lines, $line;
	}


	# The x title is treated separately without using align().
	# All the rest is formatted with align().
	my $x_title = $self->{x_title};
	my $len = length $lines[0];
	my $len_t = length $x_title;
	if ($len_t > $len) {
		warn "x title is too big!";
		return undef;
	}
	my $gap = $len - $len_t;
	my $gap_one = int($gap / 2);
	my $fill = " " x $gap_one;

	my $str = "\n" . $fill . $x_title . "\n\n";

	$str .= join "\n", @lines;

	$str .= "\n";

	return $str;
}

# }}}

# {{{ save

=head2 $tbl->save_file($file);

  Returns TRUE on success, FALSE on error

Optional argument $file, can specify the file to save to.
If ommitted it will save to the last file that was used.
If no last file is stored it will produce an error.

=cut

sub save_file {
	my $self = shift;
	my $file = shift;

	if (! defined $file or $file =~ /^[\s]+$/) {
		carp "ERROR: trying to save but no file specified and no file stored.";
		return;
	}

	$self->{file} = $file;

	my $res = open FILE, "> $file";
	if (! $res) {
		carp "ERROR: unable to open file '$file': $!";
		return;
	}

	print FILE $self;

	close FILE;

	return 1;  # success
}

# }}}

# {{{ get_*_coords

=head2 $tbl->get_*_coords();

  Returns list of all x/y coordinates on success, FALSE on error

Offset 0 for the X coordinates start at the LEFT of the displayed table
and increases RIGHTWARD.

Offset 0 for the Y coordinates start at the TOP of the displayed table
and increases DOWNWARD.

  @xs = $tbl->get_x_coords();
  @ys = $tbl->get_y_coords();

=cut

sub get_x_coords {
	my $self = shift;

	@{$self->{x}};
}

sub get_y_coords {
	my $self = shift;

	@{$self->{y}};
}
# }}}

# {{{ set_*_coords

=head2 $tbl->set_*_coords(@new_coords);

  Returns TRUE on success, FALSE on error

Assigns the x/y coordinates to the values given in the list.

  $res = $tbl->set_x_coords(@new_x_coords);
  $res = $tbl->set_y_coords(@new_y_coords);

=cut

sub set_x_coords {
	my $self = shift;
    my @vals = @_;

    my $num_x_coords = @{$self->{x}};
    my $num_new_x_coords = @vals;

    if ($num_x_coords != $num_new_x_coords) {
        carp "ERROR: The number of x coordinates must be the same ($num_x_coords != $num_new_x_coords)";
        return;
    }

    $self->{x} = [@vals];

    return 1;
}

sub set_y_coords {
	my $self = shift;
    my @vals = @_;

    my $num_y_coords = @{$self->{y}};
    my $num_new_y_coords = @vals;

    if ($num_y_coords != $num_new_y_coords) {
        carp "ERROR: The number of y coordinates must be the same ($num_y_coords != $num_new_y_coords)";
        return;
    }

    $self->{y} = [@vals];

    return 1;
}
# }}}

# {{{ get_*_vals

=head2 $tbl->get_*_vals($offset);

  Returns list of values on success OR FALSE on error

Retrives all values for a given offset.

 @xs = get_x_vals($y_offset);
 @ys = get_y_vals($x_offset);

The 0 offset of the returned list will correspond to the 0 offset of the displayed
table.

=cut

sub get_y_vals {
	my $self = shift;
	my $x = shift;

	my $num_x = @{$self->{x}};
	my $num_y = @{$self->{y}};

	unless ($x < $num_x) {
		carp "ERROR: there is no y value at position $x";
		return;
	}

	my @res_vals;
	my $vals = $self->{vals}; 
	for (my $i = 0; $i < $num_y; $i++) {
		my $xs = $vals->[$i];

		unshift @res_vals, $xs->[$x];
		# The bottom y value in the displayed table is at offset zero
		# this is why unshift is used instead of push.
	}

	return @res_vals;
}

sub get_x_vals {
	my $self = shift;
	my $y = shift;

	my $num_x = @{$self->{x}};

	unless ($y < $num_x) {
		carp "ERROR: y offset $y is out of bounds";
		return;
	}

	my $vals = $self->{vals}; 

	return (@{$self->{vals}[$y]});
}

# }}}

# {{{ set

=head2 $tbl->set($x, $y, $val);

  Returns TRUE on success OR FALSE on error

Set the value to $val at the given $x and $y coordinate offset.

=cut

sub set {
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $val = shift;

	my $num_x = @{$self->{x}};
	my $num_y = @{$self->{y}};

	unless ($y < $num_y) {
		carp "ERROR: A y offset of $y is beyond the boundary ".($num_y - 1)."";
		return;
	}

	unless ($x < $num_x) {
		carp "ERROR: A x offset of $x is beyond the boundary ".($num_x - 1)."";
		return;
	}

	$self->{vals}[($num_y - 1) - $y][$x] = $val;
	# See get() for an explanation of the $y calculation

	return 1; # success
}
# }}}

# {{{ get

=head2 $tbl->get($x, $y);

  Returns $value on success, FALSE on error

Get the value at the given $x and $y coordinate offset.

=cut

sub get {
	my $self = shift;
	my $x = shift;
	my $y = shift;

	my $num_x = @{$self->{x}};
	my $num_y = @{$self->{y}};

	unless ($y < $num_y) {
		carp "ERROR: A y offset of $y is beyond the boundary ".($num_y - 1)."";
		return;
	}

	unless ($x < $num_x) {
		carp "ERROR: A x offset of $x is beyond the boundary ".($num_x - 1)."";
		return;
	}

	#
	# The y offset starts at 0 at the bottom, not the top so it must be adjusted.
	# (length(@ys) - 1) - y
	#
	# 0 -> 4
	# 1 -> 3
	# 2 -> 2
	# 3 -> 1
	# 4 -> 0
	#
	$self->{vals}[($num_y - 1) - $y][$x];
}
# }}}

# {{{ diff

=head2 $tb1->diff($tb2, $break);

  Returns TRUE if different, FALSE otherwise.

  If $break is FALSE it returns a list of positions that are different.

Determines whether the VALUES two tables are different.
Does not check if the coordinates or the titles are different.

If $brake is FALSE return a complete list of coordinates that are different.
If $brake is TRUE it breaks out and returns as soon it is found that they are
different for a slight performance improvement.

=cut

sub diff {
	my $tbl1 = shift;
	my $tbl2 = shift;
	my $break = shift;

	my $num_x = ($tbl1->get_x_coords());
	my $num_y = ($tbl1->get_y_coords());

	my @diff_points;
	for (my $i = 0; $i < $num_x; $i++) {
		my @ys1 = $tbl1->get_y_vals($i);
		my @ys2 = $tbl2->get_y_vals($i);

		for (my $j = 0; $j < $num_y; $j++) {
			if ($ys1[$j] != $ys2[$j]) {
				push @diff_points, [$i, $j];

				return 1 if ($break);
			}
		}
	}

	if (@diff_points) {
		return @diff_points;
	} else {
		return 0;
	}
}
# }}}

# {{{ diff_*_coords

=head2 $tb1->diff_*_coords($tb2)

  Returns list of differences on success, FALSE on error

 @xdiffs = $tb1->diff_x_coords($tb2);
 @ydiffs = $tb1->diff_y_coords($tb2);

=cut

sub diff_x_coords {
	my $tbl1 = shift;
	my $tbl2 = shift;

    my @coords1 = $tbl1->get_x_coords();
    my @coords2 = $tbl2->get_x_coords();

    _diff_coords(\@coords1, \@coords2);
}

sub diff_y_coords {
	my $tbl1 = shift;
	my $tbl2 = shift;

    my @cs1 = $tbl1->get_y_coords();
    my @cs2 = $tbl2->get_y_coords();

    _diff_coords(\@cs1, \@cs2);
}

sub _diff_coords {
	my $cs1 = shift;
	my $cs2 = shift;

    my $num_cs1 = @$cs1;
    my $num_cs2 = @$cs2;

    if ($num_cs1 != $num_cs2) {
        carp "ERROR: cant compare tables with different geometries";
        return;
    }

    my @diffs;
	for (my $i = 0; $i < $num_cs1; $i++) {
        if ($cs1->[$i] != $cs2->[$i]) {
            push @diffs, $i;
        }
	}

	return @diffs;
}

# }}}

# {{{ as_plot

=head2 $tbl->as_plot('plot type', [type specific args ...] );

  Returns TRUE on success, FALSE on error.

Convert the table to a representation suitable for plotting.
The string may need to be output to a file depending on how the
plotting program is called.

See below for the various plot types.

=head3 R  [www.r-project.org]

  Returns: string on success, FALSE on error

The string can be output to a file and then the file can
be sourced to produce a plot.
It depends upon the rgl library [http://cran.r-project.org/web/packages/rgl/index.html].

 $tbl->as_plot('R');

 user$ a.out > file.R
 user$ R

 > source('file.R')

 (plot displayed)

=head3 WANTED: more plot types: gnuplot, etc


=cut

sub as_plot {
	my $self = shift;
	my $type = shift;

	my $str = '';

	if ($type eq 'R') {
		my (@x, @y, @z);

		$str .= "\n";
		$str .= "#\n";
		$str .= "# This was generated by Text::LookUpTable->as_plot() function.\n";
		$str .= "#\n";
		$str .= "# start up R and then load this file by typing:\n";
		$str .= "# source(<this file name>)\n";
		$str .= "#\n";
		$str .= "\n";
		$str .= "library(rgl);\n";
		$str .= "\n";

		my @xc = $self->get_x_coords();
		my @yc = $self->get_y_coords();
		my $num_x = @xc;
		my $num_y = @yc;


		for (my $i = 0; $i < @xc; $i++) {
			for (my $j = 0; $j < @yc; $j++) {
				my $val = $self->get($i, $j);
				push @x, $xc[$i];
				push @y, $yc[$i];
				push @z, $val;
			}
		}

		# R expects the x, y axis data to be increasing
		# Currently the y axis is the opposite
		# The data can be reversed just to get the plot to work
		# but this disrupts the data.
		@yc = reverse @yc;

		$str .= "\n";
		$str .= "x <- c(" . (join ", ", @xc) . ");\n";
		$str .= "y <- c(" . (join ", ", @yc) . ");\n";
		$str .= "z <- c(" . (join ", ", @z) . ");\n";
		$str .= "dim(z) <- c(" . $num_x . ", " . $num_y . ")\n";
		$str .= "\n";
		$str .= "open3d()\n";
		$str .= "bg3d(\"white\")\n";
		$str .= "material3d(\"black\")\n";
		$str .= "\n";
		$str .= "persp3d(x, y, z, col=\"lightblue\", xlab=\"rpm\", ylab=\"map\", zlab=\"ign\")\n";
	}

	return $str;
}

# }}}

=head1 PREREQUISITES

 Module                Version
 ------                -------
 Text::Aligner         0.03
 File::Slurp           9999.13
  
 The version numbers given have been tested and shown to work
 but other versions may work as well.

=head1 VERSION

This document refers to Text::LookUpTable version 0.05.

=head1 REFERENCES

  [1]  MegaSquirt Engine Management System
       http://www.msextra.com/

  [2]  R Project
       http://www.r-project.org/

  [3]  rgl: 3D visualization device system (OpenGL)
       http://cran.r-project.org/web/packages/rgl/index.html

  [4]  Gnuplot
       http://www.gnuplot.info/

=head1 AUTHOR

    Jeremiah Mahler <jmmahler@gmail.com>
    CPAN ID: JERI
    http://www.google.com/profiles/jmmahler#about

=head1 COPYRIGHT

Copyright (c) 2010, Jeremiah Mahler. All Rights Reserved.
This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut

# vim:foldmethod=marker

1;
