package Test::Inline::IO::File;
# ABSTRACT: Test::Inline Local Filesystem IO Handler

#pod =pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<Test::Inline::IO::File> is the default IO handler for L<Test::Inline>.
#pod
#pod L<Test::Inline> 2.0 was conceived in an enterprise setting, and retains
#pod the flexibilty, power, and bulk that this created, although for most
#pod users the power and complexity that is available is largely hidden away
#pod under multiple layers of sensible defaults.
#pod
#pod The intent with the C<InputHandler> and C<OutputHandle> parameters is to
#pod allow L<Test::Inline> to be able to pull source data from anywhere, and
#pod write the resulting test scripts to anywhere.
#pod
#pod Until a more powerful pure-OO file-system API comes along, this module
#pod serves as a minimalist implementation of the subset of functionality
#pod that L<Test::Inline> needs in order to work.
#pod
#pod An alternative IO Handler class need not subclass this one (although it
#pod is recommended), merely implement the same interface, taking whatever
#pod alternative arguments to the C<new> constructor that it wishes.
#pod
#pod All methods in this class are provided with unix-style paths, and should do
#pod the translating to the underlying filesystem themselves if required.
#pod
#pod =head1 METHODS
#pod
#pod =cut

use strict;
use File::Spec   ();
use File::chmod  ();
use File::Remove ();

our $VERSION = '2.214';





#####################################################################
# Constructor and Accessors

#pod =pod
#pod
#pod =head2 new
#pod
#pod   # Simplified usage
#pod   $io_handler = Test::Inline::IO::File->new( $path );
#pod   
#pod   # Full key/value usage
#pod   $io_handler = Test::Inline::IO::File->new(
#pod           path     => $path,
#pod           readonly => 1,
#pod   );
#pod
#pod The C<new> constructor takes a root path on the local filesystem
#pod and returns a new C<Test::Inline::IO::File> object to that
#pod location.
#pod
#pod =cut

sub new {
	my $class  = shift;
	my @params = @_;
	if ( @params < 2 ) {
		my $path  = defined $_[0] ? shift : File::Spec->curdir;
		@params = ( path => $path );
	}

	# Create the object
	my $self = bless { @params }, $class;

	# Apply defaults
	$self->{readonly} = !! $self->{readonly};

	return $self;
}

sub path {
	$_[0]->{path};
}

sub readonly {
	$_[0]->{readonly};
}

# Resolve the full path for any file
sub _path {
	my $self = shift;
	my $file = defined $_[0] ? shift : return undef;
	File::Spec->catfile( $self->{path}, $file );
}





#####################################################################
# Filesystem API

#pod =pod
#pod
#pod =head2 exists_file $file
#pod
#pod The C<exists_file> method checks to see if a particular file currently
#pod exists in the input handler.
#pod
#pod Returns true if it exists, or false if not.
#pod
#pod =cut

sub exists_file {
	my $self = shift;
	my $file = $self->_path(shift) or return undef;
	!! -f $file;
}

#pod =pod
#pod
#pod =head2 exists_dir $dir
#pod
#pod The C<exists_dir> method checks to see if a particular directory currently
#pod exists in the input handler.
#pod
#pod Returns true if it exists, or false if not.
#pod
#pod =cut

sub exists_dir {
	my $self = shift;
	my $dir = $self->_path(shift) or return undef;
	!! -d $dir;
}

#pod =pod
#pod
#pod =head2 read $file
#pod
#pod The C<read> method reads in the entire contents of a single file,
#pod returning it as a reference to a SCALAR. It also localises the
#pod newlines as it does this, so files from different operating
#pod systems should read as you expect.
#pod
#pod Returns a SCALAR reference, or C<undef> on error.
#pod
#pod =cut

sub read {
	my $self    = shift;
	my $file    = $self->_path(shift) or return undef;
	require File::Flat;
	my $content = File::Flat->slurp($file) or return undef;
	$$content =~ s/\015{1,2}\012|\015|\012/\n/g;
	$content;
}

#pod =pod
#pod
#pod =head2 write $file, $content
#pod
#pod The C<write> method writes a string to a file in one hit, creating
#pod it and it's path if needed.
#pod
#pod =cut

sub write {
	my $self = shift;
	my $file = $self->_path(shift) or return undef;
	if ( -f $file and ! -w $file ) {
		File::Remove::remove($file) or return undef;

	}
	require File::Flat;
	my $rv = File::Flat->write( $file, @_ );
	if ( $rv and $self->readonly ) {
		File::chmod::symchmod('a-w', $file);
	}
	return $rv;
}

