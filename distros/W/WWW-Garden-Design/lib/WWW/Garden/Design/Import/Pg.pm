package WWW::Garden::Design::Import::Pg;

use Moo;

with 'WWW::Garden::Design::Import';

use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use Mojo::Log;

use Types::Standard qw/HashRef/;

use WWW::Garden::Design::Database::Pg;
use WWW::Garden::Design::Util::Config;

has config =>
(
	default		=> sub{WWW::Garden::Design::Util::Config -> new -> config},
	is			=> 'rw',
	isa			=> HashRef,
	required	=> 0,
);

our $VERSION = '0.97';

# -----------------------------------------------

sub BUILD
{
	my($self)	= @_;
	my($config)	= $self -> config;

	$self -> db
	(
		WWW::Garden::Design::Database::Pg -> new
		(
			logger => Mojo::Log -> new(path => $$config{log_path})
		)
	);

} # End of BUILD.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Garden::Design::Import::Pg - Manage the 'flowers' database

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
