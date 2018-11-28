package Text::Table::Manifold;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use open     qw(:std :utf8); # Undeclared streams in UTF-8.

use Const::Exporter constants =>
[
	# Values of alignment().

	align_left   => 0,
	align_center => 1, # The default.
	align_right  => 2,

	# Values for empty(), i.e. empty string handling.

	empty_as_empty => 0, # Do nothing. The default.
	empty_as_minus => 1,
	empty_as_text  => 2, # 'empty'.
	empty_as_undef => 3,

	# Values for escape().

	escape_nothing => 0, # The default.
	escape_html    => 1,
	escape_uri     => 2,

	# Values for extend().

	extend_with_empty => 0, # The default.
	extend_with_undef => 1,

	# Values for format().

	format_internal_boxed        => 0, # The default.
	format_text_csv              => 1,
	format_internal_github       => 2,
	format_internal_html         => 3,
	format_html_table            => 4,
	format_text_unicodebox_table => 5,

	# Values for include().

	include_data    => 1, # Default.
	include_footers => 2,
	include_headers => 4, # Default.

	# Values for undef(), i.e. undef handling.

	undef_as_empty => 0,
	undef_as_minus => 1,
	undef_as_text  => 2, # 'undef'.
	undef_as_undef => 3, # Do nothing. The default.
];

use HTML::Entities::Interpolate; # This module can't be loaded at runtime.

use List::AllUtils 'max';

use Module::Runtime 'use_module';

use Moo;

use Types::Standard qw/Any ArrayRef HashRef Int Str/;

use Unicode::GCString;

