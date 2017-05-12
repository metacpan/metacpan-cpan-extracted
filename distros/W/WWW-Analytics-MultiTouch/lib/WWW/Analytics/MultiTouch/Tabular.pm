package WWW::Analytics::MultiTouch::Tabular;

use warnings;
use strict;

use IO::File;
use strict;
use warnings;
use Text::Table;
use Text::CSV_XS;
use Spreadsheet::WriteExcel;
use Spreadsheet::WriteExcel::Utility;
use Digest::MD5 qw/md5_hex/;
use Params::Validate qw(:all);
use List::Util qw/max/;
use Storable qw/dclone/;
use Hash::Merge qw/merge/;
use POSIX qw/floor/;
use LWP::UserAgent;
use File::Temp;
use Encode;

my %legal_name = map { $_ => 1 } qw/font size color bold italic underline font_strikeout font_script font_outline font_shadow num_format locked hidden align valign rotation text_wrap test_justlast center_across indent shrink pattern bg_color fg_color border bottom top left right border_color bottom_color top_color left_color right_color/;

my %chart_methods = ( title => [ qw/name name_formula/ ],
		      x_axis => [ qw/name name_formula/ ],
		      y_axis => [ qw/name name_formula/ ],
		      legend => [ qw/position/ ],
		      chartarea => [ qw/color line_color line_pattern line_weight/ ],
		      plotarea => [ qw/visible color line_color line_pattern line_weight/ ],
    );


sub new
{
    my $class = shift;

    my %params = validate(@_, { format => 0,
				filename => 0,
				header_layout => 0,
				footer_layout => 0,
			  });

    for my $method (qw/format filename filehandle/) {
	no strict 'refs';
	*{"${class}::$method"} = sub {
	    my $self = shift;
	    my $ret = $self->{$method};
	    $self->{$method} = $_[0] if defined $_[0];
	    return $ret;
	}
    }

    my $self = bless \%params, ref $class || $class;

    $self->open;

    return $self;
}


sub print 
{
    my ($self, $data) = @_;

    local $_ = $self->format;
  SWITCH: {
      m/csv/ && do { $self->csv($data), last SWITCH };
      m/xls/ && do { $self->xls($data), last SWITCH };
      $self->txt($data);
  };
}

sub txt
{
    my ($self, $datasets) = @_;
    my $handle = $self->filehandle;
    binmode $handle, ':utf8';
    foreach my $data (@$datasets) {
	my $tab = Text::Table->new(map { _text_of($_) } @{$data->{'headings'}});

	$tab->load(map { my $row = $_; [ map { _text_of($_) } @$row ] } @{$data->{'data'}});
	$handle->print($data->{'sheetname'} . "\n") if $data->{'sheetname'};
	$handle->print(_text_of($data->{'title'}) . "\n" . $tab->table);
	$handle->print("\n\n");
	if ($data->{'notes'} && @{$data->{'notes'}}) {
	    $handle->print(_text_of($_) . "\n") for @{$data->{'notes'}};
	    $handle->print("\n\n");
	}
    }
}


sub csv
{
    my ($self, $datasets) = @_;

    my $handle = $self->filehandle;
    binmode $handle, ':utf8';

    my $csv = Text::CSV_XS->new( { 'binary'=>1 } );
    foreach my $data (@$datasets) {
	if ($data->{'sheetname'}) {
	    $csv->print($handle, [ $data->{'sheetname'} ]);
	    $handle->print("\n");
	}
	$csv->print($handle, [ _text_of($data->{'title'}) ]);
	$handle->print("\n");
	$csv->print($handle, [ map { _text_of($_) } @{$data->{'headings'}}] );
	$handle->print("\n");
	map { my $row = $_; 
	      $csv->print($handle, [ map { _text_of($_) } @$row ]); 
	      $handle->print("\n"); 
	} @{$data->{'data'}};
	$handle->print("\n\n\n");
	if ($data->{'notes'} && @{$data->{'notes'}}) {
	    $handle->print(_text_of($_) . "\n") for @{$data->{'notes'}};
	    $handle->print("\n\n\n");
	}
    }
}

