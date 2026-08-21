package WWW::Garden::Design::Controller::AutoComplete;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

our $VERSION = '0.97';

# -----------------------------------------------

sub display
{
	my($self)	= @_;
	my($key)	= $self -> param('term')	|| ''; # jQuery forces use of 'term'.
	my($type)	= $self -> param('type')	|| '';

	$self -> app -> log -> debug("AutoComplete.display(key: $key, type: $type)");

	my(%context) =
	(	# Form field		Table column		Table name.
		design_flower	=> ['*',				'flowers'],
		design_feature	=> ['*',				'features'],
		feature_name	=> ['name',				'features'],
		garden_name		=> ['name',				'gardens'],
		property_name	=> ['name',				'properties'],
	);
	my(%want_single_item) =
	(
		garden_name		=> 1,
		property_name	=> 1,
	);

	my($defaults) = $self -> app -> defaults;

	# In the case of $type being 'design_flower', we're called from line 501 in homepage.html.ep,
	# meaning we're on the Design garden tab. In this case we can't assume the string the user typed
	# petains to just one column of the flower database, so we search these 3 columns in the
	# 'flowers' table: scientific_name, common_name and aliases.
	# Warning: This use '*' in %context above means the methods in Database.pm which search %context
	# must skip it. See Database.autocomplete_item() and Database.autocomplete_list().
	# Likewise for 'design_feature'.

	if ($type eq 'design_flower')
	{
		$self -> render(json => $$defaults{db} -> autocomplete_flower_list(uc $key) );
	}
	elsif ($type eq 'design_feature')
	{
		$self -> render(json => $$defaults{db} -> autocomplete_feature_list(uc $key) );
	}
	elsif ($want_single_item{$type})
	{
		$self -> render(json => $$defaults{db} -> autocomplete_item(\%context, uc $key, $type) );
	}
	else
	{
		$self -> render(json => $$defaults{db} -> autocomplete_list(\%context, uc $key, $type) );
	}

} # End of display.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Garden::Design::Controller::AutoComplete - Manage the 'flowers' database

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
