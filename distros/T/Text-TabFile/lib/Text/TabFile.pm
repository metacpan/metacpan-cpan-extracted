=head1 NAME

Text::TabFile - Module for parsing tab delimited files

=head1 SYNOPSIS

Text::TabFile provides a programattical interface to data stored in text 
files delimited with tabs. It is dependant upon the first row of the tab 
file containing header information for each corresponding "column" in the 
file.

After instancing, for each call to Read the next row's data is returned as 
a hash reference. The individual elements are keyed by their corresonding 
column headings.

=head1 USAGE

A short example of usage is detailed below. It opens a file called 
'infile.tab', reads through every row and prints out the data from 
"COLUMN1" in that row. It then closes the file.

  my $tabfile = new Text::TabFile;
  $tabfile->open('infile.tab');

  my @header = $tabfile->fields;

  while ( my $row = $tabfile->read ) {
    print $row->{COLUMN1}, "\n";
  }

  $tabfile->Close;

A shortcut for open() is to specifiy the file or a globbed filehanle as the 
first parameter when the module is instanced:

  my $tabfile = new Text::TabFile ('infile.tab');

  my $tabfile = new Text::TabFile (\*STDIN);

The close() method is atuomatically called when the object passes out of 
scope. However, you should not depend on this. Use close() when 
approrpiate.

Other informational methods are also available. They are listed blow:

=head1 METHODS

=over

=item close()

Closes the file or connection, and cleans up various bits.

=item fields()

Returns an array (or arrayref, depending on the requested context) with 
the column header fields in the order specified by the source file.

=item filename()

If Open was given a filename, this function will return that value.

=item linenumber()

This returns the line number of the last line read. If no calls to Read 
have been made, will be 0. After the first call to Read, this will return 
1, etc.

=item new([filename|filepointer],[enumerate])

Creates a new Text::TabFile object. Takes optional parameter that is either
a filename or a globbed filehandle. Files specified by filename must 
already exist.

Can optionally take a second argument. If this argument evaluates to true,
TabFile.pm will append a _NUM to the end of all fields with duplicate names.
That is, if your header row contains 2 columns named "NAME", one will be 
changed to NAME_1, the other to NAME_2.

=item open([filename|filepointer], [enumerate])

Opens the given filename or globbed filehandle and reads the header line. 
Returns 0 if the operation failed. Returns the file object if succeeds.

Can optionally take a second argument. If this argument evaluates to true,
TabFile.pm will append a _NUM to the end of all fields with duplicate names.
That is, if your header row contains 2 columns named "NAME", one will be 
changed to NAME_1, the other to NAME_2.

=item read()

Returns a hashref with the next record of data. The hash keys are determined
by the header line. 

__DATA__ and __LINE__ are also returned as keys.

__DATA__ is an arrayref with the record values in order.

__LINE__ is a string with the original tab-separated record. 

This method returns undef if there is no more data to be read.

=item setmode(encoding)

Set the given encoding scheme on the tabfile to allow for reading files
encoded in standards other than ASCII.

=back

=head1 EXPORTABLE METHODS

For convienience, the following methods are exportable. These are handy 
for quickly writing output tab files.

=over

=item tj(@STUFF)

Tab Join. Returns the given array as a string joined with tabs.

=item tl(@STUFF)

Tab Line. Returns the given array as a string joined with tabs (with 
newline appended).

=back

=head1 SEE ALSO

  Text::Delimited

=head1 BUGS AND SOURCE

	Bug tracking for this module: https://rt.cpan.org/Dist/Display.html?Name=Text-TabFile

	Source hosting: http://www.github.com/bennie/perl-Text-TabFile

=head1 VERSION

	Text::Tabfile v1.14 (2014/03/08)

=head1 COPYRIGHT

	(c) 2004-2014, Phillip Pollard <bennie@cpan.org>

=head1 LICENSE

This source code is released under the "Perl Artistic License 2.0," the text of
which is included in the LICENSE file of this distribution. It may also be
reviewed here: http://opensource.org/licenses/artistic-license-2.0

=head1 AUTHORSHIP

  I'd like to thank PetBlvd for sponsoring continued work on this module.
  http://www.petblvd.com/

  Additional contributions by Kristina Davis <krd@menagerie.tf>
  Based upon the original module by Andrew Barnett <abarnett@hmsonline.com>

  Originally derived from Util::TabFile 1.9 2003/11/05
  With permission granted from Health Market Science, Inc.

=cut

package Text::TabFile;
$Text::TabFile::VERSION='1.14';

use base 'Text::Delimited';
use warnings;
use strict;

require Exporter;
require DynaLoader;

push our @ISA, 'Exporter';
our @EXPORT_OK = qw(tj tl);

sub _init {
  my $self = shift @_;
  $self->delimiter("\t");
}

sub tj {
  my $self = shift @_ if ref($_[0]);
  return join("\t",map {defined($_)?$_:''} @_);
}

sub tl {
  my $self = shift @_ if ref($_[0]);
  return join("\t",map {defined($_)?$_:''} @_) . "\n";
}

1;