sub xls
{
    my ($self, $worksheets) = @_;

    my $handle = $self->filehandle;
    binmode $handle, ':raw';
    my $xls = Spreadsheet::WriteExcel->new($handle);

    my $bold = $xls->add_format();

    $bold->set_bold();

    # Collate formats
    # fmts stores colour data, and format data (indexed by md5 of format hash)
    my %fmts = ( colours => {},
		 colour_indexes => [ 19, 21, 24 .. 32, 34 .. 52, 53 .. 63 ],
		 last_colour_index => 0,
		 _tempfiles => {},
	);
    for my $tab (@$worksheets) {
	_collate_formats($xls, \%fmts, $tab->{title});
	_collate_formats($xls, \%fmts, $_) for @{$tab->{headings} || []};
	for my $row (@{$tab->{'data'}}) {
	    for my $cell (@$row) {
		_collate_formats($xls, \%fmts, $cell);
	    }
	}
    }

    my $tabcount = 0;
    foreach my $tab (@$worksheets) {
	$tabcount++;
	my $name = $tab->{'sheetname'} || "Sheet $tabcount";
	$name = substr($name, 0, 31) if length($name) > 31;
	$name = Encode::encode_utf8($name);
	my $worksheet = $xls->add_worksheet($name);
	$name = $worksheet->get_name(); # in case characters get altered
	my $row = $self->{layout}->{start_row} || 0;
	my $col = 0;
	my @cols = map { length(ref($_) eq 'ARRAY' ? $_->[0] : $_); } @{$tab->{'headings'}};

	_write_layout($worksheet, $xls, \%fmts, $tab, 
		      merge($self->{header_layout}, $tab->{header_layout}), 
		      0,
		      \$row, \@cols);

	$row++;
	_write_cell($worksheet, \%fmts, $row++, 0, $tab->{'title'}, $bold);
	for my $header (@{$tab->{headings}}) {
	    _write_cell($worksheet, \%fmts, $row, $col++, $header, $bold);
	}
	$row++;

	my $start_row = $row; # keep data start row for chart references
	foreach my $line (@{$tab->{'data'}}) {
	    $col = 0;
	    for my $cell (@{$line}) {
		_write_cell($worksheet, \%fmts, $row, $col, $cell);
		$col++;
	    }
	    $row++;

	    for my $i (0..@$line) {
		$cols[$i] = length(_text_of($line->[$i])) if ($line->[$i] && length(_text_of($line->[$i])) > ($cols[$i] || 0));
	    }
	}

	foreach my $chart (@{$tab->{chart}}) {
	    my $obj = $xls->add_chart( type => ($chart->{type} || 'line'), embedded => 1 );
	    for my $series (@{$chart->{series}}) {
		$obj->add_series(categories => xl_range_formula($name,
								$series->{categories}[0] + $start_row,
								$series->{categories}[1] + $start_row,
								$series->{categories}[2],
								$series->{categories}[3]),
				 values => xl_range_formula($name,
							    $series->{values}[0] + $start_row,
							    $series->{values}[1] + $start_row,
							    $series->{values}[2],
							    $series->{values}[3]),
				 name_formula => _to_formula($name, $start_row, $series->{name_formula}),
				 name => $series->{name},
		    );
	    }

	    for my $method (keys %chart_methods) {
		next unless exists $chart->{$method};
				  
		my %props = map { $_ => $chart->{$method}{$_} } 
		            grep { exists $chart->{$method}{$_} } @{$chart_methods{$method}};
		$method = 'set_' . $method;
		if (scalar keys %props > 0) {
		    if (exists $props{name_formula}) {
			$props{name_formula} = _to_formula($name, $start_row, $props{name_formula});
		    }
		    _add_custom_colour($xls, \%fmts, \%props);
		    $obj->$method(%props);
		}
	    }
	    my $ins_row = ++$row;
	    if (defined $chart->{abs_row}) {
		$ins_row = $chart->{abs_row} + $start_row;
	    }
	    else {
		$row += ($chart->{row} || 0) + floor(20 * ($chart->{y_scale} || 1));
	    }
	    $worksheet->insert_chart($ins_row + ($chart->{row} || 0), 
				     $chart->{abs_col} || $chart->{col} || 0, 
				     $obj, 0, 0, $chart->{x_scale} || 1, $chart->{y_scale} || 1);
	}
	$row++;

	_write_layout($worksheet, $xls, \%fmts, $tab, 
		      merge($self->{footer_layout}, $tab->{footer_layout}), 
		      $row,
		      \$row, \@cols);

	for my $i (0..@cols) {
	    $cols[$i] += 2;
	    $cols[$i] = 6 if ($cols[$i] < 6);
	    $cols[$i] = 60 if ($cols[$i] > 60);
	    $worksheet->set_column($i, $i, $cols[$i]);
	}
    }

    $xls->close();
    unlink $_ for values %{$fmts{_tempfiles}};
}

