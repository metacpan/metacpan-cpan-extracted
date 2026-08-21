package WWW::Garden::Design::Util::Filer;

use strict;
use warnings;

use Moo;

use Text::CSV::Encoded;

use Types::Standard qw/Object/;

has csv =>
(
	default		=> sub{return Text::CSV::Encoded -> new({allow_whitespace => 1, encoding_in => 'utf-8'})},
	is			=> 'rw',
	isa			=> Object, # 'Text::CSV::Encoded'.
	required	=> 0,
);

our $VERSION = '0.97';

# -----------------------------------------------

sub read_csv_file
{
	my($self, $file_name)	= @_;
	my($io)					= IO::File -> new($file_name, 'r');

	$self -> csv -> column_names($self -> csv -> getline($io) );

	return $self -> csv -> getline_hr_all($io);

} # End of read_csv_file.

# --------------------------------------------------

1;

=head1 NAME

WWW::Garden::Design::Util::Filer - Some file helpers

=head1 Synopsis

See L<WWW::Garden::Design/Synopsis>.

=head1 Description

L<WWW::Garden::Design> implements an interface to the 'flowers' database.

=head1 Distributions

See L<WWW::Garden::Design/Distributions>.

=head1 Installation

See L<WWW::Garden::Design/Installation>.

=head1 Methods

=head2 read_csv_file()

Returns a an arrayref of hashref of records.

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
