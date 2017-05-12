# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::ServletInputStream;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::ServletInputStream - servlet input stream interface

=head1 SYNOPSIS

  my $byte = $stream->read();

  my $numbytes = $stream->read(\$buffer);
  my $numbytes = $stream->read(\$buffer, $offset, $length);

  my $numbytes = $stream->readLine(\$buffer, $offset, $length);

  $stream->skip($numbytes);

  if ($stream->markSupported()) {
      $stream->mark($limit);
      $stream->reset();
  }

  $stream->close();

=head1 DESCRIPTION

Provides an input stream for reading binary data from a client
request. With some protocols, such as HTTP POST and PUT, the stream
can be used to read data sent from the client.

An input stream object is normally retrieved via
L<Servlet::ServletRequest/getInputStream>.

B<NOTE:> While this is an abstract class in the Java API, the Perl API
provides it as an interface. The main difference is that the Perl
version has no constructor. Also, it merges the methods declared in
B<java.io.InputStream> and B<javax.servlet.ServletInputStream> into a
single interface.

=head1 METHODS

=over

=item close()

Closes the stream and releases any system resources associated with
the stream.

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an input exception occurs

=back

=item mark($limit)

Marks the current position in the stream. A subsequent call to
C<reset()> repositions the stream at the last marked position so that
subsequent reads re-read the same bytes.

The I<$limit> argument tells the stream to allow that many bytes to be
read before the mark position is invalidated. If more than I<$limit>
bytes are read, a call to C<reset()> will have no effect.

B<Parameters:>

=over

=item I<$limit>

the maximum number of bytest hat can be read before the marked
position becomes invalid

=back

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if marking is not supported

=back

=item markSupported()

Returns true if the stream supports C<mark()> and C<reset()>, or false
if it does not.

=item read()

=item read(\$buffer, $length)

=item read(\$buffer, $length, $offset)

If no arguments are specified, returns the next byte of data from the
stream, or I<undef> if no byte is available because the end of the stream
has been reached.

If arguments are specified, reads up to I<$length> bytes from the
stream, stores them in I<$buffer>, and returns the number of bytes
read (or I<undef> if no bytes are available because the end of the
stream has been reached).

If I<$offset> is specified, the read data is placed I<$offset> bytes
from the beginning of I<$buffer>. If I<$offset> is negative, it will
be counted backwardsd from the end of the string. If I<$offset> is
positive and greater than the length of I<$buffer>, the scalar will be
padded to the required size with I<"\0"> bytes before the result of
the read is appended.

Blocks until input data is available, the end of the stream is
detected, or an exception is thrown.

B<Parameters:>

=over

=item I<\$buffer>

a reference to a scalar buffer into which the data is read

=item I<$length>

the maximum number of bytes to read

=item I<$offset>

the location in I<$buffer> where data is written

=back

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an input exception occurs

=item B<Servlet::Util::UndefReferenceException>

if I<$buffer> is specified as I<undef>

=back

=item readLine(\$buffer, $offset, $length)

Reads the input stream one line at a time. Starting at an offset,
reads bytes into the buffer until it reads a certain number of
bytes or reaches a newline character, which it reads into the array as
well. Returns the number of bytes read, or -1 if it reaches the end of
the input stream before reading the maximum number of bytes.

B<Parameters:>

=over

=item I<$buffer>

a reference to a scalar into which data is read

=item I<$offset>

an integer specifying the byte at which the method begins reading

=item I<$length>

an integer specifying the maximum number of bytes to read

=back

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an input exception occurs

=back

=item reset

Repositions the stream to the position at the time C<mark()> was last
called on the stream.

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if the stream has not been marked, the mark has been invalidated,
or marking is not supported

=back

=item skip($num)

Skips over and discards I<$num> bytes of data from the stream and
returns the number of bytes skipped, or -1 if no bytes were skipped.

B<Parameters:>

=over

=item I<$num>

the number of bytes to skip

=back

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an input exception occurs

=back

=back

=head1 SEE ALSO

L<Servlet::ServletRequest>,
L<Servlet::Util::Exception>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
