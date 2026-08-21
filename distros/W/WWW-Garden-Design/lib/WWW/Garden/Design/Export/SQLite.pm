package WWW::Garden::Design::Export::SQLite;

use Moo;

with 'WWW::Garden::Design::Export';

use strict;
use warnings;

use Mojo::Log;

use WWW::Garden::Design::Database::SQLite;

our $VERSION = '0.97';

# -----------------------------------------------

sub BUILD
{
	my($self)	= @_;
	my($config)	= $self -> config;

	$self -> init_export;
	$self -> db
	(
		WWW::Garden::Design::Database::SQLite -> new
		(
			logger => Mojo::Log -> new(path => $$config{log_path})
		)
	);

}	# End of BUILD.

# -----------------------------------------------
# Warning: This method must be here and not upstairs, in WWW::Garden::Design::Export,
# because it's also called by Local::Website when rebuilding savage.net.au/Flowers.html.

sub init_datatable
{
	my($self) = @_;

	return <<EOS;
	\$(function()
	{
		\$('#result_table').DataTable
		({
			'columnDefs':
			[
				{'cellType':'th','orderable':true,'searchable':true,'type':'html'},		// Native.
				{'cellType':'th','orderable':true,'searchable':true,'type':'html'},		// Scientific name.
				{'cellType':'th','orderable':true,'searchable':true,'type':'html'},		// Common name.
				{'cellType':'th','orderable':true,'searchable':true,'type':'html'},		// Aliases.
				{'cellType':'th','orderable':false,'searchable':false,'type':'html'}	// Thumbnail.
			],
			'order': [ [1, 'asc'] ]
		});
	});
EOS

}	# End of init_datatable.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Garden::Design::Export::SQLite - Manage the 'flowers' database

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
