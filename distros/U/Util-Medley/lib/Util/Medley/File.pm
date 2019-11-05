package Util::Medley::File;
$Util::Medley::File::VERSION = '0.007';
use Modern::Perl;
use Moose;
use Method::Signatures;
use namespace::autoclean;

use Data::Printer alias => 'pdump';
use Carp;
use File::LibMagic;
use File::Path qw(make_path remove_tree);
use Try::Tiny;
use Path::Iterator::Rule;

with 'Util::Medley::Roles::Attributes::Logger';
with 'Util::Medley::Roles::Attributes::String';
with 'Util::Medley::Roles::Attributes::Spawn';

=head1 NAME

Util::Medley::File - utility file methods

=head1 VERSION

version 0.007

=cut

=head1 SYNOPSIS

 my $file = Util::Medley::File->new;

 my $basename = $file->basename($path);
 my $dirname  = $file->dirname($path);
 my $newpath  = $file->trimSuffix($path);

 my ($dir, $filename, $suffix) = $file->parsePath($path);

 $file->cp($src, $dest);
 $file->mv($src, $dest);
 $file->chmod($path);
 $file->mkdir($path);
 $file->rmdir($path);
 $file->unlink($path);

 my $prev_dir = $file->chdir($path);
 my $type     = $file->fileType($path);
 my @found    = $file->find($path);
 my $cwd      = $file->getcwd;

 $file->xmllint(path => $path);
 my $formated_xml = $file->xmllint(string => $myxml);

=cut

########################################################

=head1 DESCRIPTION

Provides frequently used file operation methods.  Many of these
are pass-through to a standard module.  Others offer variations on 
the originals.  All methods output debug logging statements when enabled.  
Any errors are bubbled up with Carp::confess().  Use eval as appropriate.

=cut

########################################################

=head1 METHODS

=head2 basename

Pass-through to File::Path::basename().

=over

=item usage:

 my $basename = $file->basename($path);

=item args:

=over

=item path [Str]

The file path.

=back

=back

=cut

method basename (Str $path) {

	$self->Logger->debug("basename($path)");
	return File::Basename::basename($path);
}

=head2 chdir

Pass-through to CORE::chdir(), but differs in that it returns the original dir.

=over

=item usage:

 my $previous_dir = $file->chdir($path);

=item args:

=over

=item $path [Str]

Destination directory.

=back

=back

=cut

method chdir (Str $dir) {

	$self->Logger->debug("chdir($dir)");
	my $orig_dir = $self->getcwd;
	CORE::chdir($dir) or confess "failed to chdir to $dir: $!";

	return $orig_dir;
}

=head2 chmod

Pass-through to CORE::chmod().

=over

=item usage:

 $file->chmod(0755, $path);

=item args:

=over

=item $perm [Str]

Numeric mode.

=back

=back

=cut

method chmod (Str $perm, Str $file) {

	$self->Logger->debug("chmod($perm, $file)");
	CORE::chmod( $perm, $file );
}

=head2 cp

Pass-through to File::Copy::copy().

=over

=item usage:

 $file->cp($src, $dest);

=item args:

=over

=item $src [Str]

Source file.

=item $dest [Str]

Destination file.

=back

=back

=cut

method cp (Str $src, Str $dest) {

	$self->Logger->debug("cp $src, $dest");
	return File::Copy::copy( $src, $dest );
}

=head2 dirname 

Pass-through to File::Path::dirname().

=over

=item usage:

 my $dir = $file->dirname($path);

=item args:

=over

=item path [Str]

The file path.

=back

=back

=cut

method dirname (Str $path) {

	$self->Logger->debug("dirname($path)");
	return File::Basename::dirname($path);
}

=head2 fileType

Get the filetype of a file.

=over

=item usage:

 my $type = $file->fileType($path);

=item args:

=over

=item path [Str]

Path of the file you wish to interrogate.

=back

=back

=cut

method fileType (Str $path) {

	if ( $self->String->is_blank($path) ) {
		confess "path is empty";
	}

	if ( !-f $path ) {
		confess "$path does not exist";
	}

	my $info;
	my $magic = File::LibMagic->new();
	try {
		# apparently dies on error?
		$info = $magic->info_from_filename($path);
	}
	catch {
		return "unknown type: $_";
	};

	return $info->{description};
}

=head2 find

Pass-through to Path::Iterator::Rule.

=over

=item usage:

 my @files = $file->find( dir => $dir, 
                        [ files_only => $bool ],
                        [ dirs_only  => $bool ]);
 						

=item args:

=over

=item dir [Str]

The directory path you wish to search.

=item files_only [Bool]

Return files only (no directories).  Mutually exclusive from dirs_only.

=item dirs_only [Bool]

Return directories only (no files).  Mutually exclusive from files_only.

=back

=back

=cut

