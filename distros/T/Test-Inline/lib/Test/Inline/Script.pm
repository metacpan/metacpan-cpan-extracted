package Test::Inline::Script;

=pod

=head1 NAME

Test::Inline::Script - Generate the test file for a single source file

=head1 DESCRIPTION

This class is where the heavy lifting happens to actually generating a
test file takes place. Given a source filename, this modules will load
it, parse out the relavent bits, put them into order based on the tags,
and then merge them into a test file.

=head1 METHODS

=cut

use strict;
use List::Util                     ();
use Params::Util                   qw{_ARRAY _INSTANCE};
use Algorithm::Dependency::Item    ();
use Algorithm::Dependency::Source  ();
use Algorithm::Dependency::Ordered ();

use overload 'bool' => sub () { 1 },
             '""'   => 'filename';

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '2.213';
	@ISA     = qw{
		Algorithm::Dependency::Source
		Algorithm::Dependency::Item
	};
}

# Special case, for when doing unit tests ONLY.
# Don't throw the missing files warning.
use vars qw{$NO_MISSING_DEPENDENCIES_WARNING};
BEGIN {
	$NO_MISSING_DEPENDENCIES_WARNING = '';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $File = Test::Inline::Script->new( $class, \@sections, $check_count );

The C<new> constructor takes a class name, set of Section objects and
an optional C<check_count> flag.

Returns a Test::Inline::Script object on success.
Returns C<undef> on error.

=cut

sub new {
	my $class       = shift;
	my $_class      = defined $_[0] ? shift : return undef;
	my $Sections    = _ARRAY(shift) or return undef;
	my $check_count = shift || 0;

	# Create the object
	my $self = bless {
		class       => $_class,
		setup       => [ grep {   $_->setup } @$Sections ],
		sections    => [ grep { ! $_->setup } @$Sections ],
		filename    => lc "$_class.t",
		check_count => $check_count,
		# tests     => undef,
		}, $class;
	$self->{filename} =~ s/::/_/g;

	# Verify the uniqueness of the names
	$self->_duplicate_names and return undef;

	# Warn if we have missing dependencies
	my $missing = $self->missing_dependencies;
	if ( $missing ) {
		foreach ( @$missing ) {
			next if $NO_MISSING_DEPENDENCIES_WARNING;
			print "Warning: Missing dependency '$_' in $self->{class}\n";
		}
	}

	# Quickly predetermine if there will be an unknown number
	# of unit tests in the file
	my $unknown = grep { ! defined $_->tests } @$Sections;
	unless ( $unknown or grep { $_->tests } @$Sections ) {
		$unknown = 1;
	}

	# Flag all sections that need count checking in advance
	if ( $check_count ) {
		foreach my $Section ( @$Sections ) {
			next unless defined $Section->tests;
			next unless $unknown or $check_count > 1;

			# Each count check is itself a test, so
			# increment the number of tests for the section
			# when we enable the check flag.
			$Section->{check_count} = 1;
			$Section->{tests}++;
		}
	}

	$self;
}

=pod

=head2 class

Returns the class that the test file will test

=head2 filename

  my $filename = $File->filename;

The C<filename> method returns the name of the output file that the tests
should be written to. For example, the class C<Foo::Bar> would have the
filename value C<foo_bar.t>.

=head2 config

  my $config = $File->config;

The C<config> method returns the config object for the file, assuming that 
it has one. If more than one are found, the first will be used, and any 
additional config sections discarded.

Returns a L<Test::Inline::Config> object on success, or false if the
file does not contain a config section.

=head2 setup

  my @setup = $File->setup;

The C<setup> method returns the setup sections from the file, in the same
order as in the file.

Returns a list of setup L<Test::Inline::Section> objects, the null
array C<()> if the file does not contain any setup objects.

=head2 sections

  my @sections = $File->sections;

The C<sections> method returns all normal sections from the file, in the
same order as in the file. This may not be the order they will be written
to the test file, for that you should see the C<sorted> method.

Returns a list of L<Test::Inline::Section> objects, or the null array
C<()> if the file does not contain any non-setup sections.

=cut

sub class    { $_[0]->{class}        }
sub filename { $_[0]->{filename}     }
sub config   { $_[0]->{config} || '' }
sub setup    { @{$_[0]->{setup}}     }
sub sections { @{$_[0]->{sections}}  }





#####################################################################
# Main Methods

=pod

=head2 sorted

The C<sorted> method returns all normal sections from the file, in an order
that satisfies any dependencies in the sections.

Returns a reference to an array of L<Test::Inline::Section> objects,
C<0> if the file does not contain any non-setup sections, or C<undef> on
error.

=cut

sub sorted {
	my $self = shift;
	return $self->{sorted} if $self->{sorted};

	# Handle the simple case there there are no dependencies,
	# so we don't have to load the dependency algorithm code.
	unless ( map { $_->depends } $self->sections ) {
		return $self->{sorted} = [ $self->setup, $self->sections ];
	}

	# Create the dependency algorithm object
	my $Algorithm = Algorithm::Dependency::Ordered->new(
		source         => $self,
		ignore_orphans => 1, # Be lenient to non-existant dependencies
		) or return undef;

	# Pull the schedule from the algorithm. If we get an error back, it
	# should be because there is a circular dependency.
	my $schedule = $Algorithm->schedule_all;
	unless ( $schedule ) {
		warn " (Failed to build $self->{class} test schedule) ";
		return undef;
	}

	# Index the sections by name
	my %hash = map { $_->name => $_ } grep { $_->name } $self->sections;

	# Merge together the setup, schedule, and anonymous parts into a
	# single sorted list.
	my @sorted = (
		$self->setup,
		( map { $hash{$_} } @$schedule ),
		( grep { $_->anonymous } $self->sections )
		);

	$self->{sorted} = \@sorted;
}

=pod

=head2 tests

If the number of tests for all of the sections within the file are known,
then the number of tests for the entire file can also be determined.

The C<tests> method determines if the number of tests can be known, and
if so, calculates and returns the number of tests. Returns false if the
number of tests is not known.

=cut

sub tests {
	my $self = shift;
	return $self->{tests} if exists $self->{tests};

	# Add up the tests
	my $total = 0;
	foreach my $Section ( $self->setup, $self->sections ) {
		# Return undef if section has an unknown number of tests
		return undef unless defined $Section->tests;
		$total += $Section->tests;
	}

	# If the total is zero, it's probably screwed, go with "unknown"
	$self->{tests} = $total || undef;
}

=pod

=head2 merged_content

The C<merged_content> method generates and returns the merged contents of all
the sections in the file, including the setup sections at the beginning. The
method does not return the entire file, merely the part contained in the
sections. For the full file contents, see the C<file_content> method.

Returns a string containing the merged section content on success, false
if there is no content, despite the existance of sections ( which would
have been empty ), or C<undef> on error.

=cut

sub merged_content {
	my $self = shift;
	return $self->{content} if exists $self->{content};

	# Get the sorted Test::Inline::Section objects
	my $sorted = $self->sorted or return undef;

	# Prepare
	$self->{_example_count} = 0;

	# Strip out empty sections
	@$sorted = grep { $_->content =~ /\S/ } @$sorted;

	# Generate wrapped code chunks
	my @content = map { $self->_wrap_content($_) } @$sorted;
	return '' unless @content;

	# Merge to create the core testing code
	$self->{content} = join "\n\n\n", @content;

	# Clean up and return
	delete $self->{_example_count};
	$self->{content};
}

# Take a single generated section of code, and wrap it
# in the standard boilerplate.
sub _wrap_content {
	my $self    = shift;
	my $Section = _INSTANCE(shift, 'Test::Inline::Section') or return undef;
	my $code    = $Section->content;

	# Wrap in compilation test code if an example
	if ( $Section->example ) {
		$self->{_example_count}++;
		$code =~ s/^/    /mg;
		$code = "eval q{\n"
			. "  my \$example = sub {\n"
			. "    local \$^W = 0;\n"
			. $code
			. "  };\n"
			. "};\n"
			. "is(\$@, '', 'Example $self->{_example_count} compiles cleanly');\n";
	}

	# Wrap in scope braces unless it is a setup section
	unless ( $Section->setup ) {
		$code = "{\n"
		      . $code
		      . "}\n";
	}

	# Add the count-checking code if needed
	if ( $Section->{check_count} ) {
		my $increase = $Section->tests - 1;
		my $were     = $increase == 1 ? 'test was' : 'tests were';
		my $section  = 
		$code = "\$::__tc = Test::Builder->new->current_test;\n"
		      . $code
		      . "is( Test::Builder->new->current_test - \$::__tc, "
		        . ($increase || '0')
		        . ",\n"
		      . "\t'$increase $were run in the section' );\n";
	}

	# Add the section header
	$code = "# $Section->{begin}\n"
	      . $code;

	# Aaaaaaaand we're done
	$code;
}





#####################################################################
# Implement the Algorithm::Dependency::Source Interface
# This is used for section-level dependency.
# These methods, though public, are undocumented.

# Our implementation of Algorithm::Dependency::Source->load is a no-op
sub load { 1 }

# Pull a single item by name, section in the sections for it
sub item {
	my $self = shift;
	my $name = shift or return undef;
	List::Util::first { $_->name eq $name } $self->sections;
}

# Return, in their original order, all the items ( named sections )
sub items { grep { $_->name } $_[0]->sections }





#####################################################################
# Implement the Algorithm::Dependency::Item Interface
# This is used for class-level dependency.
# These methods, though public, are undocumented.

sub id {
	$_[0]->{class};
}

sub depends {
	my $self = shift;
	my %depends = map { $_ => 1     }
	              map { $_->classes }
	              ($self->setup, $self->sections);
	keys %depends;	
}





#####################################################################
# Utility Functions

sub _duplicate_names(@) {
	my $self = shift;
	my %seen = ();
	foreach ( map { $_->name } $self->sections ) {
		next unless $_;
		return 1 if $seen{$_}++;
	}
	undef;
}

1;

=pod

=head1 SUPPORT

See the main L<SUPPORT|Test::Inline/SUPPORT> section.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2004 - 2013 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
