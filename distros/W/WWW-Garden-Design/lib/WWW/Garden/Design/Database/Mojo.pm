package WWW::Garden::Design::Database::Mojo;

use Moo;

use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use Mojo::Collection;

use Types::Standard qw/Any/;

has collection =>
(
	is			=> 'rw',
	isa			=> Any,
	required	=> 0,
);

has dbh =>
(
	is			=> 'rw',
	isa			=> Any,
	required	=> 0,
);

our $VERSION = '0.97';

# -----------------------------------------------

sub BUILD
{
	my($self, $options)	= @_;

	$self -> dbh($$options{dbh});

} # End of BUILD;

# --------------------------------------------------

sub arrays
{
	my($self, $sql) = @_;

	return $self -> collection(Mojo::Collection -> new($self -> dbh -> selectall_array($sql) ) );

} # End of arrays.

# --------------------------------------------------

sub hashes
{
	my($self, $sql, $key) = @_;

	return $self -> collection(Mojo::Collection -> new($self -> dbh -> selectall_hashref($sql, $key) ) );

} # End of hashes.

# --------------------------------------------------

1;

=pod

=head1 NAME

WWW::Garden::Design::Database::Mojo - Manage the 'flowers' database

head1 Machine-Readable Change Log

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
