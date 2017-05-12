package Text::HistogramChart;

## no critic (Subroutines::RequireArgUnpacking)
## no critic (RequirePodAtEnd)
# By using =encoding utf8 this module would require perl 5.10. No need for that!
## no critic (Documentation::RequirePODUseEncodingUTF8 )

use 5.008_001;
use strict;
use warnings;


=head1 NAME

Text::HistogramChart - Make Text Histogram (Upright Bars) Charts

=head1 VERSION

Version 0.005

=cut

#use version 0.77 (); our $VERSION = 0.003; # Require version 0.77 of module "version". Even for Perl v.5.10.0, get latest bug-fixes and API
our $VERSION = 0.005;


=head1 SYNOPSIS

Text::HistogramChart creates graphical charts for terminal displays or any other display device where bitmap graphics is not available!
You can supply the Y axel legend (vertical) values or Text::HistogramChart can calculate them from the input values.

	require Text::HistogramChart;

	my $chart = Text::HistogramChart->new();

	@values = (1, 2, 3, 4, 5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0);
	@legend_values = (4, 3, 2, 1, 0, -1, -2, -3, -4);
	$chart->{'values'} = \@values;
	$chart->{'legend_values'} = \@legend_values;
	$chart->{'screen_height'} = 9;                # (height reserved for the graph.)
	$chart->{'roof_value'} = 0;                   # (active if != 0), # Arbitrarily squeeze or extend the size (height) of bars (not screen)
	$chart->{'floor_value'} = 0;                  # (the "floor" of the chart, default: 0)
	$chart->{'write_floor'} = 1;                  # (make floor visible)
	$chart->{'use_floor'} = 1;                    # (use the floor value)
	$chart->{'write_floor_value'} = 1;            # If value == floor_value, then write value (mostly "0").
	$chart->{'write_legend'} = 1;                 # (Prepend legend to each row.)
	$chart->{'legend_horizontal_width'} = 4;      # width of the space left for legend (left edge of chart)
	$chart->{'horizontal_width'} = 2;             # Horizontal width of one bar. This parameter directly influences the width of the screen (i.e. chart).
	$chart->{'write_value'} = 1;                  # (YES = 1, NO = 0, default: no; write the value on the end of the bar),
	$chart->{'write_always_over_value'} = 0;      # (YES = 1, NO = 0, default: yes; write the value only if it is too high for the graph),
	$chart->{'write_always_under_value'} = 0;     # (YES = 1, NO = 0, default: yes; write the value only if it is too low for the graph),
	$chart->{'bar_char'} = '|';                   # (default: '|')
	$chart->{'floor_char'} = '-';                 # (default '-' )
	$chart->{'over_value_char'} = '+';            # (default: '+')
	$chart->{'under_value_char'} = '_';           # (default: '-' )
	$rval = $chart->chart();
	if($rval >= 1) {
		my @ready_chart = @{$chart->{'screen'}};
		print (join '\n', @ready_chart) . "\n";
	} else {
		print "Error in creating chart: " . $chart->error_string . "\n";
	}

	# Result:
	#	4         4 5 4                             
	#	3       3 | | | 3                           
	#	2     2 | | | | | 2                         
	#	1   1 | | | | | | | 1                       
	#	0   ------------------0 ------------------0 
	#	-1                      -1| | | | | | | -1  
	#	-2                        -2| | | | | -2    
	#	-3                          -3| | | -3      
	#	-4                            -4-5-4        


=head1 DESCRIPTION

Text::HistogramChart creates graphical charts for terminal displays or any other display device where bitmap graphics is not available or desired!
You can supply the Y axel legend (vertical) values or Text::HistogramChart can calculate them from the input values.


=head1 USAGE

The following variables are available to fine tune the chart
(see SYNOPSIS for an example of usage):

=over 4

=item B<screen_height>, B<horizontal_width>, B<legend_horizontal_width>