method find (Str :$dir!, 
			 Str :$files_only,
			 Str :$dirs_only) {

	if ($files_only and $dirs_only) {
		confess "options files_only and dirs_only are mutually exclusive";		
	}
		
	if ( !-d $dir ) {
		confess "dir $dir does not exist";
	}

	my @paths;
	my $rule = Path::Iterator::Rule->new;
	my $next = $rule->iter($dir);

	while ( defined( my $path = $next->() ) ) {
		
		next if $files_only and -d $path;
		next if $dirs_only and !-d $path;
		
		push @paths, $path;
	}

	return @paths;
}

=head2 getcwd 

Pass-through to Cwd::getcwd().

=over

=item usage:

 my $cwd = $file->getcwd;

=back

=cut

method getcwd {

	my $cwd = Cwd::getcwd();
	$self->Logger->debug("cwd: $cwd");
	return $cwd;
}

=head2 mkdir 

Pass-through to File::Path::make_path().

=over

=item usage:

 $file->mkdir($path;
 $file->mkdir($path, 0755);

=item args:

=over

=item path [Str]

The directory path.

=item perm [Str]

Numeric mode.

=back

=back

=cut

method mkdir (Str $path, Str $perm?) {

	my @param = ($path);
	push @param, { mode => $perm } if defined $perm;
	$self->Logger->debug(sprintf("mkpath(%s)", join(', ', @param)));
	make_path(@param);
}

=head2 mv 

Pass-through to File::Copy::move().

=over

=item usage:

 $file->mv($src, $dest);

=item args:

=over

=item src [Str]

The source path.

=item dest [Str]

The destination path.

=back

=back

=cut

method mv (Str $src, Str $dest) {

	$self->Logger->debug("mv($src, $dest)");
	my $rc = File::Copy::move( $src, $dest );
	if (!$rc) {
		confess "mv($src, $dest) failed: $!";	
	}
}

=head2 parsePath

Parse a file path into directory, filename, and extension.  This is a 
pass-through to File::Basename::fileparse, but it additional trims the '.'
from the extension and extraneous trailing /'s in the dir.

=over

=item usage:

 my ($dir, $name, $ext) = $file->parsePath($path);

=item args:

=over

=item path [Str]

The file path for which you wish to parse.

=back

=back

=cut

method parsePath (Str $path) {

	my ( $filename, $dir, $suffix ) =
	  File::Basename::fileparse( $path, qr/\..*$/ );

	if ($dir ne './') {
		$dir =~ s/\/$//g; # remove trailing slashes
	}
	
	if ($suffix) {
		$suffix =~ s/^\.//g;
	}

	return ( $dir, $filename, $suffix );
}

=head2 rmdir

Delete a directory and any contents.  Pass-through to File::Path::remove_tree().

=over

=item usage:

 $file->rmdir($dir);

=item args:

=over

=item dir [Str]

Directory to remove.

=back

=back

=cut

method rmdir (Str $dir) {

	if ( -d $dir ) {
		$self->Logger->debug("rmdir $dir");
		remove_tree($dir);
	}
}

=head2 trimExt

Trim the file extension from a filename.

=over

=item usage:

 my $filename_no_ext = $file->trimExt($filename);

=item args:

=over

=item filename [Str]

The filename for which you want to remove the extension.

=back

=back

=cut

method trimExt (Str $name) {

	$name =~ s/\..*$//g;
	
	return $name;
}

=head2 unlink

Pass-through to CORE::unlink().

=over

=item usage:

 $file->unlink($path);

=item args:

=over

=item path [Str]

Path of the file you wish to delete.

=back

=back

=cut

method unlink (Str $path) {

	if ( -f $path ) {
		$self->Logger->debug("unlink $path");
		Core::unlink($path) or confess "failed to unlink $path: $!";
	}
}

=head2 xmllint

Wrapper around the xmllint command.  You can pass an xml string or
the path to an xml file.

=over

=item usage:

 $file->xmllint($path);

 my $pretty_xml = $file->xmllint($xmlstring);
 
=item args:

=over

=item string [Str]

An xml string.

=item path [Str]

Path to an xml file.

=back

=back

=cut

method xmllint (Str :$string,
                Str :$path) {

	if ( $string and $path ) {
		confess "string and path are mutually exclusive";
	}

	if ($string) {
		my @cmd = ( 'xmllint', '--format', '-' );
		my ( $stdout, $stderr, $exit ) =
		  $self->spawn->capture( cmd => \@cmd, stdin => $string );

		return $stdout;
	}
	elsif ($path) {
		my $cmd = "xmllint --format $path > $path.tmp";
		$self->spawn->spawn( cmd => $cmd );
		$self->mv( "$path.tmp", $path );
	}
	else {
		confess "no args provided";
	}
}


######################################################################

1;
