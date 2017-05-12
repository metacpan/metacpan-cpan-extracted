package Test::Inline;

=pod

=head1 NAME

Test::Inline - Embed your tests in your code, next to what is being tested

=head1 DESCRIPTION

Embedding tests allows tests to be placed near the code being tested.

This is a nice supplement to the traditional .t files.

=head2 How does it work?

C<Test::Inline> lets you write small fragments of general or
function-specific testing code, and insert it anywhere you want in your
modules, inside a specific tagged L<POD|perlpod> segment, like the
following.

  =begin testing
  
  # This code assumes we have a cpuinfo file
  ok( -f /proc/cpuinfo, 'Host has a standard /proc/cpuinfo file' );
  
  =end testing
  
  =begin testing label
  
  # Test generation of the <label> HTML tag
  is( My::HTML->label('foo'),        '<label>foo</label>',           '->label(simple) works' );
  is( My::HTML->label('bar', 'foo'), '<label for="bar">foo</label>', '->label(for) works'    );
  
  =end testing

You can add as many, or as few, of these chunks of tests as you wish.
The key condition when writing them is that they should be logically
independant of each other. Each chunk of testing code should not die
or crash if it is run before or after another chunk.

Using L<inline2test> or another test compiler, you can then transform
these chunks in a test script, or an entire tree of modules into a
complete set of standard L<Test::More>-based test scripts.

These test scripts can then be executed as normal.

=head2 What is Test::Inline good for?

C<Test::Inline> is incredibly useful for doing ad-hoc unit testing.

In any large groups of modules, you can add testing code here, there and
everywhere, anywhere you want. The next time the test compiler is run, a
new test script will just appear.

This also makes it great for testing assumptions you normally wouldn't
bother to write run-time code to test. It ensures that your assumptions
about the way Perl does some operation, or about the state of the host,
are confirmed at install-time.

If your assumption is ever wrong, it gets picked up at install-time and
based on the test failures, you can correct your assumption.

It's also extremely useful for systematically testing self-contained code.

That is, any code which can be independantly tested without the need for
external systems such as databases, and that has no side-effects on external
systems.

All of this code, written by multiple people, can then have one single set
of test files generated. You can check all the bits and pieces of a large
API, or anything you like, in fine detail.

Test::Inline also introduces the concept of unit-tested documentation.

Not only can your code be tested, but if you have a FAQ or some other
pure documentation module, you can validate that the documentation is
correct for the version of the module installed.

If the module ever changes to break the documentation, you can catch it
and correct the documentation.

=head2 What is Test::Inline bad for?

C<Test::Inline> is B<not> a complete testing solution, and there are several
types of testing you probably DON'T want to use it for.

=over

=item *

Static testing across the entire codebase

=item *

Functional testing

=item *

Tests with side-effects such as those that might change a testing database

=back

=head2 Getting Started

Because Test::Inline creates test scripts with file names that B<don't>
start with a number (for ordering purposes), the first step is to create
your normal test scripts using file names in the CPAN style of
F<01_compile.t>, F<02_main.t>, F<03_foobar.t>, and so on.

You can then add your testing fragments wherever you like throughout
your code, and use the F<inline2test> script to generate the test scripts
for the inline tests. By default the test scripts will be named after
the packages/classes that the test fragments are found in.

Tests for Class::Name will end up in the file C<class_name.t>.

These test files sit quite happily alongside your number test scripts.

When you run the test suite as you normally would, the inline scripts
will be run after the numbered tests.

=head1 METHODS

=cut

use 5.006;
use strict;
use IO::Handle                     ();
use List::Util                1.19 ();
use File::Spec                0.80 ();
use File::Slurp            9999.04 ();
use Params::Util              0.21 ();
use Algorithm::Dependency     1.02 ();
use Algorithm::Dependency::Source  ();
use Test::Inline::Util             ();
use Test::Inline::Section          ();
use Test::Inline::Script           ();
use Test::Inline::Content          ();
use Test::Inline::Content::Legacy  ();
use Test::Inline::Content::Default ();
use Test::Inline::Content::Simple  ();
use Test::Inline::Extract          ();
use Test::Inline::IO::File         ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '2.213';
	@ISA     = 'Algorithm::Dependency::Source';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $Tests = Test::Inline->new(
      verbose  => 1,
      readonly => 1,
      output   => 'auto',
      manifest => 'auto/manifest',
  );