The 'screen' is the area in which the chart is drawn. The size is defined with three variables.
B<screen_height> is the absolute Y-axis height in character rows.
B<horizontal_width> is the number of characters used for one bar (one value). If you have 10 values and 
B<horizontal_width> is 3, then the length of the screen (the X-axis) is 10 * 3 = 30 characters (without legend).
Use B<legend_horizontal_width> to define the legend width. The default for both is 5 characters.
Screen height defaults to 10 characters.

=item B<write_legend>
Set this to 1 if you want the legend values prepended to the left edge of the chart.

=item B<write_floor_value>, B<write_value>, B<write_always_over_value>, B<write_always_under_value>

Set B<write_value> to 1 if you want the value of each bar written to the top (or bottom if the value is negative).
Set B<write_always_over_value> and B<write_always_under_value> to 1 if you only want want the value written when
the value is greater than the maximum given legend value (or less than the minimum).
Set B<write_floor_value> to 1 if you want the value written when it equals to 'floor', normally when the value is 0.

=item B<bar_char>, B<floor_char>, B<over_value_char>, B<under_value_char>

These variables define the characters used for writing the chart
B<over_value_char> and B<under_value_char> are used when the value is off the scale (too big or too small).
B<floor_char> is the horizontal line usually at 0.
B<bar_char> is the normal 'bar'.

Any of these charaters can be more than one character is size.
If you want "fatter" vertical bars, just set bar_char to '||'.
Remember to set the other values to double digits as well.

=item B<roof_value>, B<bottom_value>, B<floor_value>, B<write_floor>, B<use_floor>

With B<roof_value> and B<bottom_value> you can restrict the chart into a certain 'height'.
E.g. you are measuring the CPU performance of a server. The performance is usually between 70% and 95% of total capacity.
To show the occasional drops to 0%-70% is a waste of (terminal) space. So you set
B<roof_value> to 95 and B<bottom_value> to 70.
This feature not yet implemented.
Set B<write_floor> to 1 if you want a horizontal bar across the screen at 0.


=back 


=head1 DEPENDENCIES

Requires Perl version 5.008.001.

Requires the following modules:

=over 4

=item Hash::Util

=back


=cut

use utf8;
use Hash::Util qw{lock_keys unlock_keys};

# Global creator
BEGIN {
	use Exporter ();
	our (@ISA, @EXPORT_OK, %EXPORT_TAGS);

	@ISA         = qw(Exporter DynaLoader);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],
	@EXPORT_OK   = qw();
}
our @EXPORT_OK;

# Global destructor
END {
}

# CONSTANTS for this module
my $TRUE = 1;
my $FALSE = 0;
my $EMPTY_STR = q{};
my @EMPTY_ARRAY = (); ## no critic (ProhibitUselessInitialization)
my $SPACE = q{ };
my $HALF_ROW = 0.5; ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

# DEFAULTS
my $DEFAULT_SCREEN_HEIGHT = 10; ## no critic (ProhibitMagicNumbers)
my $DEFAULT_ROOF_VALUE = 0;
my $DEFAULT_BOTTOM_VALUE = 0;
my $DEFAULT_FLOOR_VALUE = 0;
my $DEFAULT_WRITE_FLOOR = 0; # FALSE
my $DEFAULT_USE_FLOOR = 0; # FALSE
my $DEFAULT_WRITE_FLOOR_VALUE = 0; # FALSE
my $DEFAULT_WRITE_LEGEND = 0;
my $DEFAULT_LEGEND_HORIZONTAL_WIDTH = 5; ## no critic (ProhibitMagicNumbers)
my $DEFAULT_HORIZONTAL_WIDTH = 5; ## no critic (ProhibitMagicNumbers)
my $DEFAULT_WRITE_VALUE = 0; # FALSE
my $DEFAULT_WRITE_ALWAYS_OVER_VALUE = 0; # FALSE
my $DEFAULT_WRITE_ALWAYS_UNDER_VALUE = 0; # FALSE

my $DEFAULT_BAR_CHAR = q{|};
my $DEFAULT_FLOOR_CHAR = q{-};
my $DEFAULT_OVER_VALUE_CHAR = q{+};
my $DEFAULT_UNDER_VALUE_CHAR = q{-};
my $DEFAULT_LEGEND_VALUES = \@EMPTY_ARRAY;
my $DEFAULT_VALUES = \@EMPTY_ARRAY;
my $DEFAULT_SCREEN = q{};
my $DEFAULT_ERROR_STRING = q{};

