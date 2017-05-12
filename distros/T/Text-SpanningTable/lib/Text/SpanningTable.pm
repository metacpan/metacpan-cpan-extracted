package Text::SpanningTable;

our $VERSION = "1.000000";
$VERSION = eval $VERSION;

use warnings;
use strict;

# ABSTRACT: ASCII tables with support for column spanning.

# this hash-ref holds the characters used to print the table decorations.
our $C = {
	top => {		# the top border, i.e. hr('top')
		left	=> '.-',
		border	=> '-',
		sep		=> '-+-',
		right	=> '-.',
	},
	middle => {		# simple horizontal rule, i.e. hr('middle') or hr()
		left	=> '+-',
		border	=> '-',
		sep		=> '-+-',
		right	=> '-+',
	},
	dhr => {		# double horizontal rule, i.e. hr('dhr') or dhr()
		left	=> '+=',
		border	=> '=',
		sep		=> '=+=',
		right	=> '=+',
	},
	bottom => {		# bottom border, i.e. hr('bottom')
		left	=> "'-",
		border	=> '-',
		sep		=> '-+-',
		right	=> "-'",
	},
	row => {		# row decoration
		left	=> '| ',
		sep		=> ' | ',
		right	=> ' |',
	},
};

=head1 NAME

Text::SpanningTable - ASCII tables with support for column spanning.

=head1 SYNOPSIS

	use Text::SpanningTable;

	# create a table object with four columns of varying widths
	my $t = Text::SpanningTable->new(10, 20, 15, 25);

	# enable automatic trailing newlines
	$t->newlines(1);

	# print a top border
	print $t->hr('top');

	# print a row (with header information)
	print $t->row('Column 1', 'Column 2', 'Column 3', 'Column 4');

	# print a double horizontal rule
	print $t->dhr; # also $t->hr('dhr');

	# print a row of data
	print $t->row('one', 'two', 'three', 'four');

	# print a horizontal rule
	print $t->hr;

	# print another row, with one column that spans all four columns
	print $t->row([4, 'Creedence Clearwater Revival']);

	# print a horizontal rule
	print $t->hr;

	# print a row with the first column as normal and another column
	# spanning the remaining three
	print $t->row(
		'normal',
		[3, 'this column spans three columns and also wraps to the next line.']
	);

	# finally, print the bottom border
	print $t->hr('bottom');

	# the output from all these commands is:
	.----------+------------------+-------------+-----------------------.
	| Column 1 | Column 2         | Column 3    | Column 4              |
	+==========+==================+=============+=======================+
	| one      | two              | three       | four                  |
	+----------+------------------+-------------+-----------------------+
	| Creedence Clearwater Revival                                      |
	+----------+------------------+-------------+-----------------------+
	| normal   | this column spans three columns and also wraps to the  |
	|          | next line.                                             |
	'----------+------------------+-------------+-----------------------'

=head1 DESCRIPTION

C<Text::SpanningTable> provides a mechanism for creating simple ASCII tables,
with support for column spanning. It is meant to be used with monospace
fonts such as common in terminals, and thus is useful for logging purposes.

This module is inspired by L<Text::SimpleTable> and can generally produce
the same output (except that C<Text::SimpleTable> doesn't support column
spanning), but with a few key differences:

=over

=item * In C<Text::SimpleTable>, you build your table in the object and
C<draw()> it when you're done. In C<Text::SpanningTable>, you can print
your table (or do whatever you want with the output) as it is being built.
If you don't need to have your tables in "real-time", you can just save the
output in a variable, but for convenience and compatibility with
C<Text::SimpleTable>, this module provides a C<draw()> method (which is
actually an alias for the C<output()> method) that returns the table's
output.

=item * C<Text::SimpleTable> takes care of the top and bottom borders of
the table by itself. Due to C<Text::SpanningTable>'s "real-time" nature,
this functionality is not provided, and you have to take care of that yourself.

=item * C<Text::SimpleTable> allows you to pass titles for a header column
when creating the table object. This module doesn't have that functionality,
you have to create header rows (or footer rows) yourself and how you see
fit.

=item * C<Text::SpanningTable> provides a second type of horizontal rules
(called 'dhr' for 'double horizontal rule') that can be used for header
and footer rows (or whatever you see fit).

=item * C<Text::SpanningTable> provides an option to define a callback
function that can be automatically invoked on the module's output when
calling C<row()>, C<hr()> or C<dhr()>.

=item * In C<Text::SimpleTable>, the widths you define for the columns
are the widths of the data they can accommodate, i.e. without the borders
and padding. In C<Text::SpanningTable>, the widths you define are WITH
the borders and padding. If you are familiar with the CSS and the box model,
then columns in C<Text::SimpleTable> have C<box-sizing> set to C<content-box>,
while in C<Text::SpanningTable> they have C<box-sizing> set to C<border-box>.
So take into account that the width of the column's data will be four
characters less than defined.