The C<new> constructor creates a new test generation framework. Once the
constructor has been used to create the generator, the C<add_class> method
can be used to specify classes, or class heirachies, to generate tests for.

B<verbose> - The C<verbose> option causes the generator to write state and
debugging information to STDOUT as it runs.

B<manifest> - The C<manifest> option, if provided, will cause a manifest
file to be created and written to disk. The manifest file contains a list
of all the test files generated, but listed in the prefered order they
should be processed to best satisfy the class-level dependency of the
tests.

B<check_count> - The C<check_count> value controls how strictly the
test script will watch the number of tests that have been executed.

When set to false, the script does no count checking other than the
standard total count for scripts (where all section counts are known)

When set to C<1> (the default), C<Test::Inline> does smart count checking,
doing section-by-section checking for known-count sections B<only> when
the total for the entire script is not known.

When set to C<2> or higher, C<Test::Inline> does full count checking,
doing section-by-section checking for every section with a known number
of tests.

B<file_content> - The C<file_content> option should be provided as a CODE
reference, which will be passed as arguments the C<Test::Inline> object,
and a single L<Test::Inline::Script> object, and should return a string
containing the contents of the resulting test file. This will be written
to the C<OutputHandler>.

B<output> - The C<output> option provides the location of the directory
where the tests will be written to. It should both already exist, and be
writable. If using a custom C<OutputHandler>, the value of C<output> should
refer to the location B<within the OutputHandler> that the files will be
written to.

B<readonly> - The C<readonly> option, if provided, indicates that any
generated test files should be created (or set when updated) with
read-only permissions, to prevent accidentally adding to or editing the
test scripts directly (instead of via the classes).

This option is currently disabled by default, by may be enabled by default
in a future release, so if you do NOT want your tests being created as
read-only, you should explicitly set this option to false.

B<InputHandler> - The C<InputHandler> option, if provided, supplies an
alternative C<FileHandler> from which source modules are retrieved.

B<OuputHandler> - The C<OutputHandler> option, if provided, supplies an
alternative C<FileHandler> to which the resulting test scripts are written.

Returns a new C<Test::Inline> object on success.

Returns C<undef> if there is a problem with one of the options.

=cut

# For now, the various Handlers are hard-coded
sub new {
	my $class  = Params::Util::_CLASS(shift);
	my %params = @_;
	unless ( $class ) {
		die '->new is a static method';
	}

	# Create the object
	my $self = bless {
		# Return errors via exceptions?
		exception      => !! $params{exception},

		# Extensibility provided through the use of Handler classes
		InputHandler   => $params{InputHandler},
		ExtractHandler => $params{ExtractHandler},
		ContentHandler => $params{ContentHandler},
		OutputHandler  => $params{OutputHandler},

		# Store the ::TestFile objects
		Classes        => {},
	}, $class;

	# Run in verbose mode?
	$self->{verbose}  = !! $params{verbose};

	# Generate tests with read-only permissions?
	$self->{readonly} = !! $params{readonly};

	# Generate a manifest file?
	$self->{manifest} = $params{manifest} if $params{manifest};

	# Do count checking?
	$self->{check_count} = exists $params{check_count}
		? $params{check_count}
			? $params{check_count} >= 2
				? 2 # Paranoid count checking
				: 1 # Smart count checking
			: 0 # No count checking
		: 1; # Smart count checking (default)

	# Support the legacy file_content param
	if ( $params{file_content} ) {
		Params::Util::_CODE($params{file_content}) or return undef;
		$self->{ContentHandler} = Test::Inline::Content::Legacy->new(
			$params{file_content}
		) or return undef;
	}

	# Set the default Handlers
	$self->{ExtractHandler} ||= 'Test::Inline::Extract';
	$self->{ContentHandler} ||= Test::Inline::Content::Default->new;
	$self->{InputHandler}   ||= Test::Inline::IO::File->new( File::Spec->curdir );
	$self->{OutputHandler}  ||= Test::Inline::IO::File->new(
		path     => File::Spec->curdir,
		readonly => $self->{readonly},
	);

	# Where to write test file to, within the context of the OutputHandler
	$self->{output} = defined $params{output} ? $params{output} : '';

	$self;
}