# GLOBALS
# No global variables



=head1 EXPORT

Text::HistogramChart is a purely object-oriented module.
No exported functions.


=head1 SUBROUTINES/METHODS

=head2 new

Creator function.

=cut

sub new {
	my $class = shift;
	my $self;
	my @self_keys = (
			'screen_height',               # (height reserved for the chart.)
			'roof_value',                  # (active if != 0), # Arbitrarily squeeze or extend the size (height) of bars (not screen)
			'bottom_value',                # (below floor, active if != 0), # Not yet implemented.
			'floor_value',                 # (the "floor" of the chart, default: 0)
			'write_floor',                 # (make floor visible)
			'use_floor',                   # (use the floor value)
			'write_floor_value',           # If value == floor_value, then write value (mostly "0").
			'write_legend',                # (Prepend legend to each row.)
			'legend_horizontal_width',     # width of the space left for legend (left edge of chart) 
			'horizontal_width',            # Horizontal width of one bar. This parameter directly influences the width of the screen (i.e. chart).
			'write_value',                 # (YES = 1, NO = 0, default: no; write the value on the end of the bar),
			'write_always_over_value',     # (YES = 1, NO = 0, default: yes; write the value only if it is too high for the graph),
			'write_always_under_value',    # (YES = 1, NO = 0, default: yes; write the value only if it is too low for the graph),
			'bar_char',                    # (default: '|')
			'floor_char',                  # (default: '-' )
			'over_value_char',             # (default: '+'; overruled by write_value and write_always_over_value)
			'under_value_char',            # (default: '-'; overruled by write_value and write_always_under_value)
			'legend_values',               # array of legend values (numbers). Pointer to.
			'values',                      # array of values (numbers). Pointer to.
			'screen',                      # The result: array of strings. Pointer to.
			'error_string',                # A meaningful error!
	);
	lock_keys(%{$self}, @self_keys);
	$self->{'screen_height'} = $DEFAULT_SCREEN_HEIGHT;
	$self->{'roof_value'} = $DEFAULT_ROOF_VALUE;
	$self->{'bottom_value'} = $DEFAULT_BOTTOM_VALUE;
	$self->{'floor_value'} = $DEFAULT_FLOOR_VALUE;
	$self->{'write_floor'} = $DEFAULT_WRITE_FLOOR;
	$self->{'use_floor'} = $DEFAULT_USE_FLOOR;
	$self->{'write_floor_value'} = $DEFAULT_WRITE_FLOOR_VALUE;
	$self->{'write_legend'} = $DEFAULT_WRITE_LEGEND;
	$self->{'legend_horizontal_width'} = $DEFAULT_LEGEND_HORIZONTAL_WIDTH;
	$self->{'horizontal_width'} = $DEFAULT_HORIZONTAL_WIDTH;
	$self->{'write_value'} = $DEFAULT_WRITE_VALUE;
	$self->{'write_always_over_value'} = $DEFAULT_WRITE_ALWAYS_OVER_VALUE;
	$self->{'write_always_under_value'} = $DEFAULT_WRITE_ALWAYS_UNDER_VALUE;

	$self->{'bar_char'} = $DEFAULT_BAR_CHAR;
	$self->{'floor_char'} = $DEFAULT_FLOOR_CHAR;
	$self->{'over_value_char'} = $DEFAULT_OVER_VALUE_CHAR;
	$self->{'under_value_char'} = $DEFAULT_UNDER_VALUE_CHAR;
	$self->{'legend_values'} = $DEFAULT_LEGEND_VALUES;
	$self->{'values'} = $DEFAULT_VALUES;
	$self->{'screen'} = $DEFAULT_SCREEN;
	$self->{'error_string'} = $DEFAULT_ERROR_STRING;

	unlock_keys(%{$self});
	my $blessed_ref = bless $self, $class;
	lock_keys(%{$self}, @self_keys);
	return $blessed_ref;
}

