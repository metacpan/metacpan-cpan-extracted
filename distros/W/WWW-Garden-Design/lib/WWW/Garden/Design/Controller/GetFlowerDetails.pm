package WWW::Garden::Design::Controller::GetFlowerDetails;

use Mojo::Base 'Mojolicious::Controller';

use Date::Simple;

use Moo;

our $VERSION = '0.97';

# -----------------------------------------------

sub display
{
	my($self)		= @_;
	my($flower_id)	= $self -> param('flower_id') || 0;

	$self -> app -> log -> debug("GetFlowerDetails.display(flower_id => $flower_id)");

	if ($flower_id > 0)
	{
		my($defaults)	= $self -> app -> defaults;
		my($json)		= $$defaults{db} -> get_flower_by_id($flower_id);

		$self -> stash(error => undef);
		$self -> render(json => $json);
	}
	else
	{
		my($message) = "Error: Unknown key flower_id = $flower_id";

		$self -> app -> log -> error($message);
		$self -> stash(error => $message);
		$self -> render;
	}

} # End of display.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Garden::Design::Controller::GetFlowerDetails - Manage the 'flowers' database

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
