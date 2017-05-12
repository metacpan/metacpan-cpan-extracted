package YAML::Tiny::Stream;

=pod

=head2 NAME

YAML::Tiny::Stream - Document psuedo-streaming for YAML::Tiny

=head2 SYNOPSIS

  my $parser = YAML::Tiny::Stream->new('lots-of-documents.yml');
  
  while ( my $yaml = $parser->fetch ) {
      # Handle the document
  }

=head2 DESCRIPTION

To keep the design small and contained, L<YAML::Tiny> intentionally discards
support for streamed parsing of YAML documents.

In situations where a file contains a very large number of very small YAML
documents, B<YAML::Tiny::Stream> provides a limited implementation of streaming
that scans for YAML's --- document separators and parses them one entire
document at a time.

Please note this approach does come with caveats, as any situation in which a
triple dash occurs legitimately at the beginning of a line (such as in a quote)
may be accidently detected as a new document by mistake.

If you really do need a "proper" streaming parser, then you should see L<YAML>
or one of the other full blown YAML implementations.

=head1 METHODS

=cut

use 5.006;
use strict;
use Carp            ();
use IO::File   1.14 ();
use YAML::Tiny 1.40 ();

our $VERSION = '0.01';





######################################################################
# Constructor and Accessors

=pod

=head2 new

  my $stream = YAML::Tiny::Stream->new($file);

The C<new> constructor creates a new stream handle.

It takes a single parameter of a file name, which it will open via L<IO::File>.

In this quick initial implementation, the file handle will remain open until
the stream object is destroyed.

=cut

sub new {
	my $class  = shift;
	my $file   = shift;
	my $handle = IO::File->new($file, 'r');

	bless {
		file   => $file,
		handle => $handle,
		buffer => '',
	}, $class;
}

=pod

=head2 file

The C<file> accessor returns the original file passed to the constructor.

=cut

sub file {
	$_[0]->{file};
}

=pod

=head2 handle

The C<handle> accessor returns the IO handle being used to read in the YAML
stream.

=cut

sub handle {
	$_[0]->{handle};
}





######################################################################
# Main Methods

=pod

=head2 fetch

  my $yaml_tiny = $stream->fetch;

The C<fetch> method reads from the file until it hits the end of the next
document. This document is then passed to L<YAML::Tiny> to be parsed.

Returns a L<YAML::Tiny> object containing a single document, or C<undef> if
there are no more documents in the stream. Throws an exception if there is
an IO or parsing error.

=cut

sub fetch {
	my $self   = shift;
	my $handle = $self->{handle};
	my $buffer = $self->{buffer};

	# Fetch lines until we hit the --- for the next document
	while ( defined( my $line = <$handle> ) ) {
		if ( $line =~ /^---\s/ and length $buffer ) {
			# Stash the line for the next document
			$self->{buffer} = $line;

			# Attempt to parse the completed file
			return $self->_parse($buffer); 
		} else {
			$buffer .= $line;
		}
	}

	# Parse the final document
	if ( length $buffer ) {
		$self->{buffer} = '';
		return $self->_parse($buffer);
	}

	# Nothing left to parse
	return undef;
}

sub _parse {
	my $self = shift;
	my $yaml = YAML::Tiny->read_string(shift);
	unless ( defined $yaml ) {
		Carp::croak("Parsing Error: " . YAML::Tiny->errstr);
	}
	return $yaml;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=YAML-Tiny-Stream>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<YAML>, L<YAML::Syck>, L<Config::Tiny>, L<CSS::Tiny>,
L<http://use.perl.org/~Alias/journal/29427>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
