package WWW::Garden::Design::Controller::Feature;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper::Concise; # For Dumper().

use Moo;

our $VERSION = '0.97';

# -----------------------------------------------

sub process
{
	my($self) = @_;

	$self -> app -> log -> debug('Feature.process()');

	my($defaults)	= $self -> app -> defaults;
	my($item)		= $self -> req -> params -> to_hash;

	$self -> app -> log -> debug("param($_) => $$item{$_}") for sort keys %$item;

	if ($$item{color_chosen} && $$item{name})
	{
		# In process_feature() all success branches print the raw message plus
		# other information to the log, so nothing is printed here.

		my($packet) = $$defaults{db} -> process_feature($item);

		$self -> stash(json => $packet);
	}
	else
	{
		my($result) = {feature_id => 0, outcome => 'Error', raw => 'Missing color or feature name'};
		my($packet)	=
		{
			feature_table	=> $$defaults{db} -> read_features_table, # Warning: Not read_table('features').
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

WWW::Garden::Design::Controller::Feature - Manage the 'flowers' database

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
