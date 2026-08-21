package WWW::Garden::Design;

use utf8; # See $$defaults{joiner} below.

use Mojo::Base 'Mojolicious';

use Data::Dumper::Concise; # For Dumper().

use Moo;

use WWW::Garden::Design::Database::Pg;

our $VERSION = '0.97';

# -----------------------------------------------

sub build_attribute_ids
{
	my($self, $kind, $attribute_type_fields, $attribute_type_names) = @_;

	my($id);
	my($name);

	return
	[
		map
		{
			$name = $$attribute_type_names[$_];
			[
				map
				{
					$id = "${kind}_${name}_$_" =~ s/ /_/gr;
					$id	=~ s/-/_/g;

					$id;
				} @{$$attribute_type_fields{$name} }
			]
		} 0 .. $#$attribute_type_names
	];

} # End of build_attribute_ids.

# -----------------------------------------------

sub build_attribute_type_fields
{
	my($self, $attribute_types_table) = @_;

	my(%attribute_type_fields);

	for (sort{$$a{sequence} <=> $$b{sequence} } @$attribute_types_table)
	{
		$attribute_type_fields{$$_{name} } = [split(/\s*,\s+/, $$_{range})];
	}

	return \%attribute_type_fields;

} # End of build_attribute_type_fields.

# -----------------------------------------------

sub build_attribute_type_names
{
	my($self, $attribute_types_table) = @_;

	my(@fields);
	my($name);

	return [map{$$_{name} } sort{$$a{sequence} <=> $$b{sequence} } @$attribute_types_table];

} # End of build_attribute_type_names.

# -----------------------------------------------
#	attributes['Native']		= ['No', 'Yes', 'Unknown'];
#	attributes['Sun tolerance']	= ['Full_sun', 'Part_shade', 'Shade', 'Unknown'];

sub build_js_for_attributes
{
	my($self, $type_names, $type_fields)	= @_;
	my($attribute_elements)					= "\tvar attributes = new Object;\n\n";

	my($temp_name);

	for my $type_name (sort @$type_names)
	{
		$temp_name			= $type_name =~ s/ /_/gr;
		$attribute_elements	.= "\tattributes['$temp_name'] = ["
								. join(', ', map{"'$_'"} @{$$type_fields{$type_name} })
								. "];\n";
	}

	return $attribute_elements;

} # End of build_js_for_attributes.

# ------------------------------------------------

