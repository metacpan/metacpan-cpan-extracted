package Test::Inline::Extract;

=pod

=head1 NAME

Test::Inline::Extract - Extract relevant Pod sections from source
code.

=head1 DESCRIPTION

The Test::Inline::Extract package extracts content interesting to
L<Test::Inline> from source files.

=head1 METHODS

=cut

use strict;
use List::Util   ();
use File::Slurp  ();
use Params::Util qw{_CLASS _INSTANCE _SCALAR};

use vars qw{$VERSION};
BEGIN {
	$VERSION = '2.213';
}





#####################################################################
# Constructor

=pod

=head2 new $file | \$source

The C<new> constructor creates a new Extract object. It is passed either a
file name from which the source code would be loaded, or a reference to a
string that directly contains source code.

Returns a new C<Test::Inline::Extract> object or C<undef> on error.

=cut

sub new {
	my $class  = _CLASS(shift) or die '->new is a static method';

	# Get the source code to process, and clean it up
	my $source = $class->_source(shift) or return undef;
	$source = $$source;
	$source =~ s/(?:\015{1,2}\012|\015|\012)/\n/g;

	# Create the object
	my $self = bless {
		source   => $source,
		elements => undef,
		}, $class;

	$self;
}

sub _source {
	my $self = shift;
	return undef unless defined $_[0];
	return shift if     _SCALAR($_[0]);
	return undef if     ref $_[0];
	File::Slurp::read_file( shift, scalar_ref => 1 );
}

=pod

=head2 elements

  my $elements = $Extract->elements;

The C<elements> method extracts from the Pod any parts of the file that are
relevant to the extraction and generation process of C<Test::Inline>.

The elements will be either a package statements, or a section of inline
unit tests. They will only be returned if there is at least one section
of inline unit tests.

Returns a reference to an array of package strings and sections of inline
unit tests. Returns false if there are no sections containing inline
unit tests.

=cut

# Define the search pattern we will use
use vars qw{$search};
BEGIN {
	$search = qr/
		(?:^|\n)                           # After the beginning of the string, or a newline
		(                                  # ... start capturing
		                                   # EITHER
			package\s+                            # A package
			[^\W\d]\w*(?:(?:\'|::)[^\W\d]\w*)*    # ... with a name
			\s*;                                  # And a statement terminator
		|                                  # OR
			=for[ \t]+example[ \t]+begin\n        # ... when we find a =for example begin
			.*?                                   # ... and keep capturing
			\n=for[ \t]+example[ \t]+end\s*?      # ... until the =for example end
			(?:\n|$)                              # ... at the end of file or a newline
		|                                  # OR
			=begin[ \t]+(?:test|testing)\b        # ... when we find a =begin test or testing
			.*?                                   # ... and keep capturing
			\n=end[ \t]+(?:test|testing)\s*?      # ... until an =end tag
			(?:\n|$)                              # ... at the end of file or a newline
		)                                  # ... and stop capturing
		/isx;
}

sub elements {
	$_[0]->{elements} or
	$_[0]->{elements} = $_[0]->_elements;
}

sub _elements {
	my $self     = shift;
	my @elements = ();
	while ( $self->{source} =~ m/$search/go ) {
		push @elements, $1;
	}
	(List::Util::first { /^=/ } @elements) ? \@elements : '';
}

1;

=pod

=head1 TO DO

- For certain very complex cases, add a more intensive alternative parser
based on PPI

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