=back

Like C<Text::SimpleTable>, the columns of the table will always be exactly
the same width as defined, i.e. they will not stretch to accommodate the
data passed to the cells. If a cell's data is too big, it will be wrapped
(with possible word-breaking using the '-' character), thus resulting in
more lines of text.

=head1 METHODS

=head2 new( [@column_widths] )

Creates a new instance of C<Text::SpanningTable> with columns of the
provided widths. If you don't provide any column widths, the table will
have one column with a width of 100 characters.

Note that currently, a column cannot be less than 6 characters in width.

=cut

sub new {
	my ($class, @cols) = @_;

	my $width; # total width of the table

	# default widths
	@cols = (100) unless @cols and scalar @cols;

	foreach (@cols) {
        die "Minimum column size is 6 characters"
            if $_ < 6;
		$width += $_;
	}

	return bless {
		cols => \@cols,
		width => $width,
		newlines => 0,
		decorate => 1,
		output => [],
	}, $class;
}

=head2 newlines( [$boolean] )

By default, trailing newlines will NOT be added automatically to the output generated
by this module (for example, when printing a horizontal rule, a newline
character will not be appended). Pass a boolean value to this method to
enable/disable automatic newline creation. Returns the current value of
this attribute (after changing it if a boolean value had been passed).

=cut

sub newlines {
	$_[0]->{newlines} = $_[1]
		if defined $_[1];

	return $_[0]->{newlines};
}

=head2 decoration( [$boolean] )

By default, the table will be printed with border decoration. If you want a table
with no decoration at all, pass this a false value. Returns the current value of this
attribute (after changing it if a boolean value had been passed).

Note that in undecorated tables, the C<hr()> method will behave differently, as
documented under L</"hr( ['top'E<verbar>'middle'E<verbar>'bottom'E<verbar>'dhr'] )">.

=cut

sub decoration {
	$_[0]->{decorate} = $_[1]
		if defined $_[1];

	$_[0]->{decorate};
}

=head2 exec( \&sub, [@args] )

Define a callback function to be invoked whenever calling C<row()>, C<hr()>
or C<dhr()>. Pass this method an anonymous subroutine (C<\&sub> above)
or a reference to a subroutine, and a list of parameters/arguments you
wish this subroutine to have (C<@args> above). When called, the subroutine
will receive, as arguments, the generated output, and C<@args>.

So, for example, you can do:

	$t->exec(sub { my ($output, $log) = @_; $log->info($output); }, $log);

This would result in C<< $log->info($output) >> being invoken whenever
calling C<row()>, C<hr()> or C<dhr()>, with C<$output> being the output
these methods generated. See more info at the C<row()>'s method documentation
below.

=cut

sub exec {
	my $self = shift;

	$self->{exec} = shift;
	$self->{args} = \@_ if scalar @_;
}

=head2 hr( ['top'|'middle'|'bottom'|'dhr'] )

Generates a horizontal rule of a certain type. Unless a specific type is
provided, 'middle' we be used. 'top' generates a top border for the table,
'bottom' generates a bottom border, and 'dhr' is the same as 'middle', but
generates a 'double horizontal rule' that is more pronounced and thus can
be used for headers and footers.

This method will always result in one line of text.

If table decoration is off (see L</"decoration( [$boolean] )">), this method
will return an empty string, unless 'dhr' is passed, in which case a horizontal
rule made out of dashes will be returned.

=cut

sub hr {
	my ($self, $type) = @_;

	# generate a simple horizontal rule by default
	$type ||= 'middle';

	my $output = '';

	if ($self->{decorate}) {
		# start with the left decoration
		$output .= $C->{$type}->{left};

		# print a border for every column in the table, with separator
		# decorations between them
		for (my $i = 0; $i < scalar @{$self->{cols}}; $i++) {
			my $width = $self->{cols}->[$i] - 4;
			$output .= $C->{$type}->{border} x$width;

			# print a separator unless this is the last column
			$output .= $C->{$type}->{sep} unless $i == (scalar @{$self->{cols}} - 1);
		}

		# right decoration
		$output .= $C->{$type}->{right};
	} elsif ($type eq 'dhr') {
		$output .= '-'x$self->{width};
	} else {
        return $output;
    }

	# push this to the output buffer
	push(@{$self->{output}}, $output);

	# are we adding newlines?
	$output .= "\n" if $self->newlines;

	# if a callback function is defined, invoke it
	if ($self->{exec}) {
		my @args = ($output);
		unshift(@args, @{$self->{args}}) if $self->{args};
		$self->{exec}->(@args);
	}

	return $output;
}

=head2 dhr()