=pod

=head2 exception

The C<exception> method returns a flag which indicates whether error will
be returned via exceptions.

=cut

sub exception {
	$_[0]->{exception};
}

=pod

=head2 InputHandler

The C<InputHandler> method returns the file handler object that will be
used to find and load the source code.

=cut

sub InputHandler {
	$_[0]->{InputHandler};
}

=pod

=head2 ExtractHandler

The C<ExtractHandler> accessor returns the object that will be used
to extract the test sections from the source code.

=cut

sub ExtractHandler {
	$_[0]->{ExtractHandler};
}

=pod

=head2 ContentHandler

The C<ContentHandler> accessor return the script content generation handler.

=cut

sub ContentHandler {
	$_[0]->{ContentHandler};
}

=pod

=head2 OutputHandler

The C<OutputHandler> accessor returns the file handler object that the
generated test scripts will be written to.

=cut

sub OutputHandler {
	$_[0]->{OutputHandler};
}





#####################################################################
# Test::Inline Methods

=pod

=head2 add $file, $directory, \$source, $Handle

The C<add> method is a parameter-sensitive method for adding something
to the build schedule.

It takes as argument a file path, a directory path, a reference to a SCALAR
containing perl code, or an L<IO::Handle> (or subclass) object. It will
retrieve code from the parameter as appropriate, parse it, and create zero
or more L<Test::Inline::Script> objects representing the test scripts that
will be generated for that source code.

Returns the number of test scripts added, which could be zero, or C<undef>
on error.

=cut

sub add {
	my $self   = shift;
	my $source = $self->_source(shift) or return undef;
	if ( ref $source ) {
		# Add a chunk of source code
		return $self->_add_source($source);
	} else {
		# Add a whole directory
		return $self->_add_directory($source);
	}
}

=pod

=head2 add_class

  $Tests->add_class( 'Foo::Bar' );
  $Tests->add_class( 'Foo::Bar', recursive => 1 );

The C<add_class> method adds a class to the list of those to have their tests
generated. Optionally, the C<recursive> option can be provided to add not just
the class you provide, but all classes below it as well.

Returns the number of classes found with inline tests, and added, including 
C<0> if no classes with tests are found. Returns C<undef> if an error occurs 
while adding the class or it's children.

=cut

sub add_class {
	my $self    = shift;
	my $name    = shift or return undef;
	my %options = @_;

	# Determine the files to add
	$self->_verbose("Checking $name\n");
	my $files = $options{recursive}
		? $self->InputHandler->find( $name )
		: $self->InputHandler->file( $name );
	return $files unless $files; # 0 or undef

	# Add the files
	my $added = 0;
	foreach my $file ( @$files ) {
		my $rv = $self->add( $file );
		return undef unless defined $rv;
		$added += $rv;
	}

	# Clear the caches
	delete $self->{schedule};
	delete $self->{filenames};

	$added;
}

=pod

=head2 add_all

The C<add_all> method will search the C<InputHandler> for all *.pm files,
and add them to the generation set.

Returns the total number of test scripts added, which may be zero, or
C<undef> on error.

=cut

sub add_all {
	my $self = shift;
	my $rv = eval {
		$self->_add_directory('.');
	};
	return $self->_error($@) if $@;
	return $rv;
}

# Recursively add an entire directory of files
sub _add_directory {
	my $self = shift;

	# Find all module files in the directory
	my $files = $self->InputHandler->find(shift) or return undef;

	# Add each file
	my $added = 0;
	foreach my $file ( @$files ) {
		my $source = $self->InputHandler->read($file) or return undef;
		my $rv = $self->_add_source($source);
		return undef unless defined $rv;
		$added += $rv;
	}

	$added;
}

