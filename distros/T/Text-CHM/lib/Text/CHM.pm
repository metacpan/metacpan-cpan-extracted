package Text::CHM;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::CHM ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = qw(new filename DESTROY close get_object get_filelist);

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Text::CHM', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Text::CHM - Perl extension for handling MS Compiled HtmlHelp Files

=head1 SYNOPSIS

  use Text::CHM;
  $chm = Text::CHM->new('foobar.chm');
  print $chm->filename(), "\n";  # It will print "foobar.chm"
  @content = $chm->get_filelist();

# I hope you don't really do this!
  foreach $file ( @content )
    {
      pring $chm->get_object($file->{path});
    }

  $chm->close();

=head1 DESCRIPTION

Text::CHM is a module that implements a (partial) support for handling
MS Compiled HtmlHelp Files (chm files for short) via CHMLib. CHMLib is
a small library designed for accessing MS ITSS files.  The ITSS file
format is used for chm files, which have been the predominant medium
for software documentation from Microsoft.

Chm is a filesystem based file format, such as MS Excel or MS Word
file formats, but they aren't the same.

Text::CHM allows you to open chm files, get their filelist, get the
content of each file and close them; at the moment, no write support
is available.

=head1 METHODS

=head2 C<new(filename)>

Opens the chm file filename and returns the chm object.

=head2 C<filename()>

Returns the name of the current working chm file.

=head2 C<get_filelist()>

Returns a list of hash references with the following fields:

=over 6

=item B<path>:
the path of the file in the chm object;

=item B<size>:
the size of the file;

=item B<title>:
the title of the file, if it is an html one, else undef.

=back

=head2 C<get_object(path)>

Returns the content of the object found at path in the chm file.

=head2 C<close()>

Close the chm file opened with C<new()>.


=head1 SEE ALSO

General understanding of perl is required, see C<perldoc perl> for
more informations.

CHMLib website is available (at the moment) at the address
I<http://66.93.236.84/~jedwin/projects/chmlib/>.

For a detailed (unofficial) description of the CHM file format see
Pabs' unofficial chm specifications or Matthew T. Russotto's CHM site,
respectively at I<http://savannah.nongnu.org/projects/chmspec> and
I<http://www.speakeasy.org/~russotto/chm/>.

Text::CHM's website is I<http://digilander.libero.it/bash/text-chm/>.

=head1 AUTHOR

Domenico Delle Side, E<lt>dds@gnulinux.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Domenico Delle Side

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
