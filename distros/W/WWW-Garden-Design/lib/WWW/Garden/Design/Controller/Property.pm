package WWW::Garden::Design::Controller::Property;

use Mojo::Base 'Mojolicious::Controller';

use Moo;

our $VERSION = '0.97';

# -----------------------------------------------

sub process
{
	my($self) = @_;

	$self -> app -> log -> debug('Property.process()');

	my($defaults)	= $self -> app -> defaults;
	my($item)		= $self -> req -> params -> to_hash;

	$self -> app -> log -> debug("param($_) => $$item{$_}") for sort keys %$item;

	if ($$item{name})
	{
		# In process_property() all success branches print the raw message plus
		# other information to the log, so nothing is printed here.

		my($packet) = $$defaults{db} -> process_property($item);

		$self -> stash(json => $packet);
	}
	else
	{
		my($result) = {garden_id => 0, outcome => 'Error', raw => 'The property name is mandatory'};
		my($packet)	=
		{
			property_table	=> $$defaults{db} -> read_features_table, # Warning: Not read_table('features').
			message			=> $$defaults{db} -> format_raw_message($result),
		};

		$self -> stash(json => $packet);
		$self -> app -> log -> error($$result{raw});
	}

	$self -> render;

} # End of process.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Garden::Design::Controller::Property - Manage the 'flowers' database

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
