package WWW::Garden::Design::Import;

use Moo::Role;

use 5.30.0;
use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use File::Slurper qw/read_text/;
use File::Spec;

use FindBin;

use Text::CSV::Encoded;

use Types::Standard qw/Any HashRef/;

has crossref_locations =>
(
	default		=> sub{ return {} },
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

our $VERSION = '0.97';

# -----------------------------------------------

sub populate_all_tables
{
	my($self) = @_;

	$self -> db -> logger -> debug('Populating all tables');

	my($path) = File::Spec -> catfile($FindBin::Bin, '..', 'data', 'flowers.csv');
	my($csv)  = Text::CSV::Encoded -> new
	({
		allow_whitespace => 1,
		encoding_in      => 'utf-8',
	});

	my(%attribute_type_keys);
	my(%flower_keys, %feature_keys);
	my(%garden_keys);
	my(%property_keys);

	$self -> populate_attribute_types_table($path, $csv, \%attribute_type_keys);
	$self -> populate_constants_table($path, $csv);
	$self -> populate_flowers_table($path, $csv, \%flower_keys);
	$self -> populate_properties_table($path, $csv, \%property_keys);
	$self -> populate_gardens_table($path, $csv, \%garden_keys, \%property_keys);
	$self -> populate_flower_locations_table($path, $csv, \%flower_keys, \%property_keys, \%garden_keys);
	$self -> populate_features_table($path, $csv, \%feature_keys);
	$self -> populate_feature_locations_table($path, $csv, \%property_keys, \%garden_keys, \%feature_keys);
	$self -> populate_attributes_table($path, $csv, \%attribute_type_keys, \%flower_keys);
	$self -> populate_notes_table($path, $csv, \%flower_keys);
	$self -> populate_images_table($path, $csv, \%flower_keys);
	$self -> populate_urls_table($path, $csv, \%flower_keys);

	# Return 0 for OK and 1 for error.

	return 0;

}	# End of populate_all_tables.

# -----------------------------------------------

sub populate_attributes_table
{
	my($self, $path, $csv, $attribute_type_keys, $flower_keys) = @_;
	my($table_name) = 'attributes';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		# Column names are tested in alphabetical order.

		for my $column (qw/attribute_name common_name range/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		if (! defined $$attribute_type_keys{$$item{attribute_name} })
		{
			$self -> db -> logger -> error("$table_name. Row: $count. Attribute name '$$item{attribute_name}' undefined");
		}

		if (! defined $$flower_keys{$$item{common_name} })
		{
			$self -> db -> logger -> error("$table_name. Row: $count. Common name '$$item{common_name}' undefined");
		}

		$self -> db -> insert_hashref
		(
			$table_name,
			{
				attribute_type_id	=> $$attribute_type_keys{$$item{attribute_name} },
				flower_id			=> $$flower_keys{$$item{common_name} },
				range				=> $$item{range},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_attributes_table.

# -----------------------------------------------

sub populate_attribute_types_table
{
	my($self, $path, $csv, $attribute_type_keys) = @_;
	my($table_name) = 'attribute_types';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		# Column names are tested in alphabetical order.

		for my $column (qw/name range sequence/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		$$attribute_type_keys{$$item{name} } = $self -> db -> insert_hashref
		(
			$table_name,
			{
				name		=> $$item{name},
				range		=> $$item{range},
				sequence	=> $$item{sequence},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_attribute_types_table.

# -----------------------------------------------

sub populate_constants_table
{
	my($self, $path, $csv) = @_;
	my($table_name) = 'constants';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		# Column names are tested in alphabetical order.

		for my $column (qw/name value/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		$self -> db -> insert_hashref
		(
			$table_name,
			{
				name	=> $$item{name},
				value	=> $$item{value},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_constants_table.

# -----------------------------------------------

sub populate_feature_locations_table
{
	my($self, $path, $csv, $property_keys, $garden_keys, $feature_keys) = @_;
	my($table_name) = 'feature_locations';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($crossref_locations)	= $self -> crossref_locations;
	my($count)				= 0;
	my($max_x)				= 0;
	my($max_y)				= 0;

	my($feature_name);
	my($garden_name);
	my($property_name);
	my($tenant, $tenant_name, $type);
	my(@xy, $x, $xy_pair);
	my($y);

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		# Column names are tested in alphabetical order.

		for my $column (qw/property_name garden_name name xy/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		next if (length($$item{xy}) == 0);

		$feature_name	= $$item{name};
		$garden_name	= $$item{garden_name};
		$property_name	= $$item{property_name};
		@xy				= split(/\s/, $$item{xy});

		for my $i (0 .. $#xy)
		{
			$xy_pair	= $xy[$i];
			($x, $y)	= split(/,/, $xy_pair);
			$max_x		= $x if ($x > $max_x);
			$max_y		= $y if ($y > $max_y);

			if (defined $$crossref_locations{$xy_pair})
			{
				$tenant = $$crossref_locations{$xy_pair};

				if ( ($property_name eq $$tenant{property_name}) && ($garden_name eq $$tenant{garden_name}) )
				{
					$type			= $$tenant{type};
					$tenant_name	= ($type eq 'Flower') ? $$tenant{common_name} : $feature_name;

					$self -> db -> logger -> error("$table_name. Row: $count. Property name: $property_name. "
						. "Garden name: $garden_name. Feature '$feature_name'. "
						. "Feature location '$xy_pair' is already in use by '$tenant_name'");
				}
			}

			$$crossref_locations{$xy_pair} =
			{
				feature_name	=> $feature_name,
				garden_name		=> $garden_name,
				property_name	=> $property_name,
				type			=> 'Feature', # 'Flower' is checked above.
			};

			$self -> db -> insert_hashref
			(
				$table_name,
				{
					feature_id	=> $$feature_keys{$feature_name},
					garden_id	=> $$garden_keys{$garden_name},
					property_id	=> $$property_keys{$property_name},
					x			=> $x,
					y			=> $y,
				}
			);
		}
	}

	close $io;

	$self -> db -> logger -> info("Max (x, y) = ($max_x, $max_y)");
	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_feature_locations_table.

# -----------------------------------------------

sub populate_features_table
{
	my($self, $path, $csv, $feature_keys) = @_;
	my($table_name) = 'features';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		# Column names are tested in alphabetical order.

		for my $column (qw/hex_color name publish/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		$$feature_keys{$$item{name} } = $self -> db -> insert_hashref
		(
			$table_name,
			{
				hex_color	=> $$item{hex_color},
				name		=> $$item{name},
				publish		=> $$item{publish},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_features_table.

# -----------------------------------------------

sub populate_flower_locations_table
{
	my($self, $path, $csv, $flower_keys, $property_keys, $garden_keys) = @_;
	my($table_name) = 'flower_locations';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count)				= 0;
	my($crossref_locations)	= {};
	my($max_x)				= 0;
	my($max_y)				= 0;

	my($common_name);
	my($garden_name);
	my($property_name);
	my($tenant);
	my(@xy, $x, $xy_pair);
	my($y);

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		# Column names are tested in alphabetical order.

		for my $column (qw/common_name property_name garden_name xy/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		next if ( (! defined($$item{xy}) ) || (length($$item{xy}) == 0 ));

		$common_name	= $$item{common_name};
		$garden_name	= $$item{garden_name};
		$property_name	= $$item{property_name};

		if (! defined $$flower_keys{$$item{common_name} })
		{
			$self -> db -> logger -> error("$table_name. Row: $count. Common name '$common_name' undefined");

			next;
		}

		if (! defined $$garden_keys{$garden_name})
		{
			$self -> db -> logger -> error("$table_name. Row: $count. Garden '$garden_name' undefined");

			next;
		}

		if (! defined $$property_keys{$property_name})
		{
			$self -> db -> logger -> error("$table_name. Row: $count. Property '$property_name' undefined");

			next;
		}

		@xy = split(/\s/, $$item{xy});

		for my $i (0 .. $#xy)
		{
			$xy_pair	= $xy[$i];
			($x, $y)	= split(/,/, $xy_pair);
			$max_x		= $x if ($x > $max_x);
			$max_y		= $y if ($y > $max_y);

			if (defined $$crossref_locations{$xy_pair})
			{
				$tenant = $$crossref_locations{$xy_pair};

				# No need to check 'type' because we called this method before calling the code
				# which reads in the feature locations.

				if ( ($property_name eq $$tenant{property_name}) && ($garden_name eq $$tenant{garden_name}) )
				{
					$self -> db -> logger -> error("$table_name. Row: $count. Property name: $property_name. "
						. "Garden name: $garden_name. Common name '$common_name'. "
						. "Flower location '$xy_pair' is already in use by '$$tenant{common_name}'");
				}
			}

			$$crossref_locations{$xy_pair} =
			{
				common_name		=> $common_name,
				garden_name		=> $garden_name,
				property_name	=> $property_name,
				type			=> 'Flower', # Or 'Feature'. These are checked later.
			};

			$self -> db -> insert_hashref
			(
				$table_name,
				{
					flower_id	=> $$flower_keys{$common_name},
					garden_id	=> $$garden_keys{$garden_name},
					property_id	=> $$property_keys{$property_name},
					x			=> $x,
					y			=> $y,
				}
			);
		}
	}

	close $io;

	$self -> crossref_locations($crossref_locations);

	$self -> db -> logger -> info("Max (x, y) = ($max_x, $max_y)");
	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_flower_locations_table.

# -----------------------------------------------

sub populate_flowers_table
{
	my($self, $path, $csv, $flower_keys) = @_;
	my($table_name) = 'flowers';

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count)	= 0;
	my($lines)	= $csv -> getline_hr_all($io);

	# Stockpile some info we'll need. In particular we need %scientific_name
	# so we can generate the pig_latin column in the flowers table.

	my($common_name, %common_name);
	my($max_height, $min_height, $max_width, $min_width);
	my($scientific_name, %scientific_name);

	for my $item (@$lines)
	{
		$count++;

		# Column names are tested in alphabetical order.

		for my $column (qw/aliases common_name height kind max_height max_width min_height min_width pig_latin planted publish scientific_name thumbnail width/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
			elsif ( ($column !~ /height|width/) && (length $$item{$column} == 0) )
			{
				$$item{$column} = '-';
			}
		}

		$common_name		= $$item{common_name};
		$scientific_name	= $$item{scientific_name};

		if ($common_name{$common_name})
		{
			$self -> db -> logger -> info("$table_name. Row: $count. Duplicate common_name: $common_name");
		}

		if ($scientific_name{$scientific_name})
		{
			$self -> db -> logger -> warn("$table_name. Row: $count. Duplicate scientific_name: $scientific_name");
		}

		$common_name{$common_name}			= 0 if (! $common_name{$common_name});
		$common_name{$common_name}			+= 1;
		$scientific_name{$scientific_name}	= 0 if (! $scientific_name{$scientific_name});
		$scientific_name{$scientific_name}	+= 1;
	}

	my($pig_latin);

	for my $item (@$lines)
	{
		$common_name				= $$item{common_name};
		$scientific_name			= $$item{scientific_name};
		$pig_latin					= $self -> db -> scientific_name2pig_latin($lines, $scientific_name, $common_name);
		($max_height, $min_height)	= $self -> validate_size($table_name, $count, lc $self -> db -> trim($$item{height}), lc $self -> db -> trim($$item{height}) );
		($max_width, $min_width)	= $self -> validate_size($table_name, $count, lc $self -> db -> trim($$item{width}), lc $self -> db -> trim($$item{width}) );

#	qw/aliases common_name height kind max_height max_width min_height min_width pig_latin planted publish scientific_name thumbnail width/;

		$$flower_keys{$common_name}	= $self -> db -> insert_hashref
		(
			$table_name,
			{
				aliases			=> $$item{aliases},
				common_name		=> $common_name,
				height			=> $$item{height},
				kind			=> $$item{kind},
				max_height		=> $max_height,
				min_height		=> $min_height,
				max_width		=> $max_width,
				min_width		=> $min_width,
				pig_latin		=> $pig_latin,
				planted			=> $$item{planted},
				publish			=> $$item{publish},
				scientific_name	=> $scientific_name,
				thumbnail		=> $$item{thumbnail},
				width			=> $$item{width},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_flowers_table.

# -----------------------------------------------

sub populate_gardens_table
{
	my($self, $path, $csv, $garden_keys, $property_keys) = @_;
	my($table_name) = 'gardens';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count)	= 0;
	my($max_x)	= 0;
	my($max_y)	= 0;

	my(@xy, $x);
	my($y);

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		# Column names are tested in alphabetical order.

		for my $column (qw/garden_name description property_name publish/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		$$garden_keys{$$item{garden_name} } = $self -> db -> insert_hashref
		(
			$table_name,
			{
				description	=> $$item{description},
				name		=> $$item{garden_name},
				property_id	=> $$property_keys{$$item{property_name} },
				publish		=> $$item{publish},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_gardens_table.

# -----------------------------------------------

sub populate_images_table
{
	my($self, $path, $csv, $flower_keys) = @_;
	my($table_name) = 'images';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		# Column names are tested in alphabetical order.

		for my $column (qw/common_name description file_name/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		if (! defined $$flower_keys{$$item{common_name} })
		{
			$self -> db -> logger -> error("$table_name. Row: $count. Common name '$$item{common_name}' undefined");

			next;
		}

		$self -> db -> insert_hashref
		(
			$table_name,
			{
				flower_id	=> $$flower_keys{$$item{common_name} },
				description	=> $$item{description},
				file_name	=> $$item{file_name},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_images_table.

# -----------------------------------------------

sub populate_notes_table
{
	my($self, $path, $csv, $flower_keys) = @_;
	my($table_name) = 'notes';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		# Column names are tested in alphabetical order.

		for my $column (qw/common_name note/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		if (! defined $$flower_keys{$$item{common_name} })
		{
			$self -> db -> logger -> error("$table_name. Row: $count. Common name '$$item{common_name}' undefined");

			next;
		}

		$self -> db -> insert_hashref
		(
			$table_name,
			{
				flower_id	=> $$flower_keys{$$item{common_name} },
				note		=> $$item{note},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_notes_table.

# -----------------------------------------------

sub populate_properties_table
{
	my($self, $path, $csv, $property_keys) = @_;
	my($table_name) = 'properties';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count)	= 0;
	my($max_x)	= 0;
	my($max_y)	= 0;

	my(@xy, $x);
	my($y);

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		# Column names are tested in alphabetical order.

		for my $column (qw/description name/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		$$property_keys{$$item{name} } = $self -> db -> insert_hashref
		(
			$table_name,
			{
				description	=> $$item{description},
				name		=> $$item{name},
				publish		=> $$item{publish},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_properties_table.

# -----------------------------------------------

sub populate_urls_table
{
	my($self, $path, $csv, $flower_keys) = @_;
	my($table_name) = 'urls';
	$path           =~ s/flowers/$table_name/;

	open(my $io, '<', $path) || die "Can't open($path): $!\n";

	$csv -> column_names($csv -> getline($io) );

	my($count) = 0;

	for my $item (@{$csv -> getline_hr_all($io) })
	{
		$count++;

		# Column names are tested in alphabetical order.

		for my $column (qw/common_name url/)
		{
			if (! defined $$item{$column})
			{
				$self -> db -> logger -> error("$table_name. Row: $count. Column $column undefined");
			}
		}

		if (! defined $$flower_keys{$$item{common_name} })
		{
			$self -> db -> logger -> error("$table_name. Row: $count. Common name '$$item{common_name}' undefined");

			next;
		}

		$self -> db -> insert_hashref
		(
			$table_name,
			{
				flower_id	=> $$flower_keys{$$item{common_name} },
				url			=> $$item{url},
			}
		);
	}

	close $io;

	$self -> db -> logger -> info("Read $count records into '$table_name'");

}	# End of populate_urls_table.

# -----------------------------------------------

sub validate_size
{
	my($self, $table_name, $count, $value) = @_;
	my($max_value)	= '';
	my($min_value)	= '';

	if ($value ne '')
	{
		my($unit) = '';

		if ($value =~ /^([0-9]{0,3}(?:[.][0-9]{0,2})?)\s*-\s*([0-9]{0,3}(?:[.][0-9]{0,2})?)\s*(cm|m)$/)
		{
			$max_value	= $2;
			$min_value	= $1;
			$unit		= $3;
		}
		elsif ($value =~ /^([0-9]{0,3}(?:[.][0-9]{0,2})?)\s*(cm|m)$/)
		{
			$max_value	= $1;
			$min_value	= $1;
			$unit		= $2;
		}
		else
		{
			$self -> db -> logger -> info("$table_name. Row: $count. Cannot interpret <$value> as height or width");
		}

		if ($unit eq 'm')
		{
			# Format as whole cd, i. e. with no decimal places.

			$max_value = sprintf('%.0f', $max_value * 100);
			$min_value = sprintf('%.0f', $min_value * 100);
		}
	}

	return ($max_value, $min_value);

} # End of validate_size.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Garden::Design::Import - Manage the 'flowers' database

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