has alignment =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has data =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has empty =>
(
	default  => sub{return empty_as_empty},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has escape =>
(
	default  => sub{return escape_nothing},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has extend_data =>
(
	default  => sub{return extend_with_empty},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has extend_footers =>
(
	default  => sub{return extend_with_empty},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has extend_headers =>
(
	default  => sub{return extend_with_empty},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has format =>
(
	default  => sub{return format_internal_boxed},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has footers =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has headers =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has include =>
(
	default  => sub{return include_data | include_headers},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has join =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has padding =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has pass_thru =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has undef =>
(
	default  => sub{return undef_as_undef},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has widths =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

our $VERSION = '1.01';

# ------------------------------------------------

sub _align_to_center
{
	my($self, $s, $width, $padding) = @_;
	$s           ||= '';
	my($s_width) = Unicode::GCString -> new($s) -> chars;
	my($left)    = int( ($width - $s_width) / 2);
	my($right)   = $width - $s_width - $left;

	return (' ' x ($left + $padding) ) . $s . (' ' x ($right + $padding) );

} # End of _align_to_center;

# ------------------------------------------------

sub _align_to_left
{
	my($self, $s, $width, $padding) = @_;
	$s           ||= '';
	my($s_width) = Unicode::GCString -> new($s || '') -> chars;
	my($right)   = $width - $s_width;

	return (' ' x $padding) . $s . (' ' x ($right + $padding) );

} # End of _align_to_left;

# ------------------------------------------------

sub _align_to_right
{
	my($self, $s, $width, $padding) = @_;
	$s           ||= '';
	my($s_width) = Unicode::GCString -> new($s || '') -> chars;
	my($left)    = $width - $s_width;

	return (' ' x ($left + $padding) ) . $s . (' ' x $padding);

} # End of _align_to_right;

# ------------------------------------------------
# Apply empty_as_* and undef_as_* options, as well as escaping option(s).

sub _clean_data
{
	my($self, $alignment, $headers, $data, $footers) = @_;
	my($empty)  = $self -> empty;
	my($escape) = $self -> escape;
	my($undef)  = $self -> undef;

	use_module('URI::Escape') if ($escape == escape_uri);

	my($s);

	for my $row (0 .. $#$data)
	{
		for my $column (0 .. $#{$$data[$row]})
		{
			$s = $$data[$row][$column];
			$s = defined($s)
					? (length($s) == 0) # Unicode::GCString should not be necessary here.
						? ($empty == empty_as_minus)
							? '-'
							: ($empty == empty_as_text)
								? 'empty'
								: ($empty == empty_as_undef)
									? undef
									: $s # No need to check to empty_as_empty here!
						: $s
					: ($undef == undef_as_empty)
							? ''
							: ($undef == undef_as_minus)
								? '-'
								: ($undef == undef_as_text)
									? 'undef'
									: $s; # No need to check for undef_as_undef here!

			$s                    = $Entitize{$s}  if (defined($s) && ($escape == escape_html) );
			$s                    = URI::Escape::uri_escape($s) if ($escape == escape_uri); # Undef harmless here.
			$$data[$row][$column] = $s;
		}
	}

} # End of _clean_data.

# ------------------------------------------------

sub format_as_html_table
{
	my($self, $alignment, $headers, $data, $footers) = @_;

	my($html) = use_module('HTML::Table') -> new(%{${$self -> pass_thru}{new} }, -data => $data);

	return [$html -> getTable];

} # End of format_as_html_table.

# ------------------------------------------------

sub format_as_internal_boxed
{
	my($self, $alignment, $headers, $data, $footers) = @_;
	my($padding)   = $self -> padding;
	my($widths)    = $self -> widths;
	my($separator) = '+' . join('+', map{'-' x ($_ + 2 * $padding)} @$widths) . '+';
	my(@output)    = $separator;

	my($align);
	my(@s);

	for my $column (0 .. $#$widths)
	{
		$align = $$alignment[$column];

		if ($align == align_left)
		{
			push @s, $self -> _align_to_left($$headers[$column], $$widths[$column], $padding);
		}
		elsif ($align == align_center)
		{
			push @s, $self -> _align_to_center($$headers[$column], $$widths[$column], $padding);
		}
		else
		{
			push @s, $self -> _align_to_right($$headers[$column], $$widths[$column], $padding);
		}
	}

	push @output, '|' . join('|', @s) . '|';
	push @output, $separator;

	for my $row (0 .. $#$data)
	{
		@s = ();

		for my $column (0 .. $#$widths)
		{
			$align = $$alignment[$column];

			if ($align == align_left)
			{
				push @s, $self -> _align_to_left($$data[$row][$column], $$widths[$column], $padding);
			}
			elsif ($align == align_center)
			{
				push @s, $self -> _align_to_center($$data[$row][$column], $$widths[$column], $padding);
			}
			else
			{
				push @s, $self -> _align_to_right($$data[$row][$column], $$widths[$column], $padding);
			}
		}

		push @output, '|' . join('|', @s) . '|';
	}

	push @output, $separator;

	return [@output];

} # End of format_as_internal_boxed.

# ------------------------------------------------

sub format_as_internal_github
{
	my($self, $alignment, $headers, $data, $footers) = @_;
	my(@output) = join('|', @$headers);
	my($widths) = $self -> widths;

	my($align);
	my(@line);

	for my $column (0 .. $#$widths)
	{
		$align = $$alignment[$column];

		if ($align == align_left)
		{
			push @line, ':' . ('-' x $$widths[$column - 1]);
		}
		elsif ($align == align_center)
		{
			push @line, ':' . ('-' x $$widths[$column - 2]) . ':';
		}
		else
		{
			push @line, ('-' x $$widths[$column - 1]) . ':';
		}
	}

	push @output, join('|', @line);

	for my $row (0 .. $#$data)
	{
		push @output, join('|', map{defined($_) ? $_ : ''} @{$$data[$row]});
	}

	return [@output];

} # End of format_as_internal_github.

# ------------------------------------------------

sub format_as_internal_html
{
	my($self, $alignment, $headers, $data, $footers) = @_;
	my($table)         = '';
	my($table_options) = ${$self -> pass_thru}{new}{table} || {};
	my(@table_keys)    = sort keys %$table_options;
	my($include)       = $self -> include;
	my(%align)         =
	(
		0   => "<div style='text-align: left'>",
		1 => "<div style='text-align: center'>",
		2  => "<div style='text-align: right'>",
	);

	if (scalar @table_keys)
	{
		$table .= ' ' . join(' ', map{qq|$_ = "$$table_options{$_}"|} sort keys %$table_options);
	}

	my(@output) = "<table$table>";

	my(@line);
	my($value);

	if ( ($include & include_headers) && ($#$headers >= 0) )
	{
		push @output, '<thead>';

		for my $column (0 .. $#$headers)
		{
			push @line, "<th>$align{$$alignment[$column]}$$headers[$column]</div></th>";
		}

		push @output, '<tr>' . join('', @line) . '</tr>';
		push @output, '</thead>';
	}

	if ($include & include_data)
	{
		for my $row (0 .. $#$data)
		{
			@line = ();

			# Every row will have the same # of columns, so we pick 1.

			for my $column (0 .. $#{$$data[0]})
			{
				$value = $$data[$row][$column];
				$value = defined($value) ? $value : '';

				push @line, "<td>$align{$$alignment[$column]}$value</div></td>";
			}

			push @output, '<tr>' . join('',  @line) . '</tr>';
		}
	}

	if ( ($include & include_footers) && ($#$footers >= 0) )
	{
		push @output, '<tfoot>';

		@line = ();

		for my $column (0 .. $#$footers)
		{
			push @line, "<th>$align{$$alignment[$column]}$$footers[$column]</div></th>";
		}

		push @output, '<tr>' . join('', @line) . '</tr>';
		push @output, '<tfoot>';
	}

	push @output, '</table>';

	return [@output];

} # End of format_as_internal_html.

# ------------------------------------------------

sub format_as_text_csv
{
	my($self, $alignment, $headers, $data, $footers) = @_;

	my($csv)    = use_module('Text::CSV') -> new(${$self -> pass_thru}{new} || {});
	my($status) = $csv -> combine(@$headers);

	my(@output);

	if ($status)
	{
		push @output, $csv -> string;

		for my $row (0 .. $#$data)
		{
			$status = $csv -> combine(@{$$data[$row]});

			if ($status)
			{
				push @output, $csv -> string
			}
			else
			{
				die "Can't combine data:\nLine: " . $csv -> error_input . "\nMessage: " . $csv -> error_diag . "\n";
			}
		}
	}
	else
	{
		die "Can't combine headers:\nHeader: " . $csv -> error_input . "\nMessage: " . $csv -> error_diag . "\n";
	}

	return [@output];

} # End of format_as_text_csv.

# ------------------------------------------------

sub format_as_text_unicodebox_table
{
	my($self, $alignment, $headers, $data, $footers) = @_;
	my($include) = $self -> include;
	my($table)   = use_module('Text::UnicodeBox::Table') -> new(%{${$self -> pass_thru}{new} });

	if ( ($include & include_headers) && ($#$headers >= 0) )
	{
		# Note: Text::UnicodeBox::Table does not support central alignment.

		my(@align) = map{ ($_ == align_left) ? 'left' : 'right'} @{$self -> alignment};

		$table -> add_header({alignment => [@align]}, @$headers);
	}

	if ($include & include_data)
	{
		for my $row (0 .. $#$data)
		{
			$table -> add_row(@{$$data[$row]});
		}
	}

	return [$table -> render];

} # End of format_as_text_unicodebox_table.

# ------------------------------------------------
# Find the maimum width of header/data/footer each column.

sub _gather_statistics
{
	my($self, $alignment, $headers, $data, $footers) = @_;

	$self -> _rectify_data($alignment, $headers, $data, $footers);
	$self -> _clean_data($alignment, $headers, $data, $footers);

	my(@column);
	my($header_width);
	my(@max_widths);

	for my $column (0 .. $#$headers)
	{
		@column = ($$headers[$column], $$footers[$column]);

		for my $row (0 .. $#$data)
		{
			push @column, $$data[$row][$column];
		}

		push @max_widths, max map{Unicode::GCString -> new($_ || '') -> chars} @column;
	}

	$self -> widths(\@max_widths);

} # End of _gather_statistics.

# ------------------------------------------------
# Ensure all header/data/footer rows are the same length.

sub _rectify_data
{
	my($self, $alignment, $headers, $data, $footers) = @_;

	# Note: include is not validated, since it's a set of bit fields.

	$self -> _validate($self -> empty,          empty_as_empty,        empty_as_undef,               'empty');
	$self -> _validate($self -> escape,         escape_nothing,        escape_uri,                   'escape');
	$self -> _validate($self -> extend_data,    extend_with_empty,     extend_with_undef,            'extend_data');
	$self -> _validate($self -> extend_footers, extend_with_empty,     extend_with_undef,            'extend_headers');
	$self -> _validate($self -> extend_footers, extend_with_empty,     extend_with_undef,            'extend_footers');
	$self -> _validate($self -> format,         format_internal_boxed, format_text_unicodebox_table, 'format');
	$self -> _validate($self -> undef,          undef_as_empty,        undef_as_undef,               'undef');

	for my $alignment (@{$self -> alignment})
	{
		$self -> _validate($alignment, align_left, align_right, 'align');
	}

	# Find the longest header/data/footer row. Ignore aligment.

	my($max_length) = 0;

	for my $row (0 .. $#$data)
	{
		$max_length = $#{$$data[$row]} if ($#{$$data[$row]} > $max_length);
	}

	$max_length = max $#$headers, $#$footers, $max_length;

	# Shrink the alignment row if necessary.

	$#$alignment = $max_length if ($#$alignment > $max_length);

	# Now expand all rows to be the same, maximum, length.

	my($filler)     = align_center;
	$$alignment[$_] = $filler for ($#$alignment + 1 .. $max_length);
	$filler         = ($self -> extend_headers == extend_with_empty) ? '' : undef;
	$$headers[$_]   = $filler for ($#$headers + 1 .. $max_length);
	$filler         = ($self -> extend_footers == extend_with_empty) ? '' : undef;
	$$footers[$_]   = $filler for ($#$footers + 1 .. $max_length);
	$filler         = ($self -> extend_data == extend_with_empty) ? '' : undef;

	for my $row (0 .. $#$data)
	{
		$$data[$row][$_] = $filler for ($#{$$data[$row]} + 1 .. $max_length);
	}

} # End of _rectify_data.

# ------------------------------------------------

sub render
{
	my($self, %hash) = @_;

	# Process parameters passed to render(), which can be the same as to new().

	for my $key (keys %hash)
	{
		$self -> $key($hash{$key});
	}

	my($alignment) = $self -> alignment;
	my($headers)   = $self -> headers;
	my($data)      = $self -> data;
	my($footers)   = $self -> footers;
	my($format)    = $self -> format;

	$self -> _gather_statistics($alignment, $headers, $data, $footers);

	my($output);

	if ($format == format_internal_boxed)
	{
		$output = $self -> format_as_internal_boxed($alignment, $headers, $data, $footers);
	}
	elsif ($format == format_internal_github)
	{
		$output = $self -> format_as_internal_github($alignment, $headers, $data, $footers);
	}
	elsif ($format == format_internal_html)
	{
		$output = $self -> format_as_internal_html($alignment, $headers, $data, $footers);
	}
	elsif ($format == format_html_table)
	{
		$output = $self -> format_as_html_table($alignment, $headers, $data, $footers);
	}
	elsif ($format == format_text_csv)
	{
		$output = $self -> format_as_text_csv($alignment, $headers, $data, $footers);
	}
	elsif ($format == format_text_unicodebox_table)
	{
		$output = $self -> format_as_text_unicodebox_table($alignment, $headers, $data, $footers);
	}
	else
	{
		die 'Error: format not implemented: ' . $format . "\n";
	}

	return $output;

} # End of render.

# ------------------------------------------------

sub render_as_string
{
	my($self, %hash) = @_;
	my($join) = defined($hash{join}) ? $hash{join} : $self -> join;

	return join($join, @{$self -> render(%hash)});

} # End of render_as_string.

# ------------------------------------------------

sub _validate
{
	my($self, $value, $min, $max, $name) = @_;

	if ( ($value < $min) || ($value > $max) )
	{
		die "Error. The value for '$name', $value, is out of the range ($min .. $max)\n";
	}

} # End of _validate.

# ------------------------------------------------

1;

=pod

=encoding utf8

=head1 NAME

C<Text::Table::Manifold> - Render tables in manifold formats

=head1 Synopsis

This is scripts/synopsis.pl:

	#!/usr/bin/env perl

	use strict;
	use utf8;
	use warnings;
	use warnings qw(FATAL utf8); # Fatalize encoding glitches.
	use open     qw(:std :utf8); # Undeclared streams in UTF-8.

	use Text::Table::Manifold ':constants';

	# -----------

	# Set parameters with new().

	my($table) = Text::Table::Manifold -> new
	(
		alignment =>
		[
			align_left,
			align_center,
			align_right,
			align_center,
		]
	);

	$table -> headers(['Homepage', 'Country', 'Name', 'Metadata']);
	$table -> data(
	[
		['http://savage.net.au/',   'Australia', 'Ron Savage',    undef],
		['https://duckduckgo.com/', 'Earth',     'Mr. S. Engine', ''],
	]);

	# Note: Save the data, since render() may update it.

	my(@data) = @{$table -> data};

	# Set parameters with methods.

	$table -> empty(empty_as_text);
	$table -> format(format_internal_boxed);
	$table -> undef(undef_as_text);

	# Set parameters with render().

	print "Format: format_internal_boxed: \n";
	print join("\n", @{$table -> render(padding => 1)}), "\n";
	print "\n";

	$table -> headers(['One', 'Two', 'Three']);
	$table -> data(
	[
		['Reichwaldstraße', 'Böhme', 'ʎ ʏ ʐ ʑ ʒ ʓ ʙ ʚ'],
		['ΔΔΔΔΔΔΔΔΔΔ', 'Πηληϊάδεω Ἀχιλῆος', 'A snowman: ☃'],
		['Two ticks: ✔✔', undef, '<table><tr><td>TBA</td></tr></table>'],
	]);

	# Save the data, since render() may update it.

	@data = @{$table -> data};

	$table -> empty(empty_as_minus);
	$table -> format(format_internal_boxed);
	$table -> undef(undef_as_text);
	$table -> padding(2);

	print "Format: format_internal_boxed: \n";
	print join("\n", @{$table -> render}), "\n";
	print "\n";

	# Restore the saved data.

	$table -> data([@data]);

	# Etc.

This is data/synopsis.log, the output of synopsis.pl:

	Format: format_internal_boxed:
	+-------------------------+-----------+---------------+----------+
	| Homepage                |  Country  |          Name | Metadata |
	+-------------------------+-----------+---------------+----------+
	| http://savage.net.au/   | Australia |    Ron Savage |  undef   |
	| https://duckduckgo.com/ |   Earth   | Mr. S. Engine |  empty   |
	+-------------------------+-----------+---------------+----------+

	Format: format_internal_boxed:
	+-------------------+---------------------+----------------------------------------+
	|  One              |         Two         |                                 Three  |
	+-------------------+---------------------+----------------------------------------+
	|  Reichwaldstraße  |        Böhme        |                       ʎ ʏ ʐ ʑ ʒ ʓ ʙ ʚ  |
	|  ΔΔΔΔΔΔΔΔΔΔ       |  Πηληϊάδεω Ἀχιλῆος  |                          A snowman: ☃  |
	|  Two ticks: ✔✔    |        undef        |  <table><tr><td>TBA</td></tr></table>  |
	+-------------------+---------------------+----------------------------------------+

The latter table renders perfectly in FF, but not so in Chrome (today, 2015-01-31).

=head1 Description

Outputs tables in any one of several supported types.

Features:

=over 4

=item o Generic interface to all supported table formats

=item o Separately specify header/data/footer rows

=item o Separately include/exclude header/data/footer rows

=item o Align cell values

Each column has its own alignment option, left, center or right.

For internally generated HTML, this is done with a CSS C<div> within each C<td>, not with the obsolete
C<td align> attribute.

But decimal places are not alignable, yet, as discussed in the L</TODO>.

=item o Escape HTML entities or URIs

But not both at the same time!

=item o Extend short header/data/footer rows with empty strings or undef

Auto-extension results in all rows being the same length.

This takes place before the transformation, if any, mentioned next.

=item o Tranform cell values which are empty strings and undef

=item o Pad cell values

=item o Handle UFT8

=item o Return the table as an arrayref of lines or as a string

The arrayref is returned by L</render([%hash])>, and the string by L</render_as_string([%hash])>.

When returning a string by calling C<render_as_string()> (which calls C<render()>), you can specify
how the lines in the arrayref are joined.

In the same way the C<format> parameter discussed just below controls the output, the C<join>
parameter controls the join.

=back

The format of the output is controlled by the C<format> parameter to C<new()>, or by the parameter
to the L</format([$format])> method, or by the value of the C<format> key in the hash passed to
L</render([%hash])> and L</render_as_string(%hash])>, and must be one of these imported constants:

=over 4

=item o format_internal_boxed

All headers, footers and table data are surrounded by ASCII characters.

The rendering is done internally.

See scripts/internal.boxed.pl and output file data/internal.boxed.log.

=item o format_internal_github

Render as github-flavoured markdown.

The rendering is done internally.

See scripts/internal.github.pl and output file data/internal.github.log.

=item o format_internal_html

Render as a HTML table. You can use the L</pass_thru([$hashref])> method to set options for the HTML
table.

The rendering is done internally.

See scripts/internal.html.pl and output file data/internal.html.log.

=item o format_html_table

Passes the data to L<HTML::Table>. You can use the L</pass_thru([$hashref])> method to set options
for the C<HTML::Table> object constructor.

Warning: You must use C<Text::Table::Manifold>'s C<data()> method, or the C<data> parameter to
C<new()>, and not the C<-data> option to C<HTML::Table>. This is because the module processes the
data before calling the C<HTML::Table> constructor.

=item o format_text_csv

Passes the data to L<Text::CSV>. You can use the L</pass_thru([$hashref])> method to set options for
the C<Text::CSV> object constructor.

See scripts/text.csv.pl and output file data/text.csv.log.

=item o format_text_unicodebox_table

Passes the data to L<Text::UnicodeBox::Table>. You can use the L</pass_thru([$hashref])> method to
set options for the C<Text::UnicodeBox::Table> object constructor.

See scripts/text.unicodebox.table.pl and output file data/text.unicodebox.table.log.

=back

See also scripts/synopsis.pl, and the output data/synopsis.log.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<Text::Table::Manifold> as you would any C<Perl> module:

Run:

	cpanm Text::Table::Manifold

or run:

	sudo cpan Text::Table::Manifold

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = Text::Table::Manifold -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Text::Table::Manifold>.

Details of all parameters are explained in the L</FAQ>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</data([$arrayref])>]):

=over 4

=item o alignment => $arrayref of imported constants

This specifies alignment per column. There should be one array element per column of data. The
$arrayref will be auto-extended if necessary, using the constant C<align_center>.

Alignment applies equally to every cell in the column.

A value for this parameter is optional.

Default: align_center for every column.

=item o data => $arrayref_of_arrayrefs

This specifies the table of cell values.

An arrayref of arrayrefs, each inner arrayref is a row of data.

The # of elements in each alignment/header/data/footer row does not have to be the same. See the
C<extend*> parameters for more. Auto-extension results in all rows being the same length.

A value for this parameter is optional.

Default: [].

=item o empty => An imported constant

This specifies how to transform cell values which are the empty string. See also the C<undef>
parameter.

The C<empty> parameter is activated after the C<extend*> parameters has been applied.

A value for this parameter is optional.

Default: empty_as_empty. I.e. do not transform.

=item o escape => An imported constant

This specifies escaping of either HTML entities or URIs.

A value for this parameter is optional.

Default: escape_nothing. I.e. do not transform.

=item o extend_data => An imported constant

The 2 constants available allow you to specify how short data rows are extended. Then, after
extension, the transformations specified by the parameters C<empty> and C<undef> are applied.

A value for this parameter is optional.

Default: extend_with_empty. I.e. extend short data rows with the empty string.

=item o extend_footers => An imported constant

The 2 constants available allow you to specify how short footer rows are extended. Then, after
extension, the transformations specified by the parameters C<empty> and C<undef> are applied.

A value for this parameter is optional.

Default: extend_with_empty. I.e. extend short footer rows with the empty string.

=item o extend_headers => An imported constant

The 2 constants available allow you to specify how short header rows are extended. Then, after
extension, the transformations specified by the parameters C<empty> and C<undef> are applied.

A value for this parameter is optional.

Default: extend_with_empty. I.e. extend short header rows with the empty string.

=item o footers => $arrayref

These are the column footers. See also the C<headers> option.

The # of elements in each header/data/footer row does not have to be the same. See the C<extend*>
parameters for more.

A value for this parameter is optional.

Default: [].

=item o format => An imported constant

This specifies which format to output from the rendering methods.

A value for this parameter is optional.

Default: format_internal_boxed.

=item o headers => $arrayref

These are the column headers. See also the C<footers> option.

The # of elements in each header/data/footer row does not have to be the same. See the C<extend*>
parameters for more.

A value for this parameter is optional.

Default: [].

=item o include => An imported constant

Controls whether header/data/footer rows are included in the output.

The are three constants available, and any of them can be combined with '|', the logical OR
operator.

A value for this parameter is optional.

Default: include_headers | include_data.

=item o join => $string

L</render_as_string([%hash])> uses $hash{join}, or $self -> join, in Perl's
C<join($join, @$araref)> to join the elements of the arrayref returned by internally calling
L</render([%hash])>.

C<render()> ignores the C<join> key in the hash.

A value for this parameter is optional.

Default: ''.

=item o padding => $integer

This integer is the # of spaces added to each side of the cell value, after the C<alignment>
parameter has been applied.

A value for this parameter is optional.

Default: 0.

=item o pass_thru => $hashref

A hashref of values to pass thru to another object.

The keys in this $hashref control what parameters are passed to rendering routines.

A value for this parameter is optional.

Default: {}.

=item o undef => An imported constant

This specifies how to transform cell values which are undef. See also the C<empty> parameter.

The C<undef> parameter is activated after the C<extend*> parameters have been applied.

A value for this parameter is optional.

Default: undef_as_undef. I.e. do not transform.

=back

=head1 Methods

See the L</FAQ> for details of all importable constants mentioned here.

And remember, all methods listed here which are parameters to L</new([%hash])>, are also parameters
to both L</render([%hash])> and L</render_as_string([%hash])>.

=head2 alignment([$arrayref])

Here, the [] indicate an optional parameter.

Returns the alignment as an arrayref of constants, one per column.

There should be one element in $arrayref for each column of data. If the $arrayref is too short,
C<align_center> is the default for the missing alignments.

Obviously, $arrayref might force spaces to be added to one or both sides of a cell value.

Alignment applies equally to every cell in the column.

This happens before any spaces specified by L</padding([$integer])> are added.

See the L</FAQ#What are the constants for alignment?> for legal values for the alignments (per
column).

C<alignment> is a parameter to L</new([%hash])>. See L</Constructor and Initialization>.

=head2 data([$arrayref])

Here, the [] indicate an optional parameter.

Returns the data as an arrayref. Each element in this arrayref is an arrayref of one row of data.

The structure of C<$arrayref>, if provided, must match the description in the previous line.

Rows do not need to have the same number of elements.

Use Perl's C<undef> or '' (the empty string) for missing values.

See L</empty([$empty])> and L</undef([$undef])> for how '' and C<undef> are handled.

See L</extend_data([$extend])> for how to extend short data rows, or let the code extend auto-extend
them.

C<data> is a parameter to L</new([%hash])>. See L</Constructor and Initialization>.

=head2 empty([$empty])

Here, the [] indicate an optional parameter.

Returns the option specifying how empty cell values ('') are being dealt with.

$empty controls how empty strings in cells are rendered.

See the L</FAQ#What are the constants for handling cell values which are empty strings?>
for legal values for $empty.

See also L</undef([$undef])>.

C<empty> is a parameter to L</new([%hash])>. See L</Constructor and Initialization>.

=head2 escape([$escape])

Here, the [] indicate an optional parameter.

Returns the option specifying how HTML entities and URIs are being dealt with.

$escape controls how either HTML entities or URIs are rendered.

See the L</FAQ#What are the constants for escaping HTML entities and URIs?>
for legal values for $escape.

C<escape> is a parameter to L</new([%hash])>. See L</Constructor and Initialization>.

=head2 extend_data([$extend])

Here, the [] indicate an optional parameter.

Returns the option specifying how short data rows are extended.

If the # of elements in a data row is shorter than the longest row, $extend
specifies how to extend those short rows.

See the L</FAQ#What are the constants for extending short rows?> for legal values for $extend.

C<extend_data> is a parameter to L</new([%hash])>. See L</Constructor and Initialization>.

=head2 extend_footers([$extend])

Here, the [] indicate an optional parameter.

Returns the option specifying how short footer rows are extended.

If the # of elements in a footer row is shorter than the longest row, $extend
specifies how to extend those short rows.

See the L</FAQ#What are the constants for extending short rows?> for legal values for $extend.

C<extend_footers> is a parameter to L</new([%hash])>. See L</Constructor and Initialization>.

=head2 extend_headers([$extend])

Here, the [] indicate an optional parameter.

Returns the option specifying how short header rows are extended.

If the # of elements in a header row is shorter than the longest row, $extend
specifies how to extend those short rows.

See the L</FAQ#What are the constants for extending short rows?> for legal values for $extend.

C<extend_headers> is a parameter to L</new([%hash])>. See L</Constructor and Initialization>.

=head2 footers([$arrayref])

Here, the [] indicate an optional parameter.

Returns the footers as an arrayref of strings.

$arrayref, if provided, must be an arrayref of strings.

See L</extend_footers([$extend])> for how to extend a short footer row, or let the code auto-extend
it.

C<footers> is a parameter to L</new([%hash])>. See L</Constructor and Initialization>.

=head2 format([$format])

Here, the [] indicate an optional parameter.

Returns the format as a constant (actually an integer).

See the L</FAQ#What are the constants for formatting?> for legal values for $format.

C<format> is a parameter to L</new([%hash])>. See L</Constructor and Initialization>.

=head2 format_as_internal_boxed()

Called by L</render([%hash])>.

=head2 format_as_internal_github()

Called by L</render([%hash])>.

=head2 format_as_internal_html()

Called by L</render([%hash])>.

=head2 format_as_html_table()

Called by L</render([%hash])>.

=head2 format_as_text_csv().

Called by L</render([%hash])>.

=head2 format_as_text_unicodebox_table()

Called by L</render([%hash])>.

=head2 headers([$arrayref])

Here, the [] indicate an optional parameter.

Returns the headers as an arrayref of strings.

$arrayref, if provided, must be an arrayref of strings.

See L</extend_headers([$extend])> for how to extend a short header row, or let the code auto-extend
it.

C<headers> is a parameter to L</new([%hash])>. See L</Constructor and Initialization>.

=head2 include([$include])

Here, the [] indicate an optional parameter.

Returns the option specifying if header/data/footer rows are included in the output.

See the L</FAQ#What are the constants for including/excluding rows in the output?> for legal values
for $include.

C<include> is a parameter to L</new([%hash])>. See L</Constructor and Initialization>.

=head2 join([$join])

Here, the [] indicate an optional parameter.

Returns the string used to join lines in the table when you call L</render_as_string([%hash])>.

$join is the parameter passed to the Perl function C<join()> by C<render_as_string()>.

Further, you can use the key C<join> in %hash to pass a value directly to
L</render_as_string([%hash])>.

=head2 new([%hash])

The constructor. See L</Constructor and Initialization> for details of the parameter list.

Note: L</render([%hash])> and L</render_as_string([%hash])>support the same options as C<new()>.

=head2 padding([$integer])

Here, the [] indicate an optional parameter.

Returns the padding as an integer.

Padding is the # of spaces to add to both sides of the cell value after it has been aligned.

C<padding> is a parameter to L</new([%hash])>. See L</Constructor and Initialization>.

=head2 pass_thru([$hashref])

Here, the [] indicate an optional parameter.

Returns the hashref previously provided.

See L</FAQ#What is the format of the $hashref used in the call to pass_thru()?> for details.

See scripts/html.table.pl, scripts/internal.table.pl and scripts/text.csv.pl for sample code where
it is used in various ways.

C<pass_thru> is a parameter to L</new([%hash])>. See L</Constructor and Initialization>.

=head2 render([%hash])

Here, the [] indicate an optional parameter.

Returns an arrayref, where each element is 1 line of the output table. These lines do not have "\n"
or any other line terminator added by this module.

It's up to you how to handle the output. The simplest thing is to just do:

	print join("\n", @{$table -> render}), "\n";

Note: C<render()> supports the same options as L</new([%hash])>.

C<render()> ignores the C<join> key in the hash.

See also L</render_as_string([%hash])>.

=head2 render_as_string([%hash])

Here, the [] indicate an optional parameter.

Returns the rendered data as a string.

C<render_as_string> uses the value of $hash{join}, or the result of calling $self -> join, in Perl's
C<join($join, @$araref)> to join the elements of the arrayref returned by internally calling
L</render([%hash])>.

Note: C<render_as_string()> supports the same options as L</new([%hash])>, and passes them all to
L</render([%hash])>.

See also L</render([%hash])>.

=head2 undef([$undef])

Here, the [] indicate an optional parameter.

Returns the option specifying how undef cell values are being dealt with.

$undef controls how undefs in cells are rendered.

See the L</FAQ#What are the constants for handling cell values which are undef?>
for legal values for $undef.

See also L</empty([$empty])>.

C<undef> is a parameter to L</new([%hash])>. See L</Constructor and Initialization>.

=head2 widths()

Returns an arrayref of the width of each column, after the data is cleaned and rectified, but before
it has been aligned or padded.

=head1 FAQ

Note: See L</TODO> for what has not been implemented yet.

=head2 How are imported constants used?

Firstly, you must import them with:

	use Text::Table::Manifold ':constants';

Then you can use them in the constructor:

	my($table) = Text::Table::Manifold -> new(empty => empty_as_text);

And/or you can use them in method calls:

	$table -> format(format_internal_boxed);

See scripts/synopsis.pl for various use cases.

Note how sample code uses the names of the constants. The integer values listed below are just FYI.

=head2 What are the constants for alignment?

The parameters, one per column, to L</alignment([$arrayref])> must be one of the following:

=over 4

=item o align_left  => 0

=item o align_center => 1

So-spelt. Not 'centre'.

=item o align_right => 2

=back

Alignment applies equally to every cell in a column.

=head2 What are the constants for handling cell values which are empty strings?

The parameter to L</empty([$empty])> must be one of the following:

=over 4

=item o empty_as_empty => 0

Do nothing. This is the default.

=item o empty_as_minus => 1

Convert empty cell values to '-'.

=item o empty_as_text  => 2

Convert empty cell values to the text string 'empty'.

=item o empty_as_undef => 3

Convert empty cell values to undef.

=back

See also L</undef([$undef])>.

Warning: This updates the original data!

=head2 What are the constants for escaping HTML entities and URIs?

The parameter to L</escape([$escape])> must be one of the following:

=over 4

=item o escape_nothing => 0

This is the default.

=item o escape_html    => 1

Use L<HTML::Entities::Interpolate> to escape HTML entities. C<HTML::Entities::Interpolate> cannot
be loaded at runtime, and so is always needed.

=item o escape_uri     => 2

Use L<URI::Escape>'s uri_escape() method to escape URIs. C<URI::Escape> is loaded at runtime
if needed.

=back

Warning: This updates the original data!

=head2 What are the constants for extending short rows?

The parameters to L</extend_data([$extend])>, L</extend_footers([$extend])> and
L</extend_headers([$extend])>, must be one of the following:

=over 4

=item o extend_with_empty => 0

Short header/data/footer rows are extended with the empty string.

Later, the values discussed under
L</FAQ#What are the constants for handling cell values which are empty strings?> will be applied.

=item o extend_with_undef => 1

Short header/data/footer rows are extended with undef.

Later, the values discussed under
L</FAQ#What are the constants for handling cell values which are undef?> will be applied.

=back

See also L</empty([$empty])> and L</undef([$undef])>.

Warning: This updates the original data!

=head2 What are the constants for formatting?

The parameter to L</format([$format])> must be one of the following:

=over 4

=item o format_internal_boxed        => 0

Render internally.

=item o format_text_csv              => 1

L<Text::CSV> is loaded at runtime if this option is used.

=item o format_internal_github       => 2

Render internally.

=item o format_internal_html         => 3

Render internally.

=item o format_html_table            => 4

L<HTML::Table> is loaded at runtime if this option is used.

=item o format_text_unicodebox_table => 5

L<Text::UnicodeBox::Table> is loaded at runtime if this option is used.

=back

=head2 What are the constants for including/excluding rows in the output?

The parameter to L</include([$include])> must be one or more of the following:

=over 4

=item o include_data    => 1

Data rows are included in the output.

=item o include_footers => 2

Footer rows are included in the output.

=item o include_headers => 4

Header rows are included in the output.

=back

=head2 What is the format of the $hashref used in the call to pass_thru()?

It takes these (key => value) pairs:

=over 4

=item o new => $hashref

=over 4

=item o For internal rendering of HTML

$$hashref{table} is used to specify parameters for the C<table> tag.

Currently, C<table> is the only tag supported by this mechanism.

=item o When using L<HTML::Table>, for external rendering of HTML

$hashref is passed to the L<HTML::Table> constructor.

=item o When using L<Text::CSV>, for external rendering of CSV

$hashref is passed to the L<Text::CSV> constructor.

=item o When using L<Text::UnicodeBox::Table>, for external rendering of boxes

$hashref is passed to the L<Text::UnicodeBox::Table> constructor.

=back

=back

See html.table.pl, internal.html.pl and text.csv.pl, all in the scripts/ directory.

=head2 What are the constants for handling cell values which are undef?

The parameter to L</undef([$undef])> must be one of the following:

=over 4

=item o undef_as_empty => 0

Convert undef cell values to the empty string ('').

=item o undef_as_minus => 1

Convert undef cell values to '-'.

=item o undef_as_text  => 2

Convert undef cell values to the text string 'undef'.

=item o undef_as_undef => 3

Do nothing.

This is the default.

=back

See also L</empty([$undef])>.

Warning: This updates the original data!

=head2 Will you extend the program to support other external renderers?

Possibly, but only if the extension matches the spirit of this module, which is roughly: Keep it
simple, and provide just enough options but not too many options. IOW, there is no point in passing
a huge number of options to an external class when you can use that class directly anyway.

I've looked a number of times at L<PDF::Table>, for example, but it is just a little bit too
complex. Similarly, L<Text::ANSITable> has too many methods.

See also L</TODO>.

=head2 How do I run author tests?

This runs both standard and author tests:

	shell> perl Build.PL; ./Build; ./Build authortest

=head1 TODO

=over 4

=item o Fancy alignment of real numbers

It makes sense to right-justify integers, but in the rest of the table you probably want to
left-justify strings.

Then, vertically aligning decimal points (whatever they are in your locale) is another complexity.

See L<Text::ASCIITable> and L<Text::Table>.

=item o Embedded newlines

Cell values could be split at each "\n" character, to find the widest line within the cell. That
would be then used as the cell's width.

For Unicode, this is complex. See L<http://www.unicode.org/versions/Unicode7.0.0/ch04.pdf>, and
especially p 192, for 'Line break' controls. Also, the Unicode line breaking algorithm is documented
in L<http://www.unicode.org/reports/tr14/>.

Perl modules and other links relevant to this topic are listed under L</See Also#Line Breaking>.

=item o Nested tables

This really requires the implementation of embedded newline analysis, as per the previous point.

=item o Pass-thru class support

The problem is the mixture of options required to drive classes.

=item o Sorting the rows, or individual columns

See L<Data::Table> and L<HTML::Table>.

=item o Color support

See L<Text::ANSITable>.

=item o Subtotal support

Maybe one day. I did see a subtotal feature in a module while researching this, but I can't find it
any more.

See L<Data::Table>. It has grouping features.

=back

=head1 See Also

=head2 Table Rendering

L<Any::Renderer>

L<Data::Formatter::Text>

L<Data::Tab>

L<Data::Table>

L<Data::Tabulate>

L<Gapp::TableMap>

L<HTML::Table>

L<HTML::Tabulate>

L<LaTeX::Table>

L<PDF::Table>

L<PDF::TableX>

L<PDF::Report::Table>

L<Table::Simple>

L<Term::TablePrint>

L<Text::ANSITable>

L<Text::ASCIITable>

L<Text::CSV>

L<Text::FormatTable>

L<Text::MarkdownTable>

L<Text::SimpleTable>

L<Text::Table>

L<Text::Table::Tiny>

L<Text::TabularDisplay>

L<Text::Tabulate>

L<Text::UnicodeBox>

L<Text::UnicodeBox::Table>

L<Text::UnicodeTable::Simple>

L<Tie::Array::CSV>

=head2 Line Breaking

L<Text::Format>

L<Text::LineFold>

L<Text::NWrap>

L<Text::Wrap>

L<Text::WrapI18N>

L<Unicode::LineBreak>. The distro also includes L<Unicode::GCString>, which I use already in
Text::Table::Manifold.

L<UNICODE LINE BREAKING ALGORITHM|http://unicode.org/reports/tr14/>

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Text-Table-Manifold>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text::Table::Manifold>.

=head1 Author

L<Text::Table::Manifold> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2015.

Marpa's homepage: L<http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2014, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl Artistic License, a copy of which is available at:
	https://perldoc.perl.org/perlartistic.html.

=cut