# Actually add the source code
sub _add_source {
	my $self   = shift;
	my $source = Params::Util::_SCALAR(shift) or return undef;

	# Extract the elements from the source code
	my $Extract = $self->ExtractHandler->new( $source )
		or return $self->_error("Failed to create ExtractHandler");
	my $elements = $Extract->elements or return 0;

	# Parse the elements into sections
	my $Sections = Test::Inline::Section->parse( $elements )
		or return $self->_error("Failed to parse sections: $Test::Inline::Section::errstr");

	# Split up the Sections by class
	my %classes = ();
	foreach my $Section ( @$Sections ) {
		# All sections MUST have a package
		my $context = $Section->context
			or return $self->_error("Section does not have a package context");
		$classes{$context} ||= [];
		push @{$classes{$context}}, $Section;
	}

	# Convert the collection of Sections into class-specific test file objects
	my $added = 0;
	my $Classes = $self->{Classes};
	foreach my $_class ( keys %classes ) {
		# We can't safely spread tests for the same class across
		# different files. Error if we spot a duplicate.
		if ( $Classes->{$_class} ) {
			return $self->_error("Caught duplicate test class");
		}

		# Create a new ::TestFile object for the collection of Sections
		my $File = Test::Inline::Script->new(
			$_class,
			$classes{$_class},
			$self->{check_count}
		) or return $self->_error("Failed to create a new TestFile for '$_class'");
		$self->_verbose("Adding $File to schedule\n");
		$Classes->{$_class} = $File;
		$added++;
	}

	$added++;
}

=pod

=head2 classes

The C<classes> method returns a list of the names of all the classes that
have been added to the C<Test::Inline> object, or the null list C<()> if
nothing has been added.

=cut

sub classes {
	my $self = shift;
	sort keys %{$self->{Classes}};
}

=pod

=head2 class

For a given class name, fetches the L<Test::Inline::Script> object for that
class, if it has been added to the C<Test::Inline> object. Returns C<undef>
if the class has not been added to the C<Test::Inline> object.

=cut

sub class { $_[0]->{Classes}->{$_[1]} }

=pod

=head2 filenames

For all of the classes added, the C<filenames> method generates a map of the
filenames that the test files for the various classes should be written to.

Returns a reference to a hash with the classes as keys, and filenames as
values.

Returns C<0> if there are no files to write.

Returns C<undef> on  error.

=cut

sub filenames {
	my $self = shift;
	return $self->{filenames} if $self->{filenames};

	# Create an Algorithm::Dependency for the classes
	my $Algorithm = Algorithm::Dependency::Ordered->new(
		source         => $self,
		ignore_orphans => 1,
		) or return undef;

	# Get the build schedule
	$self->_verbose("Checking dependencies\n");
	unless ( $Algorithm->source->items ) {
		return 0;
	}
	my $schedule = $Algorithm->schedule_all or return undef;

	# Merge the test position counter with the class base names
	my %filenames = ();
	for ( my $i = 0; $i <= $#$schedule; $i++ ) {
		my $class = $schedule->[$i];
		$filenames{$class} = $self->{Classes}->{$class}->filename;
	}

	$self->{schedule}  = [ map { $filenames{$_} } @$schedule ];
	$self->{filenames} = \%filenames;
}

=pod

=head2 schedule

While the C<filenames> method generates a map of the files for the
various classes, the C<schedule> returns the list of file names in the
order in which they should actually be executed.

Returns a reference to an array containing the file names as strings.

Returns C<0> if there are no files to write.

Returns C<undef> on error.

=cut

sub schedule {
	my $self = shift;
	return $self->{schedule} if $self->{schedule};

	# Generate the file names and schedule
	$self->filenames or return undef;

	$self->{schedule};
}

=pod

=head2 manifest

The C<manifest> generates the contents of the manifest file, if it is both
wanted and needed.

Returns the contents of the manifest file as a normal string, false if it
is either not wanted or needed, or C<undef> on error.

=cut

sub manifest {
	my $self = shift;

	# Do we need to create a file?
	my $schedule = $self->schedule or return undef;
	return '' unless $self->{manifest};
	return '' unless @$schedule;

	# Each manifest entry should be listed by it's path relative to
	# the location of the manifest file.
	my $manifest_dir  = (File::Spec->splitpath($self->{manifest}))[1];
	my $relative_path = Test::Inline::Util->relative(
		$manifest_dir => $self->{output},
		);
	return undef unless defined $relative_path;

	# Generate and merge the manifest entries
	my @manifest = @$schedule;
	if ( length $relative_path ) {
		@manifest = map { File::Spec->catfile( $relative_path, $_ ) } @manifest;
	}
	join '', map { "$_\n" } @manifest;
}

=pod