Convenience method that simply calls C<hr('dhr')>.

=cut

sub dhr {
	shift->hr('dhr');
}

=head2 row( @column_data )

Generates a new row from an array holding the data for the row's columns.
At a maximum, the number of items in the C<@column_data> array will be
the number of columns defined when creating the object. At a minimum, it
will have one item. If the passed data doesn't fill the entire row, the
rest of the columns will be printed blank (so it is not structurally
incorrect to pass insufficient data).

When a column doesn't span, simply push a scalar to the array. When it
does span, push an array-ref with two items, the first being the number
of columns to span, the second being the scalar data to print. Passing an
array-ref with 1 for the first item is the same as just passing the scalar
data (as the column will simply span itself).

So, for example, if the table has nine columns, the following is a valid
value for C<@column_data>:

	( 'one', [2, 'two and three'], 'four', [5, 'five through nine'] )

The following is also valid:

	( 'one', [5, 'two through six'] )

Columns seven through nine in the above example will be blank, so it's the
same as passing:

	( 'one', [5, 'two through six'], ' ', ' ', ' ' )

If a column's data is longer than its width, the data will be wrapped
and broken, which will result in the row being constructed from more than one
lines of text. Thus, as opposed to the C<hr()> method, this method has
two options for a return value: in list context, it will return all the
lines constructing the row (with or without newlines at the end of each
string as per what was defined with the C<newlines() method>); in scalar
context, however, it will return the row as a string containing newline
characters that separate the lines of text (once again, a trailing newline
will be added to this string only if a true value was passed to C<newlines()>).

If a callback function has been defined, it will not be invoked with the
complete output of this row (i.e. with all the lines of text that has
resulted), but instead will be called once per each line of text. This is
what makes the callback function so useful, as it helps you cope with
problems resulting from all the newline characters separating these lines.
When the callback function is called on each line of text, the line will
only contain the newline character at its end if C<newlines()> has been
set to true.

=cut