#pod =pod
#pod
#pod =head2 class_file $class
#pod
#pod Assuming your input FileHandler is pointing at the root directory
#pod of a lib path (meaning that My::Module will be located at My/Module.pm
#pod within it) the C<class_file> method will take a class name, and check to see
#pod if the file for that class exists in the FileHandler.
#pod
#pod Returns a reference to an ARRAY containing the filename if it exists,
#pod or C<undef> on error.
#pod
#pod =cut

sub class_file {
	my $self   = shift;
	my $_class = defined $_[0] ? shift : return undef;
	my $file   = File::Spec->catfile( split /(?:::|')/, $_class ) . '.pm';
	$self->exists_file($file) and [ $file ];
}

#pod =pod
#pod
#pod =head2 find $class
#pod
#pod The C<find> method takes as argument a directory root class, and then scans within
#pod the input FileHandler to find all files contained in that class or any
#pod other classes under it's namespace.
#pod
#pod Returns a reference to an ARRAY containing all the files within the class,
#pod or C<undef> on error.
#pod
#pod =cut

sub find {
	my $self  = shift;
	my $dir   = $self->exists_dir($_[0]) ? shift : return undef;

	# Search within the path
	require File::Find::Rule;
	my @files = File::Find::Rule->file
	                            ->name('*.pm')
	                            ->relative
	                            ->in( $self->_path($dir) );
	@files = map { File::Spec->catfile( $dir, $_ ) } sort @files;
	return \@files;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Inline::IO::File - Test::Inline Local Filesystem IO Handler

=head1 VERSION

version 2.214

=head1 DESCRIPTION

B<Test::Inline::IO::File> is the default IO handler for L<Test::Inline>.

L<Test::Inline> 2.0 was conceived in an enterprise setting, and retains
the flexibilty, power, and bulk that this created, although for most
users the power and complexity that is available is largely hidden away
under multiple layers of sensible defaults.

The intent with the C<InputHandler> and C<OutputHandle> parameters is to
allow L<Test::Inline> to be able to pull source data from anywhere, and
write the resulting test scripts to anywhere.

Until a more powerful pure-OO file-system API comes along, this module
serves as a minimalist implementation of the subset of functionality
that L<Test::Inline> needs in order to work.

An alternative IO Handler class need not subclass this one (although it
is recommended), merely implement the same interface, taking whatever
alternative arguments to the C<new> constructor that it wishes.

All methods in this class are provided with unix-style paths, and should do
the translating to the underlying filesystem themselves if required.

=head1 METHODS

=head2 new

  # Simplified usage
  $io_handler = Test::Inline::IO::File->new( $path );
  
  # Full key/value usage
  $io_handler = Test::Inline::IO::File->new(
          path     => $path,
          readonly => 1,
  );

The C<new> constructor takes a root path on the local filesystem
and returns a new C<Test::Inline::IO::File> object to that
location.

=head2 exists_file $file

The C<exists_file> method checks to see if a particular file currently
exists in the input handler.

Returns true if it exists, or false if not.

=head2 exists_dir $dir

The C<exists_dir> method checks to see if a particular directory currently
exists in the input handler.

Returns true if it exists, or false if not.

=head2 read $file

The C<read> method reads in the entire contents of a single file,
returning it as a reference to a SCALAR. It also localises the
newlines as it does this, so files from different operating
systems should read as you expect.

Returns a SCALAR reference, or C<undef> on error.

=head2 write $file, $content

The C<write> method writes a string to a file in one hit, creating
it and it's path if needed.

=head2 class_file $class

Assuming your input FileHandler is pointing at the root directory
of a lib path (meaning that My::Module will be located at My/Module.pm
within it) the C<class_file> method will take a class name, and check to see
if the file for that class exists in the FileHandler.

Returns a reference to an ARRAY containing the filename if it exists,
or C<undef> on error.

=head2 find $class

The C<find> method takes as argument a directory root class, and then scans within
the input FileHandler to find all files contained in that class or any
other classes under it's namespace.

Returns a reference to an ARRAY containing all the files within the class,
or C<undef> on error.

=head1 TO DO

- Convert to using L<FSI::FileSystem> objects, once they exist

=head1 SUPPORT

See the main L<SUPPORT|Test::Inline/SUPPORT> section.

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Inline>
(or L<bug-Test-Inline@rt.cpan.org|mailto:bug-Test-Inline@rt.cpan.org>).

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