sub initialize_defaults
{
	my($self)							= @_;
	my($defaults)						= {};
	$$defaults{db}						= WWW::Garden::Design::Database::Pg -> new(logger => $self -> app -> log);
	$$defaults{constants_table}			= $$defaults{db} -> read_constants_table; # Warning: Not read_table('constants').
	$$defaults{attributes_table}		= $$defaults{db} -> read_table('attributes');
	$$defaults{attribute_types_table}	= $$defaults{db} -> read_table('attribute_types');
	$$defaults{attribute_type_names}	= $self -> build_attribute_type_names($$defaults{attribute_types_table});
	$$defaults{attribute_type_fields}	= $self -> build_attribute_type_fields($$defaults{attribute_types_table});
	$$defaults{attribute_attribute_ids}	= $self -> build_attribute_ids('attribute', $$defaults{attribute_type_fields}, $$defaults{attribute_type_names});
	$$defaults{attribute_elements}		= $self -> build_js_for_attributes($$defaults{attribute_type_names}, $$defaults{attribute_type_fields});
	$$defaults{features_table}			= $$defaults{db} -> read_features_table;	# Warning: Not read_table('features').
	$$defaults{gardens_table}			= $$defaults{db} -> read_gardens_table;	# Warning: Not read_table('gardens').
	$$defaults{joiner}					= '«»'; # Used in homepage.html.ep.
	$$defaults{properties_table}		= $$defaults{db} -> read_table('properties');
	$$defaults{search_attribute_ids}	= $self -> build_attribute_ids('search', $$defaults{attribute_type_fields}, $$defaults{attribute_type_names});
	my($attribute_elements)				= $self -> build_js_for_attributes($$defaults{attribute_type_names}, $$defaults{attribute_type_fields});

	# Warning: build_gardens_property_menu() sets a value in the session read by build_garden_menu(),
	# so it must be called first.
	#
	# A note on the property menus on the Gardens tab:
	# o gardens_property_menu_1 => Properties which have gardens.
	# o gardens_property_menu_2 => All properties, since any property is allowed to have gardens added.
	# Also, when a new property is added, only the latter menu gets updated (on the Gardens page).
	# And when a garden is added, the gardens_garden_menu menu is updated (on the Gardens page),
	# as well as the garden menu on the Design page, i.e. the design_garden_menu.

	$$defaults{properties_property_menu}	= $$defaults{db} -> build_properties_property_menu($$defaults{properties_table}, 'properties_property_menu', 0);
	$$defaults{design_property_menu}		= $$defaults{db} -> build_gardens_property_menu($self, $$defaults{gardens_table}, 'design_property_menu', 0);
	$$defaults{design_garden_menu}			= $$defaults{db} -> build_garden_menu($self, $$defaults{gardens_table}, 'design_garden_menu');
	$$defaults{feature_menu}				= $$defaults{db} -> build_feature_menu($$defaults{features_table}, 0);
	$$defaults{gardens_property_menu_1}		= $$defaults{db} -> build_gardens_property_menu($self, $$defaults{gardens_table}, 'gardens_property_menu_1', 0);
	$$defaults{gardens_property_menu_2}		= $$defaults{db} -> build_properties_property_menu($$defaults{properties_table}, 'gardens_property_menu_2', 0);
	$$defaults{gardens_garden_menu}			= $$defaults{db} -> build_garden_menu($self, $$defaults{gardens_table}, 'gardens_garden_menu');

	$self -> app -> defaults($defaults);

	# Find the id of the 1st property on the Properties tab.
	# This is needed to initialize a JS variable of the same name,
	# and the corresponding JS variable of the 2nd property menu on the Gardens tab.
	# And we sort the properties because the property menu is sorted, and we default to the 1st item.

	@{$$defaults{properties_table} } 			= sort{$$a{name} cmp $$b{name} } @{$$defaults{properties_table} };
	$$defaults{properties_current_property_id}	= $$defaults{properties_table}[0]{id};

	# Find the id of the 1st garden on the Gardens tab. It is sorted in Database.read_gardens_table().

	$$defaults{gardens_current_garden_id}		= $$defaults{gardens_table}[0]{id};
	$$defaults{gardens_current_property_id_1}	= $$defaults{gardens_table}[0]{property_id};

	# Find the id of the 1st feature on the Features tab.

	$$defaults{features_current_feature_id} = $$defaults{features_table}[0]{id};

	$self -> defaults($defaults);

	#$self -> app -> log -> debug("properties_current_property_id: $$defaults{properties_current_property_id}");
	#$self -> app -> log -> debug("gardens_current_property_id_1: $$defaults{gardens_current_property_id_1}");
	#$self -> app -> log -> debug("gardens_current_garden_id: $$defaults{gardens_current_garden_id}");
	#$self -> app -> log -> debug("features_current_feature_id: $$defaults{features_current_feature_id}");

} # End of initialize_defaults.

# ------------------------------------------------
# This method will run once at server start.

sub startup
{
	my $self = shift;

	$self -> secrets(['757d76331dc264f21ae97b861189bd9d8aa74647']);

	# Log a special line to make the start of each request easy to find in the log.
	# Of course, nothing is logged by this just because the server restarted.

	$self -> hook
	(
		before_dispatch =>
		sub
		{
			$self -> app -> log -> info('-' x 30);
		}
	);

	# Documentation browser under '/perldoc'.

	$self -> plugin('ServerStatus' =>
				{
					allow       => ['127.0.0.1'],
					counterfile => '/tmp/mojolicious/counter.flowers.txt',
					path        => '/server-status',
					scoreboard  => '/tmp/mojolicious',
				});
	$self -> plugin('TagHelpers');
	$self -> initialize_defaults; # For access inside all controllers.

	# Router.

	my($r) = $self -> routes;

	$r -> namespaces(['WWW::Garden::Design::Controller']);

	$r -> route('/')							-> to('Initialize#homepage');
	$r -> route('/AutoComplete')				-> to('AutoComplete#display');
	$r -> route('/Design')						-> to('Design#process');
	$r -> route('/Feature')						-> to('Feature#process');
	$r -> route('/Flower')						-> to('Flower#process');
	$r -> route('/Garden')						-> to('Garden#process');
	$r -> route('/GetFlowerDetails')			-> to('GetFlowerDetails#display');
	$r -> route('/GetTable/attribute_types')	-> to('GetTable#attribute_types');
	$r -> route('/GetTable/design_flower')		-> to('GetTable#design_flower');
	$r -> route('/GetTable/design_feature')		-> to('GetTable#design_feature');
	$r -> route('/GetTable/gardens')			-> to('GetTable#gardens');
	$r -> route('/GetTable/features')			-> to('GetTable#features');
	$r -> route('/GetTable/properties')			-> to('GetTable#properties');
	$r -> route('/Property')					-> to('Property#process');
	$r -> route('/Report/activity')				-> to('Report#activity');
	$r -> route('/Report/crosscheck')			-> to('Report#crosscheck');
	$r -> route('/Search')						-> to('Search#display');

} # End of startup.