=head2 chart

Create the chart. Writes the ready chart into $self->{'screen'}.
The ready chart is an array of strings without linefeed.
Returns >= 1, if successful, else $self->{'error_string'} contains the error.

=cut

sub chart {
	my $return_value = 1;

	my $self = shift;

	my @values = @{$self->{'values'}};
	my @legend_values;
	my $horizontal_width_empty = $EMPTY_STR;
	while(length $horizontal_width_empty < $self->{'horizontal_width'}) {
		$horizontal_width_empty .= $SPACE;
	}

	my @output_rows;
	# If user wants, write only the legend.
	# Always create the legend first so you know which rows have which values!
	# If user gives the legend values (parameter LEGEND_VALUES) 
	# then all the better for you (no need to calculate the legend yourself).
	# But only write the legend if user demands it (parameter WRITE_LEGEND).
	# Even without writing the legend, the legend values define the distance between rows.
	my $sprf_format = q{%-} . $self->{'legend_horizontal_width'} . q{s};
	if(defined $self->{'legend_values'} && scalar @{$self->{'legend_values'}} > 0) {
		@legend_values = @{$self->{'legend_values'}};
		if(scalar(@legend_values) != $self->{'screen_height'}) {
			$self->{'error_string'} = 'Screen height must be equal to the number of legend values!';
			return 0;
		}
		@legend_values = sort {$a <=> $b} @legend_values; # Sort them to be sure
	}
	else {
		my $highest_value = 0;
		if($self->{'roof_value'} != 0) {
			$highest_value = $self->{'roof_value'};
		}
		else {
			foreach my $value (@values) {
				if($value > $highest_value) {
					$highest_value = $value;
				}
			}
		}
		my $lowest_value = 0;
		if($self->{'bottom_value'} != 0) {
			$lowest_value = $self->{'bottom_value'};
		}
		else {
			foreach my $value (@values) {
				if($value < $lowest_value) {
					$lowest_value = $value;
				}
			}
		}
		my $rows_for_one = $self->{'screen_height'} / $highest_value;
		my $amount_per_row = $highest_value / $self->{'screen_height'};
		#my $rows_for_one = $self->{'screen_height'} / ($highest_value - $lowest_value + 1); //TODO
		#my $amount_per_row = ($highest_value - $lowest_value + 1) / $self->{'screen_height'}; //TODO

		# Make a legend based on lowest and highest value in @values
		my $screen_top_row = $self->{'screen_height'} - 1;
		my $screen_bottom_row = 0;
		#my $screen_top_row = $highest_value - $lowest_value; //TODO
		#my $screen_bottom_row = 0; //TODO
		for(my $i_row = $screen_bottom_row; $i_row <= $screen_top_row; $i_row++) {
			push @legend_values, (sprintf $sprf_format, int(($i_row + 1) * $amount_per_row + $HALF_ROW));
			#push @legend_values, (sprintf $sprf_format, int(($i_row + $lowest_value) * $amount_per_row + 0.5)); //TODO
		}
	}
	if($self->{'write_legend'} == 1) {
		for(my $i_row = $self->{'screen_height'} - 1; $i_row >= 0; $i_row--) { ## no critic (ControlStructures::ProhibitCStyleForLoops)
			$output_rows[$i_row] .= sprintf $sprf_format, int $legend_values[$i_row];
		}
	}

	# Now the values
	# We write one pillar at a time: one value = one pillar!
	# So, we write from left to right, one pillar at a time!
	# We write the pillar starting from the bottom.
	my $screen_top_row = $self->{'screen_height'} - 1;
	my $screen_bottom_row = 0;
	my $screen_floor_row = $screen_bottom_row;
	if($self->{'use_floor'} == 1) {
		for(0..@legend_values-1) {
			if($legend_values[$_] == $self->{'floor_value'}) {
				$screen_floor_row = $_;
			}
		}
	}
	foreach my $value (@values) {
		for(my $i_row = $screen_bottom_row; $i_row <= $screen_top_row; $i_row++) {
			if($value != $self->{'floor_value'}) { # If value == 0, just write spaces.
				if($i_row == $screen_bottom_row) { ## no critic (ControlStructures::ProhibitCascadingIfElse)
					if($i_row < $screen_floor_row) {
						if($value > $legend_values[$i_row]) { # Write empty space
							$output_rows[$i_row] .= $horizontal_width_empty;
						}
						elsif($value <= $legend_values[$i_row]) { # Write value
							if(length($value) > $self->{'horizontal_width'}) { # Doesn't fit on the row.
								$output_rows[$i_row] .= center_text(
										$self->{'write_always_under_value'} ? $self->{'under_value_char'} : ($self->{'write_value'} ? $value : $self->{'bar_char'}),
										$self->{'horizontal_width'}, $SPACE, 'right');
							}
							else {
								$output_rows[$i_row] .= center_text(
										$self->{'write_always_under_value'} ? $value : ($self->{'write_value'} ? $value : $self->{'bar_char'}),
										$self->{'horizontal_width'}, $SPACE, 'right');
							}
						}
						else {
						}
					}
					elsif($i_row >= $screen_floor_row) {
						if($value >= $legend_values[$i_row + 1]) { # Write bar char
							$output_rows[$i_row] .= center_text($self->{'bar_char'}, $self->{'horizontal_width'}, $SPACE, 'right');
						}
						elsif($value >= $legend_values[$i_row] && $value < $legend_values[$i_row + 1]) { # Write value
							$output_rows[$i_row] .= center_text($self->{'write_value'} ? $value : $self->{'bar_char'}, $self->{'horizontal_width'}, $SPACE, 'right');
						}
						elsif($value < $legend_values[$i_row] && $value >= $self->{'floor_value'}) { # Write value maybe
							$output_rows[$i_row] .= center_text(
									$self->{'write_always_under_value'} ? $value : '',
									$self->{'horizontal_width'}, $SPACE, 'right');
						}
						elsif($value < $legend_values[$i_row] && $value < $self->{'floor_value'}) { # Write value
							$output_rows[$i_row] .= center_text($self->{'write_value'} ? $value : $self->{'bar_char'}, $self->{'horizontal_width'}, $SPACE, 'right');
						}
						else {
						}
					}
					else {
					}
				}

				# (Possible) middle rows (floor down)
				elsif($i_row < $screen_floor_row && $i_row > $screen_bottom_row) {
					if($value <= $legend_values[$i_row - 1]) { # Write bar char
						$output_rows[$i_row] .= center_text($self->{'bar_char'}, $self->{'horizontal_width'}, $SPACE, 'right');
					}
					elsif($value <= $legend_values[$i_row] && $value > $legend_values[$i_row - 1]) { # Write value
						$output_rows[$i_row] .= center_text($self->{'write_value'} ? $value : $self->{'bar_char'}, $self->{'horizontal_width'}, $SPACE, 'right');
					}
					elsif($value > $legend_values[$i_row]) { # Write white space
						$output_rows[$i_row] .= $horizontal_width_empty;
					}
					else {
					}
				}

				# Floor row
				elsif($i_row == $screen_floor_row) {
					if($self->{'write_floor'} == 1) {
						$output_rows[$i_row] .= center_text('-', $self->{'horizontal_width'}, "-", 'right');
					}
					else {
						if($value > $legend_values[$i_row - 1] && $value < $legend_values[$i_row + 1]) { # Write value
							$output_rows[$i_row] .= center_text($self->{'write_value'} ? $value : $self->{'bar_char'}, $self->{'horizontal_width'}, $SPACE, 'right');
						}
						else { # Write bar char
							$output_rows[$i_row] .= center_text($self->{'bar_char'}, $self->{'horizontal_width'}, $SPACE, 'right');
						}
					}
				}

				# (Possible) middle rows (floor up)
				elsif($i_row > $screen_floor_row && $i_row < $screen_top_row) {
					if($value >= $legend_values[$i_row + 1]) { # Write bar char
						$output_rows[$i_row] .= center_text($self->{'bar_char'}, $self->{'horizontal_width'}, $SPACE, 'right');
					}
					elsif($value >= $legend_values[$i_row] && $value < $legend_values[$i_row + 1]) { # Write value
						$output_rows[$i_row] .= center_text($self->{'write_value'} ? $value : $self->{'bar_char'}, $self->{'horizontal_width'}, $SPACE, 'right');
					}
					elsif($value < $legend_values[$i_row]) { # Write white space
						$output_rows[$i_row] .= $horizontal_width_empty;
					}
					else {
					}
				}

				# Top row, here value is only >= or <!
				elsif($i_row == $screen_top_row) {
					if($value >= $legend_values[$i_row]) { # Write value or bar char
						if(length($value) > $self->{'horizontal_width'}) { # Doesn't fit on the row.
							$output_rows[$i_row] .= center_text(
									$self->{'write_always_over_value'} ? $self->{'over_value_char'} : ($self->{'write_value'} ? $value : $self->{'bar_char'}),
									$self->{'horizontal_width'}, $SPACE, 'right');
						}
						else {
							$output_rows[$i_row] .= center_text(
									$self->{'write_always_over_value'} ? $value : ($self->{'write_value'} ? $value : $self->{'bar_char'}),
									$self->{'horizontal_width'}, $SPACE, 'right');
						}
					}
					elsif($value < $legend_values[$i_row]) { # Write white space
						$output_rows[$i_row] .= $horizontal_width_empty;
					}
					else {
					}
				}
				else {
				}
			}
			else { # $value is same as $self->{'floor_value'}
				if($self->{'floor_value'} == $legend_values[$i_row]) { # This is the floor row, the "0" row.
					if($self->{'write_floor_value'} == 1) {
						$output_rows[$i_row] .= center_text($value, $self->{'horizontal_width'}, $SPACE, 'right');
					}
					elsif($self->{'write_floor'}) {
						$output_rows[$i_row] .= center_text($self->{'floor_char'}, $self->{'horizontal_width'}, $SPACE, 'right');
					}
					else {
						$output_rows[$i_row] .= $horizontal_width_empty;
					}
				}
				else {
					$output_rows[$i_row] .= $horizontal_width_empty;
				}
			}
		}
	}
	# Now we have to flip the order!
	my @reversed_rows;
	foreach my $screen_row (@output_rows) {
		unshift @reversed_rows, $screen_row;
	}
	$self->{'screen'} = \@reversed_rows;

	# Clean up
	return $return_value;
}

