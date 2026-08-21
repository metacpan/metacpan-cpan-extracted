package WWW::Garden::Design::Controller::GetTable;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

our $VERSION = '0.97';

# -----------------------------------------------

sub attribute_types
{
	my($self) = @_;

	$self -> app -> log -> debug('GetTable.attribute_types()');

	my($defaults) = $self -> app -> defaults;

	$self -> render(json => $$defaults{db} -> read_table('attribute_types') );

} # End of attribute_types.

# -----------------------------------------------

sub design_feature
{
	my($self)			= @_;
	my($design_feature)	= $self -> param('design_feature') || '';

	$self -> app -> log -> debug('GetTable.design_feature()');

	if (length($design_feature) < 2)
	{
		$self -> stash(feature_name => '');
		$self -> render();
	}
	else
	{
		my($defaults) = $self -> app -> defaults;

		$self -> stash(feature_name => $$defaults{db} -> get_feature_by_name($design_feature) );
		$self -> render;
	}

} # End of design_feature.

# -----------------------------------------------

sub design_flower
{
	my($self)			= @_;
	my($design_flower)	= $self -> param('design_flower') || '';

	$self -> app -> log -> debug('GetTable.design_flower()');

	if (length($design_flower) < 2)
	{
		$self -> stash(thumbnail_name => '');
		$self -> render();
	}
	else
	{
		my($defaults) = $self -> app -> defaults;

		$self -> stash(thumbnail_name => $$defaults{db} -> get_flower_by_both_names($design_flower) );
		$self -> render;
	}

} # End of design_flower.

# -----------------------------------------------

sub features
{
	my($self) = @_;

	$self -> app -> log -> debug('GetTable.features()');

	my($defaults)		= $self -> app -> defaults;
	my($features_table)	= $$defaults{db} -> read_features_table;

	$self -> app -> log -> debug('GetTable.features(). Size of features_table: ' . scalar @$features_table);
	$self -> render(json => $features_table);

} # End of features.

# -----------------------------------------------

sub gardens
{
	my($self) = @_;

	$self -> app -> log -> debug('GetTable.gardens()');

	my($defaults)		= $self -> app -> defaults;
	my($gardens_table)	= $$defaults{db} -> read_gardens_table;

	$self -> app -> log -> debug('GetTable.gardens(). Size of gardens_table: ' . scalar @$gardens_table);
	$self -> render(json => $gardens_table);

} # End of gardens.

# -----------------------------------------------

sub properties
{
	my($self) = @_;

	$self -> app -> log -> debug('GetTable.properties()');

	my($defaults)			= $self -> app -> defaults;
	my($properties_table)	= $$defaults{db} -> read_properties_table;

	$self -> app -> log -> debug('GetTable.properties(). Size of properties_table: ' . scalar @$properties_table);
	$self -> render(json => $properties_table);

} # End of properties.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Garden::Design::Controller::GetTable - Manage the 'flowers' database

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
