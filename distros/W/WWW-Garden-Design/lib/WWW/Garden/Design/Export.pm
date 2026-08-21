package WWW::Garden::Design::Export;

use Moo::Role;

use strict;
use utf8;
use warnings;

use boolean;

use Encode 'encode';

use File::Spec;

use Mojo::Log;

use Sort::Naturally;

use SVG::Grid;

use Text::CSV;
use Text::Xslate 'mark_raw';

use Types::Standard qw/Any Int HashRef Str/;

use WWW::Garden::Design::Database;
use WWW::Garden::Design::Util::Config;

has all =>
(
	default		=> sub{return 'No'},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

has config =>
(
	default		=> sub{WWW::Garden::Design::Util::Config -> new -> config},
	is			=> 'rw',
	isa			=> HashRef,
	required	=> 0,
);

has db =>
(
	is			=> 'rw',
	isa			=> Any,
	required	=> 0,
);

has export_columns =>
(
	default		=> sub{return {} },
	is			=> 'rw',
	isa			=> HashRef,
	required	=> 0,
);

has export_type =>
(
	default		=> sub{return 0},
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

has output_file =>
(
	default		=> sub{return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 1,
);

has property_name =>
(
	default		=> sub{return 'Ron'},
	is			=> 'rw',
	isa			=> Str,
	required	=> 1,
);

has standalone_page =>
(
	default		=> sub{return 0},
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

our $VERSION = '0.97';

# -----------------------------------------------

sub attribute_types2csv
{
	my($self, $csv)				= @_;
	my($attribute_types_table)	= $self -> db -> read_table('attribute_types');
	my($file_name)				= $self -> output_file =~ s/flowers.csv/attribute_types.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	# Column names are in order left-to-right.

	$csv -> combine(qw/name sequence range/);

	print $fh $csv -> string, "\n";

	for my $attribute_type (@$attribute_types_table)
	{
		$csv -> combine
		(
			$$attribute_type{name},
			$$attribute_type{sequence},
			$$attribute_type{range},
		);

		print $fh $csv -> string, "\n";
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of attribute_types2csv.

# -----------------------------------------------

sub attributes2csv
{
	my($self, $csv, $flowers)	= @_;
	my($file_name)				= $self -> output_file =~ s/flowers.csv/attributes.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	# Column names are in order left-to-right.

	$csv -> combine(qw/common_name attribute_name range/);

	print $fh $csv -> string, "\n";

	my($common_name);

	for my $flower (sort{uc($$a{common_name}) cmp uc($$b{common_name})} @$flowers)
	{
		next if ($$flower{publish} eq 'No');

		$common_name = $$flower{common_name};

		for my $attribute (@{$$flower{attributes} })
		{
			$csv -> combine
			(
				$common_name,
				$$attribute{name},
				$$attribute{range},
			);

			print $fh $csv -> string, "\n";
		}
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of attributes2csv.

# -----------------------------------------------

sub as_csv
{
	my($self) = @_;

	die "No output file specified\n" if (! $self -> output_file);

	my($csv)		= Text::CSV -> new({always_quote => 1, binary => 1});
	my($flowers)	= $self -> flowers2csv($csv);

	$self -> attribute_types2csv($csv);
	$self -> attributes2csv($csv, $flowers);
	$self -> constants2csv($csv);
	$self -> images2csv($csv, $flowers);
	$self -> notes2csv($csv, $flowers);
	$self -> urls2csv($csv, $flowers);

	my($features)			= $self -> features2csv($csv);
	my($property_id2name)	= $self -> properties2csv($csv);
	my($garden_id2name)		= $self -> gardens2csv($csv, $property_id2name);

	$self -> flower_locations2csv($csv, $flowers, $property_id2name, $garden_id2name);
	$self -> feature_locations2csv($csv, $features, $property_id2name, $garden_id2name);
	$self -> db -> logger -> info('Finished exporting all CSV files');

	# Return 0 for OK and 1 for error.

	return 0;

}	# End of as_csv.

# -----------------------------------------------

sub as_html
{
	my($self)			= @_;
	my($export_type)	= $self -> export_type;
	my(%columns)		= %{$self -> export_columns};
	my($count)			= 0;
	my($flowers)		= $self -> db -> read_flowers_table;
	my(@heading)		= map{ {td => mark_raw($_)} } sort{$columns{$a}{order} <=> $columns{$b}{order} } keys %columns;
	my($width)			= 40;

	my(@aliases);
	my($column_name);
	my(@fields);
	my(@line);
	my($native, $name);
	my($offset);
	my($thumbnail, @tbody);
	my($text);

	for my $flower (@$flowers)
	{
		next if ($$flower{publish} eq 'No');

		$$flower{count}	= ++$count;
		@aliases		= ();
		@line			= ();

		for (@{$$flower{attributes} })
		{
			$native = $$_{range} if ($$_{name} eq 'Native');
		}

		for my $key (sort{$columns{$a}{order} <=> $columns{$b}{order} } keys %columns)
		{
			$column_name	= $columns{$key}{column_name};
			$name			= ($column_name eq 'native') ? $native : $$flower{$column_name};

			if ($key eq 'Aliases')
			{
				@fields	= split(/\s*,\s*/, $name);
				$text	= '';

				while (my $field = shift @fields)
				{
					if (length($text . $field) > $width)
					{
						push @aliases, $text;

						$text = $field;
					}
					else
					{
						$text .= $text ? ", $field" : $field;
					}
				}

				$text = join(',<br>', @aliases, $text);
			}
			else
			{
				$text = $name;
			}

			push @line, {td => mark_raw($text)};
		}

		$offset			= $#line;
		$line[$offset]	=
			{
				td => mark_raw
				(
					qq|<a href='$$flower{web_page_url}' target = '_blank'><img src='$$flower{thumbnail_url}' alt = "$$flower{scientific_name}"></a>|
				)
			};

		push @tbody, [@line];
	}

	my(@thead)			= [@heading];
	my($constants)		= $self -> db -> read_constants_table;
	my($js4datatable)	= mark_raw($self -> init_datatable);
	my($tx)				= Text::Xslate -> new
	(
		input_layer => '',
		path        => $$constants{template_path},
	);

	return encode('utf-8', $tx -> render
	(
		$self -> standalone_page ? 'standalone.page.tx' : 'basic.table.tx',
		{
			js4datatable	=> $js4datatable,
			thead			=> \@thead,
			tbody			=> \@tbody,
		}
	) );

} # End of as_html.

# -----------------------------------------------

sub constants2csv
{
	my($self, $csv)	= @_;
	my($constants)	= $self -> db -> constants;
	my($file_name)	= $self -> output_file =~ s/flowers.csv/constants.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	# Column names are in order left-to-right.

	$csv -> combine(qw/name value/);

	print $fh $csv -> string, "\n";

	for my $name (sort keys %$constants)
	{
		$csv -> combine
		(
			$name,
			$$constants{$name},
		);

		print $fh $csv -> string, "\n";
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of constants2csv.

# -----------------------------------------------

sub export_all_pages
{
	my($self)					= @_;
	my($attribute_types_table)	= $self -> db -> read_table('attribute_types');
	my($constants)				= $self -> db -> constants;
	my($flowers)				= $self -> db -> read_flowers_table;
	my($target_dir)				= File::Spec -> catfile($$constants{homepage_dir}, $$constants{flower_dir});

	$self -> db -> logger -> info("Export.export_all_pages(). Output directory: $target_dir");

	# Process each flower looking for others with the same prefix.
	# The reason for using common name here is it helps when 2
	# different plants have the same scientific name, such as
	# Plectranthus eklonii.

	my($common_name);
	my(@fields);
	my($id);
	my($pig_latin, $prefix, %prefixes);
	my($scientific_name);

	for my $flower (@$flowers)
	{
		next if ($$flower{publish} eq 'No');

		$common_name		= $$flower{common_name};
		$id					= $$flower{id};
		$scientific_name	= $$flower{scientific_name};
		@fields				= split(/\s+/, $scientific_name);
		$pig_latin			= $$flower{pig_latin};
		$prefix				= $fields[0];
		$prefixes{$prefix}	= [] if (! $prefixes{$prefix});

		push @{$prefixes{$prefix} }, [$id, $pig_latin, "$scientific_name => $common_name"];
	}

	my($tx) = Text::Xslate -> new
	(
		input_layer => '',
		path        => $$constants{template_path},
	);

	my(@attributes, $aliases);
	my(@images);
	my(@links);
	my(@notes);
	my($other_id, $other_pig_latin, $other_common_name);
	my($text);
	my($url, @urls);
	my($web_page_name);

	for my $flower (@$flowers)
	{
		next if ($$flower{publish} eq 'No');

		$aliases			= $$flower{aliases};
		@attributes			= ();
		$common_name		= $$flower{common_name};
		$id					= $$flower{id};
		@images				= ();
		@links				= ();
		@notes				= ();
		$scientific_name	= $$flower{scientific_name};
		$pig_latin			= $$flower{pig_latin};
		@urls				= ();

		# Attributes.

		push @attributes,
		[
			{td => 'Attribute'},
			{td => 'Range'},
		];

		for my $attribute (sort{$$a{sequence} <=> $$b{sequence} } @{$$flower{attributes} })
		{
			push @attributes,
			[
				{td => ucfirst $$attribute{name} },
				{td => $$attribute{range} },
			];
		}

		# Images.

		push @images,
		[
			{td => 'Descriptions'},
			{td => 'Images'},
		];

		for my $item (@{$$flower{images} })
		{
			push @images,
			[
				{td => mark_raw($$item{description})},
				{td => mark_raw("<img src = '$$item{file_name}'>")},
			];
		}

		# Links.

		@fields	= split(/\s+/, $scientific_name);
		$prefix	= $fields[0];

		if ($#{$prefixes{$prefix} } > 0)
		{
			for my $item (@{$prefixes{$prefix} })
			{
				if ($#links < 0)
				{
					push @links, [{td => "Auto-generated links for $scientific_name aka $common_name"}];
				}

				($other_id, $other_pig_latin, $other_common_name) = ($$item[0], $$item[1], $$item[2]);

				if ($other_id != $id)
				{
					push @links, [{td => mark_raw("See also <a href = '/Flowers/$other_pig_latin.html'>$other_common_name</a>")}];
				}
			}
		}

		# Notes.

		for my $note (@{$$flower{notes} })
		{
			$text = $$note{note};

			if ($text =~ /^http/)
			{
				$text = "» <a href = '$text'>$$note{note}</a>";
			}
			else
			{
				$text = "» $text";
			}

			if ($#notes < 0)
			{
				push @notes,
				[
					{td => 'Notes'},
				];
			}

			push @notes,
			[
				{td => mark_raw($text)},
			];
		}

		# URLs.

		for my $url (@{$$flower{urls} })
		{
			if ($#urls < 0)
			{
				push @urls,
				[
					{td => 'URLs'},
				];
			}

			push @urls,
			[
				{td => mark_raw("<a href = '$$url{url}'>$$url{url}</a>")},
			];
		}

		$web_page_name = File::Spec -> catfile($$constants{homepage_dir}, $$constants{flower_dir}, "$pig_latin.html");

		$self -> db -> logger -> info("Writing $web_page_name");

		open(my $fh, '>:encoding(utf-8)', $web_page_name);
		print $fh $tx -> render
					(
						'individual.page.tx',
						{
							aliases			=> $aliases eq '' ? '' : "Aliases: $aliases",
							attributes		=> \@attributes,
							common_name		=> $common_name,
							height			=> $$flower{height} || '-',
							images			=> \@images,
							link_count		=> scalar(@links), # Necessary because Text::Xslate rejects $#$links.
							links			=> \@links,
							note_count		=> scalar(@notes),
							notes			=> \@notes,
							scientific_name	=> $scientific_name,
							title			=> $scientific_name,
							url_count		=> scalar(@urls),
							urls			=> \@urls,
							width			=> $$flower{width} || '-',
						}
					);
		close $fh;
	}

	$self -> db -> logger -> info('Finished exporting all HTML files');

	# Return 0 for OK and 1 for error.

	return 0;

} # End of export_all_pages.

# -----------------------------------------------

sub export_features
{
	my($self)			= @_;
	my($constants)		= $self -> db -> constants;
	my($features_table)	= $self -> db -> read_features_table;
	my($target_dir)		= File::Spec -> catfile($$constants{homepage_dir}, $$constants{flower_dir});

	$self -> db -> logger -> info("Export.export_features(). Output directory: $target_dir");

	my(@file_names);

	for my $feature (sort{$$a{name} cmp $$b{name} } @$features_table)
	{
		next if ($$feature{publish} eq 'No');

		push @file_names, $self -> db -> generate_tile($constants, $feature);
	}

	my(@heading)	= map{ {td => $_} } (qw(Feature Icon) );
	my(@row)		= [@heading];
	my($tx)			= Text::Xslate -> new
	(
		input_layer	=> '',
		path		=> $$constants{template_path},
	);

	for my $item (@file_names)
	{
		push @row, [{td => $$item{name} }, {td => mark_raw("<object data = '$$constants{homepage_url}$$constants{feature_url}/$$item{file_name}.png'></object>")}];
	}

	push @row, [@heading];

	my($file_name) = File::Spec -> catfile($$constants{homepage_dir}, $$constants{feature_dir}, 'features.html');

	open(my $fh, '>', $file_name) || die "Can't open: $file_name: $!\n";
	print $fh $tx -> render
	(
		(
			'garden.features.tx',
			{
				row => \@row,
			}
		)
	);

	close $fh;

	$self -> db -> logger -> info('Finished exporting all features');

	# Return 0 for OK and 1 for error.

	return 0;

} # End of export_features.

# -----------------------------------------------

sub export_garden_layout
{
	my($self, $gardens_table, $garden_name) = @_;

	$self -> db -> logger -> debug("export_garden_layout(). Processing garden '$garden_name'");

	my($constants)		= $self -> db -> constants;
	my($flowers)		= $self -> db -> read_flowers_table;
	my($features)		= $self -> db -> read_features_table;
	my($max_x)			= 0;
	my($max_y)			= 0;
	my($property_found)	= false;
	my($property_name)	= $self -> property_name;
	my($x_offset)		= $$constants{x_offset};
	my($y_offset)		= $$constants{y_offset};

	my(%garden_id2name, %garden_name2id);

	# The calling code checks ($$garden{property_publish} eq 'No') and ($$garden{publish} eq 'No').

	for my $garden (@$gardens_table)
	{
		$garden_name2id{$$garden{name} }	= $$garden{id};
		$garden_id2name{$$garden{id} }		= $$garden{name};

		if ($property_name eq $$garden{property_name})
		{
			$property_found = true;
		}
	}

	die "No such property: $property_name. \n" if (! $property_found);

	my($garden_id) = $garden_name2id{$garden_name};

	my(%feature_name);

	for my $feature (@$features)
	{
		next if ($$feature{publish} eq 'No');

		$feature_name{$$feature{id} } = $$feature{name};
	}

	# 1: Set the parameters.

	my($id);
	my(%location_xy);
	my($x);
	my($y);

	for my $flower (@$flowers)
	{
		next if ($$flower{publish} eq 'No');

		for my $location (@{$$flower{flower_locations} })
		{
			next if ($garden_id2name{$$location{garden_id} } ne $garden_name);

			$id					= $$location{id};
			$x					= $$location{x};
			$y					= $$location{y};
			$max_x				= $x	if ($x > $max_x);
			$max_y				= $y	if ($y > $max_y);
			$location_xy{$id}	= []	if (! $location_xy{$id});

			push @{$location_xy{$id} }, [$x, $y];
		}
	}

	$self -> db -> logger -> info("Max (x, y) after processing 'flower_locations': ($max_x, $max_y)");

	for my $feature (@$features)
	{
		next if ($$feature{publish} eq 'No');

		for my $feature (@{$$feature{feature_locations} })
		{
			next if ($garden_id2name{$$feature{garden_id} } ne $garden_name);

			$x		= $$feature{x};
			$y		= $$feature{y};
			$max_x	= $x	if ($x > $max_x);
			$max_y	= $y	if ($y > $max_y);
		}
	}

	$self -> db -> logger -> info("Max (x, y) after processing 'feature_locations': ($max_x, $max_y)");

	my($x_cell_count)	= $max_x;
	my($y_cell_count)	= $max_y;
	my($grid)			= SVG::Grid -> new
	(
		cell_width		=> $$constants{cell_width},
		cell_height		=> $$constants{cell_height},
		x_cell_count	=> $x_cell_count,
		y_cell_count	=> $y_cell_count,
		x_offset		=> $$constants{x_offset},
		y_offset		=> $$constants{y_offset},
	);

	$grid -> grid(stroke => 'blue');

	# 2: Add the feature locations to the grid.

	my($grid_id);

	for my $item (@$features)
	{
		next if ($$item{publish} eq 'No');

		for my $feature (@{$$item{feature_locations} })
		{
			next if ($garden_id2name{$$feature{garden_id} } ne $garden_name);

			$grid_id = $grid -> svg -> image
			(
				height	=> $$constants{cell_height},
				href	=> $$item{feature_url},
				width	=> $$constants{cell_width},
				x		=> $x_offset + $$constants{cell_width} * $$feature{x}, # Cell co-ord.
				y		=> $y_offset + $$constants{cell_height} * $$feature{y}, # Cell co-ord.
			);
		}
	}

	# 3: Add the flowers to the grid.

	my($pig_latin);
	my(%tool_tips);

	$tool_tips{$garden_id} = {};

	for my $flower (@$flowers)
	{
		next if ($$flower{publish} eq 'No');

		$pig_latin = $$flower{pig_latin};

		for my $location (@{$$flower{flower_locations} })
		{
			next if ($garden_id2name{$$location{garden_id} } ne $garden_name);

			$grid_id = $grid -> image_link
			(
				href	=> $$flower{web_page_url},
				image	=> $$flower{thumbnail_url},
				show	=> 'new', # Converted into -show by SVG::Grid.
				title	=> "$$flower{scientific_name} / $$flower{common_name}",
				x		=> $$location{x}, # Cell co-ord.
				y		=> $$location{y}, # Cell co-ord.
			);

			$tool_tips{$garden_id}{$grid_id} = "$$flower{scientific_name} / $$flower{common_name}";
		}
	}

	# 4: Add some annotations and write the layout SVG.

	$grid -> text
	(
		'font-size'		=> 32,
		'font-weight'	=> '400',
		text			=> "'$property_name - $garden_name Garden'",
		x				=> $grid -> x_offset + 8,		# Pixel co-ord.
		y				=> $grid -> y_offset / 2 + 8,	# Pixel co-ord.
	);
	$grid -> text
	(
		'font-size'		=> 32,
		'font-weight'	=> '400',
		text			=> '--> N',
		x				=> $grid -> width - 2 * $grid -> cell_width,	# Pixel co-ord.
		y				=> $grid -> y_offset / 2,						# Pixel co-ord.
	);
	$grid -> text
	(
		'font-size'		=> 32,
		'font-weight'	=> '400',
		text			=> 'Block size: Width: 11.7m. Height: 46m',
		x				=> $grid -> width - 20 * $grid -> cell_width,	# Pixel co-ord.
		y				=> $grid -> height,							# Pixel co-ord.
	);

	my($file_name) = File::Spec -> catfile($$constants{homepage_dir}, $$constants{flower_dir}, "$garden_name.garden.layout.svg");

	$self -> db -> logger -> info("Writing to $file_name");

	$grid -> write(output_file_name => $file_name);

	# 4: Output some HTML.

	my(@garden_index);

	push @garden_index, <<EOS;
<html>
	<head>
		<title>$property_name - $garden_name Garden Layout</title>
		<meta http-equiv = 'Content-Type' content = 'text/html; charset=utf-8' />
		<link rel = 'stylesheet' type = 'text/css' href = '/assets/css/www/garden/design/homepage.css'>
	</head>
	<body>
		<h1 class = 'centered'><span class = '$$constants{css_class4headings}' id = 'top'>The '$property_name - $garden_name Garden' Layout</span></h1>
		<br />
		<table align = 'center' summary = 'Table for $property_name - $garden_name Garden'>
			<tr><td>Links</td></tr>
EOS

	for my $garden (@$gardens_table)
	{
		# Skip other properties and skip the current garden.

		next if ($self -> property_name ne $$garden{property_name});
		next if ($garden_name eq $$garden{name});

		push @garden_index, <<EOS;
			<tr><td><a href = '$$constants{homepage_url}$$constants{flower_url}/$$garden{name}.garden.layout.html'>The '$property_name - $$garden{name} Garden' Layout</a></td></tr>
EOS
	}

	push @garden_index, <<EOS;
			<tr><td><a href = '$$constants{homepage_url}/Flowers.html'>The Flower Catalog</a></td></tr>
		</table>

		<br />

		<h2 align = 'center'>The '$property_name - $garden_name Garden Layout' (SVG image), with clickable flower thumbnails in situ</h2>

		<table align = 'center' summary = 'Table for $property_name - $garden_name Garden Layout'>
			<tr><td align = 'center'>
				<object data = '$$constants{homepage_url}$$constants{flower_url}/$garden_name.garden.layout.svg'></object>
			</td></tr>
		</table>

		<br />

		<table align = 'center' summary = 'First placeholder for link to top'><tr><td align = 'center'><a href = '#top'>Top</a></td></tr></table>
	</body>
EOS

	# Finally, (in several steps) generate the JS which implements ToolTips activated by MouseOver.

	push @garden_index, <<EOS;

	<script type="text/javascript" src="/assets/js/jQuery/jquery-3.1.1.min.js"></script>
	<script type="text/javascript" src="/assets/js/jQuery/jquery-ui-1.12.1/jquery-ui.min.js"></script>
	<script type="text/javascript">

	var tool_tips = [];
EOS

	my($index) = -1;

	my(@tips);

	for $grid_id (nsort keys %{$tool_tips{$garden_id} })
	{
		$index++;

		# Must use double-quotes in case the common_name contains a single-quote.
		# And we use a stack because <<EOS added an extra \n to every output line :-(.

		push @tips, qq|\ttool_tips[$index] = {id: '$grid_id', text: "$tool_tips{$garden_id}{$grid_id}"};|;
	}

	my($tips) = join("\n", @tips);

	push @garden_index, <<EOS;
$tips

	var id;

	for (var i = 0; i < tool_tips.length; i++)
	{
		id = document.getElementById(tool_tips[i].id);

		\$(id).tooltip({content: tool_tips[i].text, items: 'span'});

		\$(id)
		.mouseenter(function() {
			\$(id).tooltip('open')
		})
		.mouseleave(function() {
			\$(id).tooltip('close')
		});
	}

	</script>
</html>
EOS

	$file_name = File::Spec -> catfile($$constants{homepage_dir}, $$constants{flower_dir}, "$garden_name.garden.layout.html");

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(UTF-8)', $file_name);
	print $fh map{"$_\n"} @garden_index;
	close $fh;

	$self -> db -> logger -> info("Finished exporting garden layout for the '$garden_name' garden");

} # End of export_garden_layout.

# -----------------------------------------------

sub export_layout_guide
{
	my($self)			= @_;
	my($constants)		= $self -> db -> constants;
	my($gardens_table)	= $self -> db -> read_gardens_table; # Warning: Not read_table('gardens').
	my($html)			= '';
	my($property_name)	= $self -> property_name;

	# See ~/backup/face.book.txt and face.book.meta.txt.

	$html .= <<EOS;
<table align = 'center' summary = 'Facebook like button'>
	<tr>
		<td>
			<div id = 'fb-root'></div>
			<script>
				(function(d, s, id)
				{
					var js, fjs = d.getElementsByTagName(s)[0];
					if (d.getElementById(id)) return;
					js = d.createElement(s); js.id = id;
					js.src = '//connect.facebook.net/en_US/sdk.js#xfbml=1';
					fjs.parentNode.insertBefore(js, fjs);
				}(document, 'script', 'facebook-jssdk') );
			</script>

			<!-- Your like button code -->
			<div class = 'fb-like'
				data-action		= 'like'
				data-href		= 'https://savage.net.au/Flowers.html'
				data-layout		= 'standard'
				data-show-faces	='true'>
			</div>
		</td>
	</tr>
</table>
<table align = 'center' summary = 'Table for a list of articles'>
	<tr><td align='center'><br /><span class = '$$constants{css_class4headings}' id = 'articles'>Articles</span></td></tr>
	<tr><td><a href = '$$constants{homepage_url}$$constants{flower_url}/html/Garden.Design.Software.html'>2016-12-29: Garden Design Software</a></td></tr>
	<tr><td><a href = '$$constants{homepage_url}$$constants{flower_url}/html/How.To.Net.Dwarf.Apples.html'>2016-01-03: How To Net Dwarf Apples</a></td></tr>
	<tr><td><a href = '$$constants{homepage_url}$$constants{flower_url}/html/Protecting.Apples.From.Possums.html'>2013-12-08: Protecting Apples From Possums</a></td></tr>
</table>
<br />
<table align = 'center' summary = 'Table for a list of garden layouts'>
	<tr><td align = 'center'><span class = '$$constants{css_class4headings}' id = 'garden_layouts'>The Garden Layouts</span></td></tr>
EOS

	for my $garden (@$gardens_table)
	{
		next if ( ($$garden{property_name} ne $property_name) || ($$garden{property_publish} eq 'No') || ($$garden{publish} eq 'No') );

		$html .= <<EOS;
	<tr><td><a href = '$$constants{homepage_url}$$constants{flower_url}/$$garden{name}.garden.layout.html'>The '$property_name - $$garden{name} Garden' Layout, with clickable flower thumbnails in situ</a></td></tr>
EOS
	}

	$html .= <<EOS;
</table>
<table align = 'center' summary = 'Table for a list of URLs'>
	<tr><td align = 'center'><br /><span class = '$$constants{css_class4headings}' id = 'various_urls'>Various Links</span></td></tr>
	<tr><td><a href = '$$constants{homepage_url}$$constants{flower_url}/flowers.schema.svg'>The database schema</a></td></tr>
	<tr><td><a href = 'https://datatables.net/'>The URL</a> of the free Javascript package which manages the HTML table below</td></tr>
	<tr><td><a href = 'https://github.com/bgrins/spectrum'>The github repo</a> of the free Javascript package which provides a color spectrum...</td></tr>
	<tr><td>... and the corresponding <a href = 'https://bgrins.github.io/spectrum/'>on-line docs</a></td></tr>
	<tr><td><a href = 'http://nurseriesonline.com.au'>Nurseries OnLine - A great Australian website</a></td></tr>
	<tr><td><a href = 'http://www.flowersforums.com/forums/'>Flower Forums - A great place to ask for help</a></td></tr>
	<tr><td><a href = 'http://www.LabourofLoveLandscaping.com'>Some identification assistance kindly provided by Kate Kennedy Butler</a></td></tr>
	<tr><td><a href = 'http://www.theplantlist.org/'>The Plant List - A working list of all plant species</a></td></tr>
	<tr><td><a href = 'http://www.plantnet.org/'>PlantNet - Identify plants via pix</a></td></tr>
</table>
EOS

	return $html;

} # End of export_layout_guide.

# -----------------------------------------------

sub export_layouts
{
	my($self)			= @_;
	my($gardens_table)	= $self -> db -> read_gardens_table; # Warning: Not read_table('gardens').

	for my $garden (@$gardens_table)
	{
		next if ( ($$garden{property_publish} eq 'No') || ($$garden{publish} eq 'No') );

		$self -> export_garden_layout($gardens_table, $$garden{name}) if ($self -> property_name eq $$garden{property_name});
	}

} # End of export_layouts.

# -----------------------------------------------

sub feature_locations2csv
{
	my($self, $csv, $features, $property_id2name, $garden_id2name) = @_;
	my($file_name) = $self -> output_file =~ s/flowers.csv/feature_locations.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	# Column names are in order left-to-right.

	$csv -> combine(qw/name property_name garden_name xy/);

	print $fh $csv -> string, "\n";

	my($feature_name);
	my($garden_name);
	my(%location);
	my($property_name);

	for my $feature (@$features)
	{
		next if ($$feature{publish} eq 'No');

		%location		= ();
		$feature_name	= $$feature{name};

		for my $feature (@{$$feature{feature_locations} })
		{
			$garden_name							= $$garden_id2name{$$feature{garden_id} };
			$property_name							= $$property_id2name{$$feature{property_id} };
			$location{$property_name}				= {} if (! $location{$property_name});
			$location{$property_name}{$garden_name}	= [] if (! $location{$property_name}{$garden_name});

			push @{$location{$property_name}{$garden_name} }, "$$feature{x},$$feature{y}";
		}

		for $property_name (sort keys %location)
		{
			for $garden_name (sort keys %{$location{$property_name} })
			{
				$csv -> combine
				(
					$feature_name,
					$property_name,
					$garden_name,
					join(' ', nsort @{$location{$property_name}{$garden_name} }),
				);

				print $fh $csv -> string, "\n";
			}
		}
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of feature_locations2csv.

# -----------------------------------------------

sub features2csv
{
	my($self, $csv) = @_;
	my($features)	= $self -> db -> read_features_table; # Returns a sorted array ref.
	my($file_name)	= $self -> output_file =~ s/flowers.csv/features.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	# Column names are in order left-to-right.

	$csv -> combine(qw/name hex_color publish/);

	print $fh $csv -> string, "\n";

	for my $feature (@$features)
	{
		next if ($$feature{publish} eq 'No');

		$csv -> combine
		(
			$$feature{name},
			$$feature{hex_color},
			$$feature{publish},
		);

		print $fh $csv -> string, "\n";
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

	return $features;

} # End of features2csv.

# -----------------------------------------------

sub flower_locations2csv
{
	my($self, $csv, $flowers, $property_id2name, $garden_id2name) = @_;
	my($file_name) = $self -> output_file =~ s/flowers.csv/flower_locations.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	# Column names are in order left-to-right.

	$csv -> combine(qw/common_name property_name garden_name xy/);

	print $fh $csv -> string, "\n";

	my($common_name);
	my($garden_name);
	my(%location);
	my($property_name);

	for my $flower (sort{uc($$a{common_name}) cmp uc($$b{common_name})} @$flowers)
	{
		next if ($$flower{publish} eq 'No');

		$common_name	= $$flower{common_name};
		%location		= ();

		for my $location (@{$$flower{flower_locations} })
		{
			$garden_name							= $$garden_id2name{$$location{garden_id} };
			$property_name							= $$property_id2name{$$location{property_id} };
			$location{$property_name}				= {} if (! $location{$property_name});
			$location{$property_name}{$garden_name}	= [] if (! $location{$property_name}{$garden_name});

			push @{$location{$property_name}{$garden_name} }, "$$location{x},$$location{y}",
		}

		for $property_name (sort keys %location)
		{
			for $garden_name (sort keys %{$location{$property_name} })
			{
				$csv -> combine
				(
					$common_name,
					$property_name,
					$garden_name,
					join(' ', nsort @{$location{$property_name}{$garden_name} }),
				);

				print $fh $csv -> string, "\n";
			}
		}
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of flower_locations2csv.

# -----------------------------------------------

sub flowers2csv
{
	my($self, $csv)		= @_;
	my($flowers)		= $self -> db -> read_flowers_table;
	my($output_file)	= $self -> output_file;

	$self -> db -> logger -> info("Writing to $output_file");

	open(my $fh, '>:encoding(utf-8)', $output_file) || die "Can't open(> $output_file): $!";

	# Column names are in order left-to-right.

	$csv -> combine(qw/common_name scientific_name aliases height width publish/);

	print $fh $csv -> string, "\n";

	for my $flower (sort{uc($$a{common_name}) cmp uc($$b{common_name})} @$flowers)
	{
		next if ($$flower{publish} eq 'No');

		$csv -> combine
		(
			$$flower{common_name},
			$$flower{scientific_name},
			$$flower{aliases},
			$$flower{height},
			$$flower{width},
			$$flower{publish},
		);

		print $fh $csv -> string, "\n";
	}

	close($fh);

	$self -> db -> logger -> info("Wrote $output_file");

	return $flowers;

} # End of flowers2csv.

# -----------------------------------------------

sub gardens2csv
{
	my($self, $csv, $property_id2name)	= @_;
	my($file_name)						= $self -> output_file =~ s/flowers.csv/gardens.csv/r;
	my($garden_table)					= $self -> db -> read_table('gardens');

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	# Column names are in order left-to-right.

	$csv -> combine(qw/property_name garden_name description publish/);

	print $fh $csv -> string, "\n";

	my(%garden_id2name);

	for my $garden (sort{$$a{name} cmp $$b{name} } @$garden_table)
	{
		next if ($$garden{publish} eq 'No');

		$garden_id2name{$$garden{id} } = $$garden{name};

		$csv -> combine
		(
			$$property_id2name{$$garden{property_id} },
			$$garden{name},
			$$garden{description},
			$$garden{publish},
		);

		print $fh $csv -> string, "\n";
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

	return \%garden_id2name;

} # End of gardens2csv.

# -----------------------------------------------

sub images2csv
{
	my($self, $csv, $flowers)	= @_;
	my($file_name)				= $self -> output_file =~ s/flowers.csv/images.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	# Column names are in order left-to-right.

	$csv -> combine(qw/common_name description file_name/);

	print $fh $csv -> string, "\n";

	my($common_name);

	for my $flower (sort{uc($$a{common_name}) cmp uc($$b{common_name})} @$flowers)
	{
		next if ($$flower{publish} eq 'No');

		$common_name = $$flower{common_name};

		for my $item (sort{$$a{flower_id} cmp $$b{flower_id} } @{$$flower{images} })
		{
			$csv -> combine
			(
				$common_name,
				$$item{description},
				$$item{raw_name}, # We don't want the whole domain/url!
			);

			print $fh $csv -> string, "\n";
		}
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of images2csv.

# -----------------------------------------------

sub init_export
{
	my($self)				= @_;
	my($export_type)		= $self -> export_type;
	my($standalone_page)	= $self -> standalone_page;
	my($all)				= $self -> all;

	if ($all !~ /^(?:No|Yes)$/i)
	{
		die "The 'all' flag must be Yes or No'\n";
	}

	# Warning: The line in web.site.xml which runs this script must not use command line options.
	# That means, that whatever options that code needs must be the defaults.

	$self -> export_columns
	({
		'Native' =>
			{
				column_name	=> 'native',
				order		=> 2, # The value 1 is not used.
			},
		'Scientific name' =>
			{
				column_name	=> 'scientific_name',
				order		=> 3,
			},
		'Common name' =>
			{
				column_name	=> 'common_name',
				order		=> 4,
			},
		'Aliases' =>
			{
				column_name	=> 'aliases',
				order		=> 5,
			},
		'Thumbnail <span class = "index">(clickable)</span>' =>
			{
				column_name	=> 'thumbnail_file_name',
				order		=> 6,
			},
	});

	if ($export_type < 0)
	{
		$self -> export_type(0);
	}
	elsif ($export_type > 1)
	{
		$self -> export_type(1);
	}

	if ($standalone_page < 0)
	{
		$self -> standalone_page(0);
	}
	elsif ($standalone_page > 1)
	{
		$self -> standalone_page(1);
	}


}	# End of init_export.

# -----------------------------------------------

sub notes2csv
{
	my($self, $csv, $flowers)	= @_;
	my($file_name)				= $self -> output_file =~ s/flowers.csv/notes.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	# Column names are in order left-to-right.

	$csv -> combine(qw/common_name note/);

	print $fh $csv -> string, "\n";

	my($common_name);

	for my $flower (sort{uc($$a{common_name}) cmp uc($$b{common_name})} @$flowers)
	{
		next if ($$flower{publish} eq 'No');

		$common_name = $$flower{common_name};

		for my $note (sort{$$a{flower_id} cmp $$b{flower_id} } @{$$flower{notes} })
		{
			$csv -> combine
			(
				$common_name,
				$$note{note},
			);

			print $fh $csv -> string, "\n";
		}
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of notes2csv.

# -----------------------------------------------

sub properties2csv
{
	my($self, $csv)		= @_;
	my($property_table)	= $self -> db -> read_table('properties');
	my($file_name)		= $self -> output_file =~ s/flowers.csv/properties.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	# Column names are in order left-to-right.

	$csv -> combine(qw/name description publish/);

	print $fh $csv -> string, "\n";

	my(%property_id2name);

	for my $row (sort{uc($$a{name}) cmp uc($$b{name})} @$property_table)
	{
		next if ($$row{publish} eq 'No');

		$property_id2name{$$row{id} } = $$row{name};

		$csv -> combine
		(
			$$row{name},
			$$row{description},
			$$row{publish}
		);

		print $fh $csv -> string, "\n";
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

	return \%property_id2name;

} # End of properties2csv.

# -----------------------------------------------

sub urls2csv
{
	my($self, $csv, $flowers)	= @_;
	my($file_name)				= $self -> output_file =~ s/flowers.csv/urls.csv/r;

	$self -> db -> logger -> info("Writing to $file_name");

	open(my $fh, '>:encoding(utf-8)', $file_name) || die "Can't open(> $file_name): $!";

	# Column names are in order left-to-right.

	$csv -> combine(qw/common_name url/);

	print $fh $csv -> string, "\n";

	my($common_name);

	for my $flower (sort{uc($$a{common_name}) cmp uc($$b{common_name})} @$flowers)
	{
		next if ($$flower{publish} eq 'No');

		$common_name = $$flower{common_name};

		for my $url (sort{$$a{flower_id} cmp $$b{flower_id} } @{$$flower{urls} })
		{
			$csv -> combine
			(
				$common_name,
				$$url{url},
			);

			print $fh $csv -> string, "\n";
		}
	}

	close $fh;

	$self -> db -> logger -> info("Wrote $file_name");

} # End of urls2csv.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Garden::Design::Export - Manage the 'flowers' database

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/WWW-Garden-Design>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW::Garden::Design>.

=head1 Author

L<WWW::Garden::Design> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2014.

My homepage: L<https://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2018, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