=head1 INTERNAL SUBROUTINES

=head2 center_text

Center a string into a string buffer. Return the buffer.
Parameters: text to be centered, field width, fill character (default: " "), start direction (default: left).
If text is longer than field width, it is not truncated!

=cut

sub center_text {
	my $text = $_[0];
	my $field_width = $_[1];
	my $fill_character = ($_[2] ? $_[2] : $SPACE);
	my $start_direction = ($_[3] ? $_[3] : 'left'); ## no critic (ProhibitMagicNumbers)
	my $next_add_direction = $start_direction;
	# MODIFY BUFFER
	while(length($text) < $field_width) {
		if($next_add_direction eq 'left') {
			$text = $fill_character . $text;
			$next_add_direction = 'right'
		}
		else {
			$text = $text . $fill_character;
			$next_add_direction = 'left'
		}
	}

	return $text;
}

=head1 AUTHOR

Mikko Koivunalho, C<< <mikko.koivunalho at iki.fi> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-histogram at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-HistogramChart>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::HistogramChart


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-HistogramChart>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-HistogramChart>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-HistogramChart>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-HistogramChart/>

=back


=head1 ACKNOWLEDGEMENTS

None.


=head1 DIAGNOSTICS

None.


=head1 CONFIGURATION AND ENVIRONMENT

Please see the examples.


=head1 INCOMPATIBILITIES

None known.


=head1 BUGS AND LIMITATIONS

Plenty I'm sure.
Using roof_value and bottom_value together to restrict the bars into a certain scope is not yet implemented.


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mikko Koivunalho.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Text::HistogramChart
