package WWW::Garden::Design::Database::MojoDriver;

use Moo;

use feature ':5.10';
use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

use DBI;

use Types::Standard qw/Any HashRef Object/;

use WWW::Garden::Design::Database::Mojo;
use WWW::Garden::Design::Util::Config;

has config =>
(
	default		=> sub{WWW::Garden::Design::Util::Config -> new -> config},
	is			=> 'rw',
	isa			=> HashRef,
	required	=> 0,
);

has db =>
(
	is			=> 'rw',
	isa			=> Object,
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
	my($self)	= @_;
	my($config)	= $self -> config;
	my($attr)	=
	{
		AutoCommit 			=> $$config{AutoCommit},
		mysql_enable_utf8	=> $$config{mysql_enable_utf8},	#Ignored if not using MySQL.
		RaiseError 			=> $$config{RaiseError},
		sqlite_unicode		=> $$config{sqlite_unicode},	#Ignored if not using SQLite.
	};

	$self -> dbh(DBI -> connect($$config{dsn}, $$config{username}, $$config{password}, $attr) );
	$self -> db(WWW::Garden::Design::Database::Mojo -> new({dbh => $self -> dbh}) );

} # End of BUILD;

# --------------------------------------------------

sub arrays
{
	my($self, $sql)	= @_;

	return $self -> db -> arrays($sql);

} # End of arrays.

# --------------------------------------------------

sub hashes
{
	my($self, $sql, $key)	= @_;

	return $self -> db -> hashes($sql, $key);

} # End of hashes.

# --------------------------------------------------

1;

=pod

=head1 NAME

WWW::Garden::Design::Database::MojoDriver - Manage the 'flowers' database

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
