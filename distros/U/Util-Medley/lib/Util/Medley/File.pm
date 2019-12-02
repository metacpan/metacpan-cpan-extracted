package Util::Medley::File;
$Util::Medley::File::VERSION = '0.016';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
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

version 0.016

=cut

=head1 SYNOPSIS

 my $util = Util::Medley::File->new;

 my $basename = $util->basename($path);
 my $dirname  = $util->dirname($path);
 my $newpath  = $util->trimSuffix($path);

 my ($dir, $utilname, $suffix) = $util->parsePath($path);

 $util->cp($src, $dest);
 $util->mv($src, $dest);
 $util->chmod($path);
 $util->mkdir($path);
 $util->rmdir($path);
 $util->unlink($path);

 my $prev_dir = $util->chdir($path);
 my $type     = $util->fileType($path);
 my @found    = $util->find($path);
 my $cwd      = $util->getcwd;

=cut

########################################################

=head1 DESCRIPTION

Provides frequently used file operation methods.  Many of these
are pass-through to another module.  Others offer variations on 
the originals.  All methods output debug logging statements when enabled.  
Any errors are bubbled up with Carp::confess().  Use eval as appropriate.

=cut

########################################################

=head1 METHODS

=head2 basename

Pass-through to File::Path::basename().

=over

=item usage:

 $basename = $util->basename($path);

 $basename = $util->basename(path => $path);

=item args:

=over

=item path [Str]

The file path.

=back

=back

=cut

multi method basename (Str :$path!) {
	
	return $self->basename($path);	
}

multi method basename (Str $path) {

	$self->Logger->debug("basename($path)");
	return File::Basename::basename($path);
}

=head2 chdir

Pass-through to CORE::chdir(), but differs in that it returns the original dir.

=over

=item usage:

 $previous_dir = $util->chdir($path);

 $previous_dir = $util->chdir(path => $path);
 
=item args:

=over

=item $path [Str]

Destination directory.

=back

=back

=cut

multi method chdir (Str :$dir!) {

	return $self->chdir($dir);	
}

multi method chdir (Str $dir) {

	$self->Logger->debug("chdir($dir)");
	my $orig_dir = $self->getcwd;
	CORE::chdir($dir) or confess "failed to chdir to $dir: $!";

	return $orig_dir;
}

=head2 chmod

Pass-through to CORE::chmod().

=over

=item usage:

 $util->chmod(0755, $path);

 $util->chmod(perm => 0755, path => $path);
 
=item args:

=over

=item perm [Str]

Numeric mode.

=item file [Str]

Location of the file to update.

=back

=back

=cut

multi method chmod (Str :$perm!, Str :$file!) {

	return $self->chmod($perm, $file);	
}

multi method chmod (Str $perm, Str $file) {

	$self->Logger->debug("chmod($perm, $file");
	CORE::chmod( $perm, $file );
}

=head2 cp

Pass-through to File::Copy::copy().

=over

=item usage:

 $util->cp($src, $dest);

 $util->cp(src => $src, dest => $dest);
 
=item args:

=over

=item src [Str]

Source file.

=item dest [Str]

Destination file.

=back

=back

=cut

multi method cp (Str :$src!, Str :$dest!) {

	return $self->cp($src, $dest);
}

multi method cp (Str $src, Str $dest) {

	$self->Logger->debug("cp $src, $dest");
	return File::Copy::copy( $src, $dest );
}

=head2 dirname 

Pass-through to File::Path::dirname().

=over

=item usage:

 $dir = $util->dirname($path);
 
 $dir = $util->dirname(path => $path);
 
=item args:

=over

=item path [Str]

The file path.

=back

=back

=cut

multi method dirname (Str :$path!) {

	return $self-dirname($path);
}

multi method dirname (Str $path) {

	$self->Logger->debug("dirname($path)");
	return File::Basename::dirname($path);
}

=head2 fileType

Get the filetype of a file.

=over

=item usage:

 $type = $util->fileType($path);
 
 $type = $util->fileType(path => $path);
 
=item args:

=over

=item path [Str]

Path of the file you wish to interrogate.

=back

=back

=cut

multi method fileType (Str :$path!) {

	return $self->fileType($path);
}

multi method fileType (Str $path) {

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
		return "unknown type for $path: $_";
	};

	return $info->{description};
}

=head2 find

Pass-through to Path::Iterator::Rule.  Returns a list of all files and 
directories.

=over

=item usage:

 @files = $util->find($dir);
 
 @files = $util->find(dir => $dir);

=item args:

=over

=item dir [Str]

The directory path you wish to search.

=back

=back

=cut

multi method find (Str :$dir!) {

	if ( !-d $dir ) {
		confess "dir $dir does not exist";
	}

	my @paths;
	my $rule = Path::Iterator::Rule->new;
	my $next = $rule->iter($dir);

	while ( defined( my $path = $next->() ) ) {
	
		next if $path eq $dir; # don't return self	
		push @paths, $path;
	}

	return @paths;
}