sub _to_formula {
    my ($name, $start_row, $name_formula) = @_;
    return "='$name'!" . xl_rowcol_to_cell($name_formula->[0] + $start_row,
					   $name_formula->[1], 1, 1);
}

sub _get_sub_text {
    my $subst = shift;
    return (ref($subst) eq 'ARRAY' ? $subst->[0] : $subst) || '';
}

sub _substitute_text {
    my $tab = shift;
    my $texts = shift;

    $texts = ref($texts) eq 'ARRAY' ? dclone($texts) : [ $texts ];
    for (@$texts) {
	s{(?<!\\)@([\w_]+)}{ _get_sub_text($tab->{$1}) }eg;
	s/\\@/@/g;
    }
    return $texts;
}


sub _row_of {
    my $img = shift;
    my $baserow = shift;

    if (defined $img->{row}) {
	$_[0] = $img->{row};
	return $baserow + $img->{row};
    }
    return $baserow + ++$_[0];
}

sub _text_of {
    my $cell = shift;

    $cell = $cell->[0] if ref($cell) eq 'ARRAY';
    return defined $cell ? $cell : '';
}

sub _cache_image_file {
    my ($fmts, $img) = @_;

    return $img->{filename} unless $img->{filename} =~ m{^https?://};

    if (exists($fmts->{_tempfiles}{$img->{filename}})
	&& -f $fmts->{_tempfiles}{$img->{filename}}) {
	return $img->{filename} = $fmts->{_tempfiles}{$img->{filename}};
    }
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($img->{filename});
    if (! $response->is_success) {
	warn "Failed to download $img->{filename}\n";
	return;
    }
    if (my $dst = File::Temp->new(UNLINK => 0)) {
	print $dst $response->decoded_content;
	close $dst;
	return $img->{filename} = $fmts->{_tempfiles}{$img->{filename}} = $dst->filename;
    }
    warn "Failed to store $img->{filename}\n";
    return;
}

sub _write_layout {
    my ($worksheet, $xls, $fmts, $tab, $layout, $baserow, $rowref, $colsref) = @_;

    my $current_row = 0;
    for my $method (keys %$layout) {
	my $params = $layout->{$method};
	if ($method eq 'image') {
	    $params = [ $params ] unless ref($params) eq 'ARRAY';
	    for my $img (@{$params}) {
		_cache_image_file($fmts, $img) or next;
		$worksheet->insert_image(_row_of($img, $baserow, $current_row),
					 $img->{col} || 0,
					 $img->{filename},
					 $img->{x_offset} || 0,
					 $img->{y_offset} || 0,
					 $img->{x_scale} || 1,
					 $img->{y_scale} || 1,
		    );
	    }
	}
	elsif ($method eq 'header' || $method eq 'footer') {
	    $params = [ $params ] unless ref($params) eq 'ARRAY';
	    for my $hdr (@{$params}) {
		my $texts = _substitute_text($tab, $hdr->{text});
		if ($hdr->{colspan} || $hdr->{rowspan}) {
		    my $format = _collate_formats($xls, $fmts, [ undef, $hdr->{cell_format} ||= { bold => 1 }], 1);
		    my $i = 0;
		    for my $text (@$texts) {
			my $r = _row_of($hdr, $baserow + $i, $current_row);
			my $c = $hdr->{col} || 0;
			$worksheet->merge_range($r,
						$c,
						$r + ($hdr->{rowspan} || 0),
						$c + ($hdr->{colspan} || 0),
						$text,
						$format);
			$i++;
			$$rowref = max($$rowref, $r + ($hdr->{rowspan} || 0));
			if (! $hdr->{colspan} && defined $colsref) {
			    $colsref->[$hdr->{col}] = max($colsref->[$hdr->{col}], length($text));
			}
		    }
		}
		else {
		    _collate_formats($xls, $fmts, [ undef, $hdr->{cell_format} ]);
		    my $i = 0;
		    for my $text (@$texts) {
			$text ||= '';
			my $r = _row_of($hdr, $baserow + $i, $current_row);
			my $c = $hdr->{col} || 0;
			_write_cell($worksheet, $fmts, $r, $c, [ $text, $hdr->{cell_format} ]);
			$i++;
			$$rowref = max($$rowref, $r);
			$colsref->[$c] = max($colsref->[$c] || 0, length($text)) if defined $colsref;
		    }
		}
	    }
	}
	elsif ($worksheet->can($method)) {
	    $worksheet->$method(ref($params) eq 'ARRAY' ? @$params : $params);
	}

    }
}

sub _to_legal_format {
    my $fmt = shift;

    my %vals = map { $_ => $fmt->{$_} } 
      grep { exists($legal_name{$_}) && defined($fmt->{$_}) }
      keys %{$fmt};
    if (scalar keys %vals != scalar keys %$fmt) {
	warn "Invalid format key found: " . join(' ', grep { ! exists($legal_name{$_}) } keys %{$fmt}) . "\n";
    }

    return \%vals;
}

# Convert format to unique string
# Not required to be reversible
sub _to_format_key {
    my $fmt = shift;
    my $key = '';
    
    for my $k (sort keys %$fmt) {
	my $v = $fmt->{$k};
	$key .= "$k=$v&";
    }

    return md5_hex($key);
}

sub _add_custom_colour {
    my ($xls, $fmts, $fmt) = @_;

    # Create custom colours for RGB triples #RRGGBB
    for my $colourkey (grep { m/color/ } keys %$fmt) {
	my $colourval = $fmt->{$colourkey};
	next unless $colourval =~ m/^#/;
	if (! exists($fmts->{colours}{$colourval})) {
	    $fmts->{colours}{$colourval} = $xls->set_custom_color($fmts->{colour_indexes}[$fmts->{last_colour_index}++], $colourval);
	}
	$fmt->{$colourkey} = $fmts->{colours}{$colourval};
    }
}

sub _collate_formats {
    my ($xls, $fmts, $cell, $merged) = @_;
    if (ref($cell) eq 'ARRAY' && @$cell == 2 && ref($cell->[1]) eq 'HASH') {
	my $fmt = _to_legal_format($cell->[1]);
	my $fmt_key = _to_format_key($merged ? { %$fmt, merged => 1 } : $fmt);
	_add_custom_colour($xls, $fmts, $fmt);
	unless (exists $fmts->{$fmt_key}) {
	    $fmts->{$fmt_key} = $xls->add_format(%$fmt);
	}
	return $fmts->{$fmt_key}
    }
    return;
}

sub _write_cell {
    my ($worksheet, $fmts, $row, $col, $cell, $def_fmt) = @_;

    if (ref($cell) eq 'ARRAY') {
	$worksheet->write($row, $col, $cell->[0], $fmts->{_to_format_key(_to_legal_format($cell->[1]))} || $def_fmt);
    }
    else {
	$worksheet->write($row, $col, $cell, $def_fmt);
    }
}


sub open
{
    my ($self, $format, $filename) = @_;
    my $filehandle;

    $self->format($format) if $format;
    $self->filename($filename) if $filename;

    if ($self->filename) {
	$filehandle = IO::File->new(">" . $self->filename) or die "Failed to open " . $self->filename . ": $!";
    }
    else {
	$filehandle = \*STDOUT;
    }

    $self->filehandle($filehandle);
}


sub close
{
    my $self = shift;

    if ($self->filehandle) {
	$self->filehandle->close();
	$self->filehandle(undef);
	$self->filename(undef);
    }
}

=head1 NAME

WWW::Analytics::MultiTouch::Tabular - Provides various output formats for writing tabular reports

=head1 SYNOPSIS

# Simple usage

   use WWW::Analytics::MultiTouch::Tabular;

   my @data = ( [ 1, 2, 3 ],
		[ 4, 5, 6 ],
		[ 7, 8, 9 ],
              );
   my @reports = (
       { 
       title => "Number of Results in Top 10, by Site",
       sheetname => "Top Positions",
       headings => [ "Site", "Engine", "Top 10 Results", "Unique URLs", "Top 10 Previous Week", "Unique URLs Previous Week" ],
       data => \@data,
       },
       ...
       );
   my $output = WWW::Analytics::MultiTouch::Tabular->new({format => 'txt', outfile => $file});
   $output->print(\@reports);
   $output->close();

# With formatting 

   my @data = ( [ [ 1, { color => 'red' } ], 2, 3 ],
		[ [ 4, { color => '#123456' ], 5, 6 ],
		[ [ 7, { bold => 1 } ], 8, 9 ],
              );

=head1 DESCRIPTION

Takes a list of reports and outputs them in the specified format (text, csv, or Excel).

For Excel, supports extended formatting including headers, footers, colours, fonts, images, charts.

=head1 METHODS

=head2 new

    $output = WWW::Analytics::MultiTouch::Tabular->new({format => 'txt', filename => $file});

Creates a new WWW::Analytics::MultiTouch::Tabular object.  Options are as follows:

=over 4

=item * format

txt, csv or xls.

=item * filename

Name of output file

=item * header_layout, footer_layout

See L<HEADERS AND FOOTERS>.

=back

=head2 print

  $output->print(\@reports);

Prints given data in txt, csv, or xls format.

Each item in @reports is a hash containing the following elements:

=over 4

=item * title

Report title

=item * sheetname

Sheet name, where applicable (as in spreadsheet output).

=item * headings

Array of column headings.  Each heading entry may be a scalar (used as is) or a
two-element array, in which case the first element is the data and the second
element is the cell format.  See L<CELL FORMAT> for cell formatting details.

=item * data

Array of data; each row is a row in the output, with columns corresponding to
the column headings given.  Each data point may be a scalar (used as is) or a
two-element array, in which case the first element is the data and the second
element is the cell format.  See L<CELL FORMAT> for cell formatting details.

Examples:

Simple data array, no formatting:

      data => [ [ 1, 2, 3 ],
		[ 4, 5, 6 ],
		[ 7, 8, 9 ],
              ]

Data array with first entry in each row formatted:

      data => [ [ [ 1, { color => 'red' } ], 2, 3 ],
		[ [ 4, { color => '#123456' ], 5, 6 ],
		[ [ 7, { bold => 1 } ], 8, 9 ],
              ]


=item * header_layout, footer_layout

See L<HEADERS AND FOOTERS>.

=item * chart

Insert one or more charts.  Example:

		   chart => [ { type => 'column',
				x_scale => 1.5,
				y_scale => 1.5,
				series => [ map {
				    { categories => [ -1, -1, 1, scalar @{$data[0]} ],
				      values => [ $_, $_, 1, scalar @{$data[0]} ],
				      name_formula => [$_, 0],
				      name => $data[$_][0],
				    } } (0 .. @data - 1) ]
			      } ],

Options are:

=over 4

=item * type

May be 'area', 'bar', 'column', 'line', 'pie', 'scatter', 'stock'. See
L<Spreadsheet::WriteExcel::Chart> for more details on the available types.

=item * series

This is the array of data series for the chart.  'categories', 'values' and
'name_formula' are given in terms of cell ranges referenced to the start of the
spreadsheet data.  The heading row may be referenced as -1 relative to the start
of the data.  See L<Spreadsheet::WriteExcel::Chart/add_series> for more details.

=item * row, abs_row

Optional row offset or absolute row position.  Will be placed at the current row if not specified.

=item * col, abs_col

Optional column number.  Will be placed at column 0 if not specified.

=item * x_scale, y_scale

Optional chart scaling factors.

=item * title, x_axis, y_axis, legend, chartarea, plotarea

See the corresponding set_* method in L<Spreadsheet::WriteExcel::Chart> for more details.

=back

=back

=head2 txt

    $output->txt(\@reports);

Generate output in plain text format.

=head2 csv

    $output->csv(\@reports);

Generate output in CSV format.

=head2 xls

    $output->xls(\@reports);

Generate output in Excel spreadsheet format.

  
=head2 open

    $output->format('csv');
    $output->filename("$dir/csv-test.csv");
    $output->open;

    $output->open("xls", "$dir/xls-test.xls");

'open' opens a file for writing.  It is usually not necessary to call 'open' as it 
is implicit in 'new'.  However, if you wish to re-use the object created with
'new' to output a different format or to a different file, then you need to call
open with the new format/file arguments, or after setting the new format and
output file with the format and outfile methods.


=head2 format

  $output->format('xls');

Set/get format to be used in L<print>.  L<open> must be called for the format change to take effect.

=head2 filename

Set/get filename to be used in L<print>. L<open> must be called for the filename change to take effect.

If no filename is provided as an argument or previously set, STDOUT will be used.

=head2 outfile

'outfile' is equivalent to 'filename', provided for backward compatibility.

=head2 filehandle

    $output->filehandle(\*STDOUT);

As an alternative to 'open', you can set the file handle explicitly using filehandle().

=head2 close

Close file

=head1 HEADERS AND FOOTERS

A set of images, rows of text and/or spreadsheet operations to create page headers and footers.  'header_layout' is used prior to placing any data on the page, and 'footer_layout' afterwards.  Example:

 'header_layout' => {
          'hide_gridlines' => '2',
          'image' => [
                     {
                       'filename' => 'http://www.multitouchanalytics.com/images/multitouch-analytics-header.jpg',
                       'col' => 0,
                       'row' => 1,
                       'x_scale' => 0.7,
                       'y_scale' => 0.7
                     },
                   ],
          'header' => [
                      {
                        'colspan' => '5',
                        'cell_format' => {
                                         'color' => 'white',
                                         'align' => 'center',
                                         'bold' => 1,
                                         'bg_color' => 'blue',
                                         'size' => '16'
                                       },
                        'text' => 'Multi Touch Reporting',
                        'col' => 0,
                        'row' => '5'
                      },
                      {
                        'cell_format' => {
                                         'align' => 'right',
                                         'bold' => 1
                                       },
                        'text' => [
                                  'Generation Date:',
                                  'Report Type:',
                                  'Date Range:',
                                  'Analysis Window:'
                                ],
                        'col' => 0,
                        'row' => '7'
                      },
                      {
                        'text' => [
                                  '@generation_date',
                                  '@title',
                                  '@start_date - @end_date',
                                  '@window_length days'
                                ],
                        'col' => 1,
                        'row' => '7'
                      }
                    ],
          'start_row' => '10'
        }
  }

Options are as follows:

=over 4

=item * image

Specifies an image (PNG or JPEG) or images to be placed into the spreadsheet.
Multiple images may be inserted by specifying an array of option hashes,
comprising the following keys:

=over 4

=item * row

Optional row number.  Will be placed at the current row if not specified.

=item * col

Optional column number.  Will be placed at column 0 if not specified.

=item * filename

Filename or URL of the image.

=item * x_offset, y_offset

Optional pixel offsets of image from top-left of cell.

=item * x_scale, y_scale

Optional image scaling factors.

=back

=item * header, footer

Specifies formatted rows of text. 'header' is intended to be used for
'header_layout' and 'footer' for 'footer_layout', but it doesn't actually matter
if they are used the other way around.  Multiple rows may be inserted by
specifying an array of option hashes, comprising the following keys:

=over 4

=item * cell_format

See L<CELL FORMAT>.

=item * row

Optional row number.  Will be placed at the current row if not specified.

=item * col

Optional column number.  Will be placed at column 0 if not specified.

=item * rowspan, colspan

Optional row and column spans for merged cells.

=item * text

Lines of text.  If given as an array, each line will be inserted on subsequent
rows, keeping the same formatting options.

Variables may be specified in the text as @variable_name, and will be
substituted.  Valid variable names are the top level keys passed in the report
hash to print().

=back

=item * Any worksheet or page setup method from L<Spreadsheet::WriteExcel>

e.g. keep_leading_zeros, show_comments, set_first_sheet, set_tab_color, hide_gridlines, set_zoom, etc.

Any valid Spreadsheet::WriteExcel worksheet method will be invoked with the given values, i.e.

  hide_gridlines => 1
  print_area => [ 1, 2, 3, 4 ]

invokes $worksheet->hide_gridlines(1) and $worksheet->print_area(1, 2, 3, 4).

=back

=head1 CELL FORMAT

Cell formatting options are defined through a hashref of any text formatting
options from L<Spreadsheet::WriteExcel>; specifically, any of 'font', 'size',
'color', 'bold', 'italic', 'underline', 'font_strikeout', 'font_script',
'font_outline', 'font_shadow', 'num_format', 'locked', 'hidden', 'align',
'valign', 'rotation', 'text_wrap', 'test_justlast', 'center_across', 'indent',
'shrink', 'pattern', 'bg_color', 'fg_color', 'border', 'bottom', 'top', 'left',
'right', 'border_color', 'bottom_color', 'top_color', 'left_color',
'right_color'.

=head1 AUTHOR

Jon Schutz, C<< <jon at jschutz.net> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-www-analytics-multitouch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Analytics-MultiTouch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Analytics::MultiTouch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Analytics-MultiTouch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Analytics-MultiTouch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Analytics-MultiTouch>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Analytics-MultiTouch/>

=back


=head1 COPYRIGHT & LICENSE

 Copyright 2010 YourAmigo Ltd.

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

1;
