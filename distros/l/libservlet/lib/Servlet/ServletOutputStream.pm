# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::ServletOutputStream;

$VERSION = 0;

1;
__END__

=pod

=head1 NAME

Servlet::ServletOutputStream - servlet output stream interface

=head1 SYNOPSIS

  $stream->print($string);

  $stream->println();
  $stream->println($string);

  $stream->write($string);
  $stream->write($string, $length);
  $stream->write($string, $length, $offset);

  $stream->flush();

  $stream->close();

=head1 DESCRIPTION

Provides an output stream for writing binary data to a servlet
response.

An output stream object is normally retrieved via
L<Servlet::ServletResponse/getOutputStream>.

B<NOTE:> While this is an abstract class in the Java API, the Perl API
provides it as an interface. The main difference is that the Perl
version has no constructor. Also, it merges the methods declared in
B<java.io.OutputStream> and B<javax.servlet.ServletOutputStream> into a
single interface.

=head1 METHODS

=over

=item close()

Closes the stream and releases any system resources associated with
the stream.

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an output exception occurred

=back

=item flush()

Flushes this input stream and forces any buffered output bytes to be
written out.

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an output exception occurred

=back

=item print($value)

Writes a scalar value to the client, with no carriage return-line feed
(CRLF) character at the end.

B<Parameters:>

=over

=item I<$value>

the value to send to the client

=back

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an output exception occurred

=back

=item println([$value])

Writes a scalar value to the client, if specified, followed by a
carriage return-line feed (CRLF) character.

B<Parameters:>

=over

=item I<$value>

the (optional) value to send to the client

=back

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an output exception occurred

=back

=item write($value)

=item write($value, $length)

=item write($value, $length, $offset)

Writes the scalar $value to the stream.

If no arguments are specified, functions exactly equivalently to
C<print()>.

If I<$length> is specified, writes that many bytes from I<$value>. If
I<$offset> is specified, starts writing that many bytes from the
beginning of I<$value>. I<$offset> and I<$length> must not be negative,
and I<$length> must not be greater than the amount of data in
I<$value> starting from I<$offset>.

Blocks until input data is available, the end of the stream is
detected, or an exception is thrown.

B<Parameters:>

=over

=item I<$value>

a scalar value to be written

=item I<$length>

the maximum number of bytes to write

=item I<$offset>

the location in I<$value> where data is read from

=back

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an input exception occurs

=item B<Servlet::Util::IndexOutOfBoundsException>

if I<$buffer> is specified as I<undef>

=back

=back

=head1 SEE ALSO

L<Servlet::ServletResponse>,
L<Servlet::Util::Exception>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