=head2 save

  $Tests->save;

The C<save> method generates the test files for all classes, and saves them
to the C<output> directory.

Returns the number of test files generated. Returns C<undef> on error.

=cut

sub save {
	my $self = shift;

	# Get the file names to save to
	my $filenames = $self->filenames;
	return $filenames unless $filenames; # undef or 0

	# Write the manifest if needed
	my $manifest = $self->manifest;
	return undef unless defined $manifest;
	if ( $manifest ) {
		if ( $self->OutputHandler->write( $self->{manifest}, $manifest ) ) {
			$self->_verbose( "Wrote manifest file '$self->{manifest}'\n" );
		} else {
			$self->_verbose( "Failed to write manifest file '$self->{manifest}'\n" );
			return undef;
		}
	}

	# Write the files
	my $written = 0;
	foreach my $class ( sort keys %$filenames ) {
		$self->_save( $class ) or return undef;
		$written++;
	}

	$written;
}

sub _file {
	my $self      = shift;
	my $filenames = $self->filenames or return undef;
	$filenames->{$_[0]};
}

sub _save {
	my $self     = shift;
	my $class    = shift                or return undef;
	my $filename = $self->_file($class) or return undef;
	local $| = 1;

	# Write the file
	my $content = $self->_content($class) or return undef;
	$self->_verbose("Saving...");
	if ( $self->{output} ) {
		$filename = File::Spec->catfile( $self->{output}, $filename );
	}
	unless ( $self->OutputHandler->write( $filename, $content ) ) {
		$self->_verbose("Failed\n");
		return undef;
	}
	$self->_verbose("Done\n");

	1;
}

sub _content {
	my $self     = shift;
	my $class    = shift                or return undef;
	my $filename = $self->_file($class) or return undef;
	my $Script   = $self->class($class) or return undef;

	# Get the file content
	$self->_verbose("Generating $filename for $class...");
	my $content = $self->ContentHandler->process( $self, $Script );
	$self->_verbose("Failed\n") unless defined $content;

	$content; # content or undef
}





#####################################################################
# Implement the Algorithm::Dependency::Source Interface

sub load { 1 }
sub item { $_[0]->{Classes}->{$_[1]} }
sub items {
	my $classes = shift->{Classes};
	map { $classes->{$_} } sort keys %$classes;
}





#####################################################################
# Support Methods

# Get the source code from a variety of places
sub _source {
	my $self = shift;
	return undef unless defined $_[0];
	unless ( ref $_[0] ) {
		if ( $self->InputHandler->exists_file($_[0]) ) {
			# File path
			return $self->InputHandler->read(shift);
		} elsif ( $self->InputHandler->exists_dir($_[0]) ) {
			# Directory path
			return shift; # Handled seperately
		}
		return undef;
	}
	if ( Params::Util::_SCALAR($_[0]) ) {
		# Reference to SCALAR containing code
		return shift;
	}
	if ( Params::Util::_INSTANCE($_[0], 'IO::Handle') ) {
		my $fh   = shift;
		my $old  = $fh->input_record_separator(undef);
		my $code = $fh->getline;
		$fh->input_record_separator($old);
		return \$code;
	}

	# Unknown
	undef;
}

# Print a message if we are in verbose mode
sub _verbose {
	my $self = shift;
	return 1 unless $self->{verbose};
	print @_;
}

# Warn and return
sub _error {
	my $self = shift;
	if ( $self->exception ) {
		Carp::croak("Error: $_[0]");
	}
	$self->_verbose(map { "Error: $_" } @_);
	undef;
}

1;

=pod

=head1 BUGS

The "Extended =begin" syntax used for non-trivial sections is not formalised
as part of the POD spec yet, although it is on the track to being included.

While simple '=begin testing' sections are fine and will pass POD testing,
extended begin sections may cause POD errors.

=head1 TO DO

- Add support for C<example> sections

- Add support for C<=for> sections

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Inline>

Professional support, assistance, or customisations for large scale
uses of C<Test::Inline> are available from L<http://phase-n.com/>.

For other issues, contact the maintainer.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

Thank you to Phase N (L<http://phase-n.com/>) for permitting
the open sourcing and release of this distribution.

=head1 COPYRIGHT

Copyright 2004 - 2013 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
