# -*- Mode: Perl; indent-tabs-mode: nil; -*-

=pod

=head1 NAME

Wombat::Connector::ResponseBase - internal response base class

=head1 SYNOPSIS

  package My::Connector::Response;

  use base qw(Wombat::Connector::ResponseBase);

=head1 DESCRIPTION

Convenience base implementation of B<Wombat::Response> and
B<Servlet::ServletResponse> which can be used for most
connectors. Only connector-specific methods need to be implemented.

=cut

package Wombat::Connector::ResponseBase;

use base qw(Wombat::Response);
use fields qw(application connector contentCount error facade handle);
use fields qw(included request);
use fields qw(buffer bufferCount bufferSize characterEncoding committed);
use fields qw(contentLength contentType locale output writer);
use strict;
use warnings;

use Servlet::Util::Exception ();
use Wombat::Connector::ResponseFacade ();
use Wombat::Connector::ResponseHandle ();
use Wombat::Globals ();
use Wombat::Util::RequestUtil ();

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Connector::ResponseBase> instance,
initializing fields appropriately. If subclasses override the
constructor, they must be sure to call

  $self->SUPER::new();

=back

=cut

sub new {
    my $self = shift;
    my $facade = shift;

    $self = fields::new($self) unless ref $self;

    $self->recycle($facade);

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getApplication()

Return the Application within which this Response is being generated.

=cut

sub getApplication {
    my $self = shift;

    return $self->{application};
}

=pod

=item setApplication($application)

Set the Application within which this Response is being generated. This
must be called as soon as the appropriate Application is identified.

B<Parameters:>

=over

=item $application

the B<Wombat::Application> within which the Response is being generated

=back

=cut

sub setApplication {
    my $self = shift;
    my $application = shift;

    $self->{application} = $application;

    return 1;
}

=pod

=item getBufferSize()

Return the buffer size (in bytes) used for the response.

=cut

sub getBufferSize {
    my $self = shift;

    return $self->{bufferSize};
}

=pod

=item setBufferSize($size)

Set the preferred buffer size for the body of the response.

B<Parameters:>

=over

=item $size

the buffer size, in bytes

=back

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if content has been written to the buffer

=back

=cut

sub setBufferSize {
    my $self = shift;
    my $size = shift;

    if ($self->{bufferCount}) {
        my $msg = "setBufferSize: content in buffer";
        Servlet::Util::IllegalStateException->throw($msg);
    }
    if ($self->isCommitted()) {
        my $msg = "setBufferSize: response is committed";
        Servlet::Util::IllegalStateException->throw($msg);
    }

    $self->{bufferSize} = $size;

    return 1;
  }

=pod

=item getCharacterEncoding()

Return the character encoding used in the body of this Response, or
I<ISO-8859-1> if the character encoding is unset. The character
encoding is set explicitly with C<setContentType()> or implicity with
C<setLocale()>.

=cut

sub getCharacterEncoding {
    my $self = shift;

    return $self->{characterEncoding} || 'ISO-8859-1';
}

=pod

=item isCommitted()

Return a flag indicating if this Response has been committed.

=cut

sub isCommitted {
    my $self = shift;

    return $self->{committed};
}

=pod

=item getConnector()

Return the Connector through which this Response is returned.

=cut

sub getConnector {
    my $self = shift;

    return $self->{connector};
}

=pod

=item setConnector($connector)

Set the Connector through which this response is returned.

B<Parameters:>

=over

=item $connector

the B<Wombat::Connector> that will return the response

=back

=cut

sub setConnector {
    my $self = shift;
    my $connector = shift;

    $self->{connector} = $connector;

    return 1;
}

=pod

=item getContentCount()

Return the number of bytes actually written to the output handle.

=cut

sub getContentCount {
    my $self = shift;

    return $self->{contentCount};
}

=pod

=item getContentLength()

Return the content length, in bytes, that was set or calculated for
this Response.

=cut

sub getContentLength {
    my $self = shift;

    return $self->{contentLength};
}

=pod

=item setContentLength($len)

Set the length of the content body in this Response.

B<Parameters:>

=over

=item $len

the content length, in bytes

=back

=cut

sub setContentLength {
    my $self = shift;
    my $len = shift;

    return 1 if $self->isCommitted();
    return 1 if $self->isIncluded();

    $self->{contentLength} = $len;

    return 1;
  }

=pod

=item getContentType()

Return the MIME type that was set or calculated for this response.

=cut

sub getContentType {
    my $self = shift;

    return $self->{contentType};
}

=pod

=item setContentType($type)

Set the content type of this Response. If the C<charset> parameter is
specified, the character encoding of this Response is also set.

B<Parameters:>

=over

=item $type

the MIME type of the content

=back

=cut

sub setContentType {
    my $self = shift;
    my $type = shift;

    return 1 if $self->isCommitted();
    return 1 if $self->isIncluded();

    $self->{contentType} = $type;

    my $charset = Wombat::Util::RequestUtil->parseCharacterEncoding($type);
    $self->{characterEncoding} = $charset if $charset;

    return 1;
  }

=pod

=item isError()

Return a flag indicating whether or not this is an error response.

=cut

sub isError {
    my $self = shift;

    return $self->{error};
}

=pod

=item setError()

Set a flag indicating that this Response is an error response.

=cut

sub setError {
    my $self = shift;

    $self->{error} = 1;

    return 1;
}

=pod

=item getHandle()

Return the output handle associated with this Response.

=cut

sub getHandle {
    my $self = shift;

    return $self->{handle};
}

=pod

=item setHandle($handle)

Set the output handle ssociated with this Response.

B<Parameters:>

=over

=item $handle

the B<IO::Handle> associated with this response

=back

=cut

sub setHandle {
    my $self = shift;
    my $handle = shift;

    $self->{handle} = $handle;
}

=pod

=item isIncluded()

Return a flag indicating whether or not this Response is being
processed as an include.

=cut

sub isIncluded {
    my $self = shift;

    return $self->{included};
}

=pod

=item setIncluded($flag)

Set a flag indicating whether or not this Response is being processed
as an include.

B<Parameters:>

=over

=item $flag

a boolean value indicating whether or not this response is included

=back

=cut

sub setIncluded {
    my $self = shift;
    my $flag = shift;

    $self->{included} = $flag;

    return 1;
}

=pod

=item getLocale()

Return the locale assigned to this Response.

=cut

sub getLocale {
    my $self = shift;

    return $self->{locale};
}

=pod

=item setLocale($loc)

Set the locale for this Response. The character encoding for this
Response will be set to the encoding specified by the locale.

B<Parameters:>

=over

=item $loc

the locale for the response

=back

=cut

sub setLocale {
    my $self = shift;
    my $loc = shift;

    return 1 if $self->isCommitted();
    return 1 if $self->isIncluded();

    $self->{locale} = $loc;

    # XXX: map locale to encoding and set encoding

    return 1;
  }

=pod

=item getOutputHandle()

Return the B<Servlet::ServletOutputHandle> that wraps the underlying
output handle (see C<getHandle()>. The default implementation returns a
handle created by C<createOutputHandle()>.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if the C<getWriter()> method has already been called for this response

=item B<Servlet::Util::IOException>

if an input or output exception occurred

=back

=cut

sub getOutputHandle {
    my $self = shift;

    if ($self->{writer}) {
        my $msg = "getOutputHandle: writer already obtained";
        Servlet::Util::IllegalStateException->throw($msg);
    }

    $self->{output} ||= $self->createOutputHandle();

    return $self->{output};
}

=pod

=item getRequest()

Return the Request with which this Response is associated.

=cut

sub getRequest {
    my $self = shift;

    return $self->{request};
}

=pod

=item setRequest($request)

Set the Request with which this Response is associated.

B<Parameters:>

=over

=item $request

the B<Wombat::Request> with which this response is associated

=back

=cut

sub setRequest {
    my $self = shift;
    my $request = shift;

    $self->{request} = $request;
}

=pod

=item getResponse()

Return the ServletResponse for which this object is the facade.

=cut

sub getResponse {
    my $self = shift;

    return $self->{facade};
}

=pod

=item getWriter()

Return the B<XXX> that wraps the ServletOutputHandle for this
response. The default implementation returns a B<XXX> wrapped around
the handle created by C<createOutputHandle()>.

B<Throws:>

=over

=item B<Servlet::Util::UnsupportedEncodingException>

if the charset specified in C<setContentType()> cannot be used

=item B<Servlet::Util::IllegalStateException>

if the C<getOutputHandle()> method has already been called for this
request

=item B<Servlet::Util::IOException>

if an input or output exception occurred

=back

=cut

sub getWriter {
    my $self = shift;

    return $self->{writer} if $self->{writer};

    if ($self->{output}) {
        my $msg = "getWriter: output handle already obtained";
        Servlet::Util::IllegalStateException->throw($msg);
    }

    my $encoding = $self->getCharacterEncoding();
    unless ($encoding) {
        my $msg = "getWriter: no character encoding specified";
        Servlet::Util::UnsupportedEncodingException->throw($msg);
    }
    # XXX:
    unless (uc $encoding eq 'ISO-8859-1') {
        my $msg = "getWriter: unsupported character encoding [$encoding]";
        Servlet::Util::UnsupportedEncodingException->throw($msg);
    }

    # XXX: create writer for $encoding
    $self->{writer} = $self->createOutputHandle();

    return $self->{writer};
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item createOutputHandle()

Create and return a B<Servlet::ServletOutputHandle> to write the
response content.

B<Throws:>

=over

=item Servlet::Util::IOException

if an input or output error occurs

=back

=cut

sub createOutputHandle {
    my $self = shift;

    return Wombat::Connector::ResponseHandle->new($self);
}

=pod

=item finishResponse()

Perform whatever actions are required to flush and close the output
handle or writer.

B<Throws:>

=over

=item Servlet::Util::IOException

if an input or output error occurs

=back

=cut

sub finishResponse {
    my $self = shift;

#    Wombat::Globals::DEBUG &&
#        $self->debug("finishing response");

    if ($self->{writer}) {
        $self->{writer}->flush();
        $self->{writer}->close();
    }

    if ($self->{output}) {
        $self->{output}->flush();
        $self->{output}->close();
    }

    # the underlying handle is the connector's responsibility

    return 1;
}

=pod

=item flushBuffer()

Force any content in the buffer to be written to the client. The
response is automatically committed on the first invocation of this
method.

B<Throws:>

=over

=item B<Servlet::Util::IOException>

=back

=cut

sub flushBuffer {
    my $self = shift;

    if ($self->{bufferCount}) {
        eval {
            $self->{handle}->write($self->{buffer}, $self->{bufferCount});
        };
        if ($@) {
            my $msg = "flushBuffer: problem writing to socket";
            Servlet::Util::IOException->new($msg);
        }

        undef $self->{buffer};
        $self->{bufferCount} = 0;

        unless ($self->{committed}) {
            $self->{committed} = 1;

#            Wombat::Globals::DEBUG &&
#                $self->debug("committed response");
        }
    }

    return 1;
}

=pod

=item reset()

Clear any data that exists in the content buffer and unset the
content length and content type.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if the response has already been committed

=back

=cut

sub reset {
    my $self = shift;

    return 1 if $self->isIncluded();

    $self->resetBuffer();

    $self->setContentLength(-1);
    $self->setContentType(undef);

    return 1;
}

=pod

=item resetBuffer()

Clear the content of the content buffer in the response without
modifying any other fields.

B<Throws:>

=over

=item B<Servlet::Util::IllegalStateException>

if the response has already been committed

=back

=cut

sub resetBuffer {
    my $self = shift;

    if ($self->isCommitted()) {
        my $msg = "resetBuffer: response is committed";
        Servlet::Util::IllegalStateException->throw($msg);
    }

    $self->{bufferCount} = 0;
    undef $self->{buffer};

    return 1;
}

=pod

=back

=head1 PACKAGE METHODS

These methods should only ever be called by other classes in the
B<Wombat::Connector> namespace. Other packages should use the public
API only!

=over

=item write($string, [$length, [$offset]])

Write the specified string to the content buffer and return the number
of bytes written. If the operation causes the buffer to be filled, the buffer
will be flushed (as many times as necessary).

=cut

sub write {
    my $self = shift;
    my $str = shift;
    my $length = shift || length $str;
    my $offset = shift || 0;

    return 0 unless $length;

    # if it all fits in the buffer, stick it in and we're done

    if ($length <= $self->{bufferSize} - $self->{bufferCount}) {
        $self->{buffer} .= substr($str, $offset, $length);

        $self->{bufferCount} += $length;
        $self->{contentCount} += $length;

        return $length;
    }

    # if there's more than the buffer can hold, flush it and start
    # writing buffer sized chunks

    $self->flushBuffer();

    my $iterations = $length / $self->{bufferSize};
    my $leftoverStart = $iterations * $self->{bufferSize};
    my $leftoverLen = $length - $leftoverStart;

    my $written = 0;
    for (my $i = 0; $i < $iterations; $i++) {
        $written += $self->write($str, $self->{bufferSize},
                                 $offset + ($i * $self->{bufferSize}));
    }

    # write the leftover bits, which are guaranteed to fit in the buffer

    if ($leftoverLen) {
        $written += $self->write($str, $leftoverLen, $offset + $leftoverStart);
    }

    return $written;
}

=pod

=item recycle()

Release all object references and initialize instances variables in
preparation for use or reuse of this object.

=cut

sub recycle {
    my $self = shift;
    my $facade = shift;

    # Wombat::Response instance variables
    $self->{application} = undef;
    $self->{connector} = undef;
    $self->{contentCount} = 0;
    $self->{error} = undef;
    $self->{facade} = $facade || Wombat::Connector::ResponseFacade->new($self);
    $self->{handle} = undef; # the handle to which response data is written
    $self->{included} = undef;
    $self->{request} = undef;

    # Servlet::ServletResponse instance variables
    $self->{buffer} = undef;
    $self->{bufferCount} = 0;
    $self->{bufferSize} = 1024;
    $self->{characterEncoding} = undef;
    $self->{committed} = undef;
    $self->{contentLength} = -1;
    $self->{contentType} = undef;
    $self->{locale} = undef;
    $self->{output} = undef; # the Servlet::ServletOutputHandle wrapper
    $self->{writer} = undef; # XXX: character handle

    return 1;
}

=pod

=back

=cut

# private methods

sub log {
    my $self = shift;

    $self->{connector}->log(@_) if $self->{connector};

    return 1;
}

sub debug {
    my $self = shift;

    # extra check in case we forget to check DEBUG before
    $self->log($_[0], undef, 'DEBUG') if Wombat::Globals::DEBUG;

    return 1;
}

1;
__END__

=pod

=head1 SEE ALSO

L<IO::Handle>,
L<Servlet::ServletResponse>,
L<Servlet::ServletServletOutputHandle>,
L<Servlet::Util::Exception>,
L<Wombat::Application>,
L<Wombat::Connector>,
L<Wombat::Request>,
L<Wombat::Response>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