sub row {
	my ($self, @data) = @_;

	my @rows; # will hold a matrix of the table

	my $done = 0; # how many columns have we generated yet?

	# go over all columns provided
	for (my $i = 0; $i < scalar @data; $i++) {
		# is this a spanning column? what is the width of it?
		my $width = 0;

		my $text = ''; # will hold column's text

		if (ref $data[$i] eq 'ARRAY') {
			# this is a spanning column
			$text .= $data[$i]->[1] if defined $data[$i]->[1];

			foreach (0 .. $data[$i]->[0] - 1) {
				# $data[$i]->[0] is the number of columns this column spans
				$width += $self->{cols}->[$done + $_];
			}

			# subtract the number of columns this column spans
			# minus 1, because two adjacent columns share the
			# same separating border
			$width -= $data[$i]->[0] - 1
                if $self->{decorate};

			# increase $done with the number of columns we have
			# just parsed
			$done += $data[$i]->[0];
		} else {
			# no spanning
			$text .= $data[$i] if defined $data[$i];
			$width = $self->{cols}->[$done];
			$done++;
		}

        if ($self->{decorate}) {
            # make sure the column's data is at least 4 characters long
            # (because we're subtracting four from every column to make
            #  room for the borders and separators)
            $text .= ' 'x(4 - length($text))
                if length($text) < 4;

            # subtract four from the width, for the column's decorations
            $width -= 4;
        } else {
            $text = ' '
                if length($text) == 0;
            $width -= 1;
        }

		# if the column's text is longer than the available width,
		# we need to wrap it.
		my $new_string = ''; # will hold parsed text
		if (length($text) > $width) {
			while (length($text) && length($text) > $width) {
				# if the $width'th character of the string
				# is a whitespace, just break it with a
				# new line.

				# else if the $width'th - 1 character of the string
				# is a whitespace, this is probably the start
				# of a word, so add a whitespace and a newline.

				# else if the $width'th + 1 character is a whitespace,
				# it is probably the end of a word, so just
				# break it with a newline.

				# else we're in the middle of a word, so
				# we need to break it with '-'.


				if (substr($text, $width - 1, 1) =~ m/^\s$/) {
					$new_string .= substr($text, 0, $width, '') . "\n";
				} elsif (substr($text, $width - 2, 1) =~ m/^\s$/) {
					$new_string .= substr($text, 0, $width - 1, '') . " \n";
				} elsif (substr($text, $width, 1) =~ m/^\s$/) {
					$new_string .= substr($text, 0, $width, '') . "\n";
				} else {
					$new_string .= substr($text, 0, $width - 1, '') . "-\n";
				}
			}
			$new_string .= $text if length($text);
		} else {
			$new_string = $text;
		}

		# if this row's data was split into more than one lines,
		# we need to store these lines appropriately in our table's
		# matrix (@rows).
		my @fake_rows = split(/\n/, $new_string);
		for (my $j = 0; $j < scalar @fake_rows; $j++) {
			$rows[$j]->[$i] = ref $data[$i] eq 'ARRAY' ? [$data[$i]->[0], $fake_rows[$j]] : $fake_rows[$j];
		}
	}

	# suppose one column's data was wrapped into more than one lines
	# of text. this means the matrix won't have data for all these
	# lines in other columns that did not wrap (or wrapped less), so
	# let's go over the matrix and fill missing cells with whitespace.
	for (my $i = 1; $i < scalar @rows; $i++) {
		for (my $j = 0; $j < scalar @{$self->{cols}}; $j++) {
			next if $rows[$i]->[$j];

			if (ref $rows[$i - 1]->[$j] eq 'ARRAY') {
				my $width = length($rows[$i - 1]->[$j]->[1]);
				$rows[$i]->[$j] = [$rows[$i - 1]->[$j]->[0], ' 'x$width];
			}
		}
	}

	# okay, now we go over the matrix and actually generate the
	# decorated output
	my @output;
	for (my $i = 0; $i < scalar @rows; $i++) {
		my $output = $self->{decorate} ? $C->{row}->{left} : '';

		my $push = 0; # how many columns have we generated already?

		# print the columns
		for (my $j = 0; $j < scalar @{$rows[$i]}; $j++) {
			my $width = 0;
			my $text;

			if (ref $rows[$i]->[$j] eq 'ARRAY') {
				# a spanning column, calculate width and
				# get the text
				$text = $rows[$i]->[$j]->[1];
				foreach (0 .. $rows[$i]->[$j]->[0] - 1) {
					$width += $self->{cols}->[$push + $_];
				}
				$width -= $rows[$i]->[$j]->[0] - 1;
			} else {
				# normal column
				$text = $rows[$i]->[$j];
				$width = $self->{cols}->[$push];
			}

			$width -= $self->{decorate} ? 4 : 1;

			# is there any text for this column? if not just
			# generate whitespace
			$output .= $text && length($text) ? $text . ' 'x($width - length($text)) : ' 'x$width;

			# increase the number of columns we just processed
			$push += ref $rows[$i]->[$j] eq 'ARRAY' ? $rows[$i]->[$j]->[0] : 1;

			# print a separator, unless this is the last column
            if ($push != scalar @{$self->{cols}}) {
    			$output .= $self->{decorate} ? $C->{row}->{sep} : ' ';
            }
		}

		# have we processed all columns? (i.e. has the user provided
		# data for all the columns?) if not, generate empty columns
		my $left = scalar @{$self->{cols}} - $push;

		if ($left) {
			for (my $k = 1; $k <= $left; $k++) {
				my $width = $self->{cols}->[$push++];
                $width -= 4
                    if $self->{decorate};
				$output .= ' 'x$width;
                if ($k != $left) {
    				$output .= $self->{decorate} ? $C->{row}->{sep} : ' ';
                }
			}
		}

		$output .= $C->{row}->{right}
			if $self->{decorate};

		push(@output, $output);
	}

	# save output in the object
	push(@{$self->{output}}, @output);

	# invoke callback function, if any
	if ($self->{exec}) {
		my @args;
		push(@args, @{$self->{args}}) if $self->{args};
		foreach (@output) {
			$_ .= "\n" if $self->newlines && !m/\n$/;
			push(@args, $_);
			$self->{exec}->(@args);
			pop @args;
		}
	}

	# is the user expecting an array?
    foreach (@output) {
        $_ .= "\n" if $self->newlines && !m/\n$/;
    }
    return wantarray ? @output : join("\n", @output);
}

=head2 output()

=head2 draw()

Returns the entire output generated for the table up to the point of calling
this method. It should be stressed that this method does not "finalize"
the table by adding top and bottom borders or anything at all. Decoration
is done "real-time" and if you don't add top and bottom borders yourself
(with C<hr('top')> and C<hr('bottom')>, respectively), this method will
not do that for you. Returned output will or will not contain newlines as
per the value defined with C<newlines()>.

Both the above methods do the same, C<draw()> is provided as an alias for
compatibility with L<Text::SimpleTable>.

=cut

sub output {
	my $self = shift;

	my $output = join("\n", @{$self->{output}});
	$output .= "\n" if $self->newlines;

	return $output;
}

sub draw {
	shift->output;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-spanningtable at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-SpanningTable>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Text::SpanningTable

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-SpanningTable>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-SpanningTable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-SpanningTable>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-SpanningTable/>

=back

=head1 ACKNOWLEDGEMENTS

Sebastian Riedel and Marcus Ramberg, authors of L<Text::SimpleTable>, which
provided the inspiration of this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Ido Perlmuter

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1;