multi method find (Str $dir) {

	return $self->find(dir => $dir);	
}


=head2 findFiles

Returns a list of all files under a given directory.  Just a 
convenience wrapper around find.

=over

=item usage:

 @files = $util->findFiles($dir);
 
 @files = $util->find(dir => $dir);

=item args:

=over

=item dir [Str]

The directory path you wish to search.

=back

=back

=cut

multi method findFiles (Str :$dir!) {

	my @paths = $self->find(dir => $dir);
	my @files;
	
	foreach my $path (@paths) {	
		next if -d $path;
		push @files, $path;	
	}
	
	return @files;
}

multi method findFiles (Str $dir) {

	return $self->findFiles(dir => $dir);
}


=head2 findDirs

Returns a list of all directories under a given directory.  Just a 
convenience wrapper around find.

=over

=item usage:

 @dirs = $util->findDirs($dir);
 
 @dirs = $util->findDirs(dir => $dir);

=item args:

=over

=item dir [Str]

The directory path you wish to search.

=back

=back

=cut

multi method findDirs (Str :$dir!) {

	my @paths = $self->find(dir => $dir);
	my @dirs;
	
	foreach my $path (@paths) {	
		next if !-d $path;
		push @dirs, $path;	
	}
	
	return @dirs;
}

multi method findDirs (Str $dir) {

	return $self->findDirs(dir => $dir);
}


=head2 getcwd 

Pass-through to Cwd::getcwd().

=over

=item usage:

 $cwd = $util->getcwd;

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

 $util->mkdir($path, [$perm]);
 
 $util->mkdir(path => $path, [perm => $perm]);

=item args:

=over

=item path [Str]

The directory path.

=item perm [Str]

Numeric mode.

=back

=back

=cut

multi method mkdir (Str :$path!, Str :$perm) {

	return $self->mkdir(@_);
}

multi method mkdir (Str $path, Str $perm?) {

	my @param = ($path);
	push @param, { mode => $perm } if defined $perm;
	$self->Logger->debug(sprintf("mkpath(%s)", join(', ', @param)));
	make_path(@param);
}

=head2 mv 

Pass-through to File::Copy::move().

=over

=item usage:

 $util->mv($src, $dest);

 $util->mv(src => $src, dest => $dest);
 
=item args:

=over

=item src [Str]

The source path.

=item dest [Str]

The destination path.

=back

=back

=cut

multi method mv (Str :$src!, Str :$dest!) {

	return $self->mv($src, $dest);
}

multi method mv (Str $src, Str $dest) {

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

 ($dir, $name, $ext) = $util->parsePath($path);

 ($dir, $name, $ext) = $util->parsePath(path => $path);

=item args:

=over

=item path [Str]

The file path for which you wish to parse.

=back

=back

=cut

multi method parsePath (Str :$path!) {

	return $self->parsePath($path);
}

multi method parsePath (Str $path) {

	my ( $utilname, $dir, $suffix ) =
	  File::Basename::fileparse( $path, qr/\..*$/ );

	if ($dir ne './') {
		$dir =~ s/\/$//g; # remove trailing slashes
	}
	
	if ($suffix) {
		$suffix =~ s/^\.//g;
	}

	return ( $dir, $utilname, $suffix );
}


=head2 rmdir

Delete a directory and any contents.  Pass-through to File::Path::remove_tree().

=over

=item usage:

 $util->rmdir($dir);

 $util->rmdir(dir => $dir);
 
=item args:

=over

=item dir [Str]

Directory to remove.

=back

=back

=cut

multi method rmdir (Str :$dir!) {

	return $self->rmdir($dir);
}

multi method rmdir (Str $dir) {

	if ( -d $dir ) {
		$self->Logger->debug("rmdir $dir");
		remove_tree($dir);
	}
}


=head2 trimExt

Trim the file extension from a filename.

=over

=item usage:

 $filename_no_ext = $util->trimExt($filename);

 $filename_no_ext = $util->trimExt(name => $filename);

=item args:

=over

=item name [Str]

The filename for which you want to remove the extension.

=back

=back

=cut

multi method trimExt (Str :$name!) {

	return $self->trimExt($name);
}

multi method trimExt (Str $name) {

	$name =~ s/\..*$//g;
	
	return $name;
}

=head2 unlink

Pass-through to CORE::unlink().

=over

=item usage:

 $util->unlink($path);

 $util->unlink(path => $path);
 
=item args:

=over

=item path [Str]

Path of the file you wish to delete.

=back

=back

=cut

multi method unlink (Str :$path!) {

	return $self->unlink($path);
}

multi method unlink (Str $path) {

	if ( -f $path ) {
		$self->Logger->debug("unlink $path");
		Core::unlink($path) or confess "failed to unlink $path: $!";
	}
}

######################################################################

1;
