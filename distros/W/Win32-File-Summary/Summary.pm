package Win32::File::Summary;

use 5.006;
use strict;
use warnings;
use Carp;
use File::Basename;
use Config;
#use vars qw($VERSION @ISA @EXPORT);

#require Exporter;
#require DynaLoader;
#use AutoLoader;

use base qw/ DynaLoader /;
use vars qw/ $VERSION /;


#our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::File::Summary ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
#our %EXPORT_TAGS = ( 'all' => [ qw(
	
#) ] );

#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#our @EXPORT = qw(
	
#);
our $VERSION = '1.10';
our $File;
our $IsOOo = 0;

#require XSLoader;
#XSLoader::load('Win32::File::Summary', $VERSION);

bootstrap Win32::File::Summary $VERSION;

# Preloaded methods go here.

sub GetPath
{
	my $instdir = $Config{installsitelib};
	print "$instdir\n";
	return $instdir;
}

sub new
{
	my $class = shift;
	my $self = {
		File=>shift,
	};
	bless $self, $class;
	my $path = dirname($INC{"Win32/File/Summary.pm"});
	init($self->{File}, $path);
	return $self;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

  Win32::File::Summary - Perl extension read property informations from MS compound files and normal files.

=head1 SYNOPSIS

  use Win32::File::Summary;
  my $Prop = Win32::File::Summary->new($file);
  my $iscorOS = $Prop->IsWin2000OrNT();
  print "This OS is the correct one\n";
  my $isStgfile = $Prop->IsStgFile();
  print "The file contains a storage object.\n" if $isStgfile == 1;
  my $result = $Prop->Read();
  if(ref($result) eq "SCALAR")
  {
	my $err = $Prop->GetError();
	print "The Error: " . $$err  . "\n";
	exit;
  }

  my %hash = %{ $result };

  foreach my $key (keys %hash)
  {
	print "$key=" . $hash{$key} . "\n";
  }


=head1 DESCRIPTION

  The modul Win32::File::Summary can be used to get the summary informations from a MS compound file or normal (text) files.
  What are the summary information: 
  For compound documents, e.g. Word, you can add Title, Author, Description and some other informations to the document.
  The same, but not all of them you can add also to normal (text) files.
  This informationes can be read and add in the Property Dialog under the Summary Tab. The module reads these informations and prints them out.

  Please see the test.pl file for an example

=head1 FUNCTIONS

=over 4

=item new(file)
 
  This method is the constructor. The only parameter is the filename of the document which informations you want to get.
  
=item IsWin2000OrNT()

   This method returns 1 if the operating system currently used is Windows NT/2000/XP otherwise  0.
   
=item IsStgFile()

  This method returns 1 if that the file contains a storage object, otherwise 0.
  
=item Read()

  This method reads the property set and returns a refernce to a hash which contain the informations.
  If the method fail a scalar reference with the value \"0\" will be returned.
  To check use the following code:
  if(ref($result) eq "SCALAR")
  {
	my $err = $Prop->GetError();
	print "The Error: " . $$err  . "\n";
	exit;
  } else
  {
  	my %hash = %{ $result };
  	(Do something with the hash.)
  }

=item SetOEMCP

   If it is set to 1 then special characters like umlauts are displayed correctly in the DOS BOX.
   If set to 0 then the characters are displayed correctly in a file.
  
=item GetError()

  The GetError method returns the error message (scalar reference).
  The method shall only called if the result from the Read() methode is a scalar reference.

=back

=head1 TECHNICAL and LICENSE INFORAMTION

  The module Win32::File::Summary uses zlib1.1.4 from Mark Adler and Jean-loup
  Gailly and the unzip 1.01 from http://www.winimage.com/zLibDll/unzip.htm
  
  Thank you to Mark Adler, Jean-loup Gailly and all other which are makeing
  the libraries available to the public.
  
  There is no need to download the libraries above I allready added the
  neccessary parts to the module.

  It also uses the Mini-XML library version 2.2.2 from Michael Sweet.
  The whole library can be found under http://www.easysw.com/~mike/mxml/.
  Special thank to him for his great work.
  I included this version in the mxml-2.2.2.tar.gz in this package in the subdirectory mxml/.
  For License informations about the library please unpack the mxml-2.2.2.tar.gz and read the documentation.
  
  There is no need to extract the Mini-XML source files from the Tar Archive. I included the Perl modul Archive::Tar
  which will extract the neccessary source files to the module directory if Makefile.PL is called.
  
=head1 AUTHOR

Reinhard Pagitsch, E<lt>rpirpag@gmx.atE<gt>

=head1 SEE ALSO

L<perl>.

=head1 TODO

  Adding suport to write the summary informations back to the file.

=cut