# ------------------------------------------------

1;

=pod

=encoding utf8

=head1 NAME

WWW::Garden::Design - Flower Database, Search Engine and Garden Design

=head1 Synopsis

The Search Engine is started by the Mojolicious command scripts/start.sh:

	#!/bin/bash

	cp /dev/null log/development.log

	scripts/flowers daemon -clients 2 -listen http://*:3008 &

Which runs scripts/hypnotoad.pl:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use FindBin;
	BEGIN { unshift @INC, "$FindBin::Bin/../lib" }

	# Start command line interface for application
	require Mojolicious::Commands;
	Mojolicious::Commands->start_app('WWW::Garden::Design');

=head1 Description

An L<article|https://savage.net.au/Flowers/html/Garden.Design.Software.html> about the package is
on-line.

C<WWW::Garden::Design> provides:

=over 4

=item o A Flower Database stored in CSV files

These are used for bootstrapping the system into the SQLite database (below).

=item o An Import Package

This reads the CSV files and populates the Flower Database.

=item o A Flower Database managed by SQLite

For testing, a copy ships in data/flowers.sqlite.

=item o An Export Package

There are a number of simple Perl scripts involved, and some bash scripts to tie them together.

They generate:

=over 4

=item o A web page for every flower

These are pointed to be clickable thumbnails on the 'Flower Catalog' (next) and the 'Garden Layouts'
(below).

These pages consist of a set of details per flower:

=over 4

=item o Scientific name

=item o Common name

=item o Aliases

=item o Attributes

Details (so far) for: native, habit, edibleness and sub tolerance.

=item o A set of images

=item o A set of notes

=item o A set of URLs

=back

=item o The 'Flower Catalog' as an HTML table

This can be generated as a stand-alone page, or as a HTML table to be embedded in any web page.
Mine is L<online|https://savage.net.au/Flowers.html#the_flower_catalog>.

Each row in the table displays:

=over 4

=item o A native (to Australia) flag (Yes or No)

=item o The Scientific name

=item o The Common name

Actually, I've fiddled some of these to make flowers which have significantly different scientific
names end up on successive rows of the table. Likewise, flowers with very similar names are forced
to appear together in the table.

=item o A list of the flower's aliases

Search for 'pansy' to see a ridiculous list as a sample.

=item o A clickable thumbnail

Clicking opens up, in a new browser tab, a page dedicated to the flower whose thumbnail was clciked.

=back

=item o 'Garden Layouts' as SVG files

One SVG file is created for each of your gardens.

See my L<front garden layout|https://savage.net.au/Flowers/front.garden.layout.html> and
L<back garden layout|https://savage.net.au/Flowers/back.garden.layout.html>.

=item o A set of updated CSV files

For when you update the database either via the Search Engine or otherwise.

=back

=item o A Search Engine

This is a L<Mojolicious>-based program.

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<https://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install C<WWW::Garden::Design> as you would any C<Perl> module:

Run:

	cpanm WWW::Garden::Design

or run:

	sudo cpan WWW::Garden::Design

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 References

L<HumaneJS|http://wavded.github.com/humane-js/> - A simple, modern, browser notification system.

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
