# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Test::MockFile::FileHandle;

use strict;
use warnings;
use Errno qw/EBADF EINVAL/;
use Scalar::Util ();

our $VERSION = '0.038';

my $files_being_mocked;
{
    no warnings 'once';
    $files_being_mocked = \%Test::MockFile::files_being_mocked;
}

=head1 NAME

Test::MockFile::FileHandle - Provides a class for L<Test::MockFile> to
tie to on B<open> or B<sysopen>.

=head1 VERSION

Version 0.038

=cut

=head1 SYNOPSIS

This is a helper class for L<Test::MockFile>. It leverages data in the
Test::MockFile namespace but lives in its own package since it is the
class that file handles are tied to when created in L<Test::MockFile>

    use Test::MockFile::FileHandle;
    tie *{ $_[0] }, 'Test::MockFile::FileHandle', $abs_path, $rw;


=head1 EXPORT

No exports are provided by this module.

=head1 SUBROUTINES/METHODS

=head2 TIEHANDLE

Args: ($class, $file, $mode)

Returns a blessed object for L<Test::MockFile> to tie against. There
are no error conditions handled here.

One of the object variables tracked here is a pointer to the file
contents in C<%Test::MockFile::files_being_mocked>. In order to allow
MockFiles to be DESTROYED when they go out of scope, we have to weaken
this pointer.

See L<Test::MockFile> for more info.

=cut

sub TIEHANDLE {
    my ( $class, $file, $mode ) = @_;

    length $file or die("No file name passed!");

    my $self = bless {
        'file'   => $file,
        'data'   => $files_being_mocked->{$file},
        'tell'   => 0,
        'read'   => $mode =~ m/r/ ? 1 : 0,
        'write'  => $mode =~ m/w/ ? 1 : 0,
        'append' => $mode =~ m/a/ ? 1 : 0,
    }, $class;

    # This ref count can't hold the object from getting released.
    Scalar::Util::weaken( $self->{'data'} );

    return $self;
}

=head2 PRINT

This method will be triggered every time the tied handle is printed to
with the print() or say() functions. Beyond its self reference it also
expects the list that was passed to the print function.

In append mode (C<< >> >> or C<< +>> >>), output is always written at
the end of the file contents. In other write modes, output is written
at the current tell position, overwriting existing bytes. The tell
position advances by the number of bytes written.

If the file handle wasn't opened in a write mode, this call will set
C<$!> to EBADF and return.

=cut

# _write_bytes: raw write of $output at the current tell position.
# This is the shared engine for both PRINT and WRITE.
# Returns the number of bytes written.
sub _write_bytes {
    my ( $self, $output ) = @_;

    my $data = $self->{'data'} or do {
        $! = EBADF;
        return 0;
    };

    my $tell     = $self->{'tell'};
    my $contents = \$data->{'contents'};

    if ( $self->{'append'} ) {
        # Append mode (>> / +>>): always write at end regardless of tell.
        $$contents .= $output;
        $self->{'tell'} = length $$contents;
    }
    else {
        # Overwrite at tell position (>, +<, +>).
        # Pad with null bytes if tell is past end of current contents.
        my $content_len = length $$contents;
        if ( $tell > $content_len ) {
            $$contents .= "\0" x ( $tell - $content_len );
        }
        substr( $$contents, $tell, length($output), $output );
        $self->{'tell'} = $tell + length($output);
    }

    return length($output);
}

sub PRINT {
    my ( $self, @list ) = @_;

    if ( !$self->{'write'} ) {

        # Filehandle $fh opened only for input at t/readline.t line 27, <$fh> line 2.
        # https://github.com/cpanel/Test-MockFile/issues/1
        CORE::warn("Filehandle ???? opened only for input at ???? line ???, <???> line ???.");
        $! = EBADF;
        return;
    }

    # Build the output string: join with $, (output field separator) if set.
    my $output = '';
    for my $i ( 0 .. $#list ) {
        $output .= $list[$i] if defined $list[$i];
        $output .= $, if defined $, && $i < $#list;
    }

    # Append output record separator ($\) when set explicitly by the caller.
    # Note: say() does NOT set $\ for tied handles (Perl handles its newline
    # at the C level after PRINT returns), so this only covers explicit usage.
    $output .= $\ if defined $\;

    my $data = $self->{'data'} or do {
        $! = EBADF;
        return 0;
    };

    my $bytes = $self->_write_bytes($output);
    $self->_update_write_times() if $bytes;

    return 1;
}

=head2 PRINTF

This method will be triggered every time the tied handle is printed to
with the printf() function. Beyond its self reference it also expects
the format and list that was passed to the printf function.

Per L<perlfunc/printf>, C<printf> does B<not> append C<$\> (the output
record separator), unlike C<print>. We therefore write directly via
C<_write_bytes> instead of delegating to C<PRINT>.

=cut

sub PRINTF {
    my $self   = shift;
    my $format = shift;

    if ( !$self->{'write'} ) {
        $! = EBADF;
        return;
    }

    my $data = $self->{'data'} or do {
        $! = EBADF;
        return 0;
    };

    my $bytes = $self->_write_bytes( sprintf( $format, @_ ) );
    $self->_update_write_times() if $bytes;

    return 1;
}

=head2 WRITE

This method will be called when the handle is written to via the
syswrite function.

Arguments passed are:C<( $self, $buf, $len, $offset )>

This is one of the more complicated functions to mimic properly because
$len and $offset have to be taken into account. Reviewing how syswrite
works reveals there are all sorts of weird corner cases.

=cut

sub WRITE {
    my ( $self, $buf, $len, $offset ) = @_;

    if ( !$self->{'write'} ) {
        $! = EBADF;
        return 0;
    }

    unless ( $len =~ m/^-?[0-9.]+$/ ) {
        CORE::warn(qq{Argument "$len" isn't numeric in syswrite at @{[ join ' line ', (caller)[1,2] ]}.\n});
        $! = EINVAL;
        return 0;
    }

    $len = int($len);    # Perl seems to do this to floats.

    if ( $len < 0 ) {
        CORE::warn(qq{Negative length at @{[ join ' line ', (caller)[1,2] ]}.\n});
        $! = EINVAL;
        return 0;
    }

    my $strlen = length($buf);
    $offset //= 0;

    if ( $offset < 0 ) {
        $offset = $strlen + $offset;
    }

    if ( $offset < 0 || $offset > $strlen ) {
        CORE::warn(qq{Offset outside string at @{[ join ' line ', (caller)[1,2] ]}.\n});
        $! = EINVAL;
        return 0;
    }

    # Write directly — syswrite must NOT inherit $, or $\ from PRINT.
    # Per perlapi: if len exceeds available data after offset, writes
    # only what is available (substr handles this naturally).
    my $bytes = $self->_write_bytes( substr( $buf, $offset, $len ) );
    $self->_update_write_times() if $bytes;
    return $bytes;
}

=head2 READLINE

This method is called when the handle is read via <HANDLE> or readline
HANDLE.

Based on the numeric location we are in the file (tell), we read until
the EOF separator (C<$/>) is seen. tell is updated after the line is
read. undef is returned if tell is already at EOF.

=cut

sub _READLINE_ONE_LINE {
    my ($self) = @_;

    my $data = $self->{'data'} or return undef;
    my $contents = $data->{'contents'};
    my $len      = length($contents);
    my $tell     = $self->{'tell'};

    # Slurp mode: $/ = undef — return everything from tell to end
    if ( !defined $/ ) {
        return undef if $tell >= $len;
        $self->{'tell'} = $len;
        return substr( $contents, $tell );
    }

    # Fixed-record mode: $/ = \N — read exactly N bytes
    if ( ref $/ ) {
        my $reclen = ${ $/ } + 0;
        return undef if $tell >= $len;
        my $remaining = $len - $tell;
        my $read_len  = $reclen < $remaining ? $reclen : $remaining;
        $self->{'tell'} = $tell + $read_len;
        return substr( $contents, $tell, $read_len );
    }

    # Paragraph mode: $/ = '' — read paragraphs separated by blank lines
    if ( $/ eq '' ) {
        my $pos = $tell;

        # Skip leading newlines
        while ( $pos < $len && substr( $contents, $pos, 1 ) eq "\n" ) {
            $pos++;
        }
        return undef if $pos >= $len;

        my $start    = $pos;
        my $boundary = index( $contents, "\n\n", $pos );

        if ( $boundary == -1 ) {
            # No more paragraph boundaries — return rest
            $self->{'tell'} = $len;
            return substr( $contents, $start );
        }

        # Return text up to boundary + 2 newlines (Perl collapses to exactly 2)
        my $text = substr( $contents, $start, $boundary - $start ) . "\n\n";

        # Advance past all consecutive newlines at the boundary
        $pos = $boundary;
        while ( $pos < $len && substr( $contents, $pos, 1 ) eq "\n" ) {
            $pos++;
        }
        $self->{'tell'} = $pos;

        return $text;
    }

    # Normal mode: read until $/ is found
    return undef if $tell >= $len;

    my $idx = index( $contents, $/, $tell );

    if ( $idx == -1 ) {
        # Record separator not found — return rest of string
        $self->{'tell'} = $len;
        return substr( $contents, $tell );
    }

    my $new_tell = $idx + length($/);
    $self->{'tell'} = $new_tell;
    return substr( $contents, $tell, $new_tell - $tell );
}

sub READLINE {
    my ($self) = @_;

    if ( !$self->{'read'} ) {
        my $path = $self->{'file'} // 'unknown';
        CORE::warn("Filehandle $path opened only for output");
        return;
    }

    return if $self->EOF;

    if (wantarray) {
        my @all;
        my $line = _READLINE_ONE_LINE($self);
        while ( defined $line ) {
            push @all, $line;
            $line = _READLINE_ONE_LINE($self);
        }
        $self->_update_read_time() if @all;
        return @all;
    }

    my $line = _READLINE_ONE_LINE($self);
    $self->_update_read_time() if defined $line;
    return $line;
}

=head2 GETC

This method will be called when the getc function is called. It reads 1
character out of contents and adds 1 to tell. The character is
returned. Returns undef at EOF.

=cut

sub GETC {
    my ($self) = @_;

    if ( !$self->{'read'} ) {
        my $path = $self->{'file'} // 'unknown';
        CORE::warn("Filehandle $path opened only for output");
        return undef;
    }

    return undef if $self->EOF;

    my $data = $self->{'data'} or return undef;
    my $char = substr( $data->{'contents'}, $self->{'tell'}, 1 );
    $self->{'tell'}++;
    $self->_update_read_time();

    return $char;
}

=head2 READ

Arguments passed are:C<( $self, $file_handle, $len, $offset )>

This method will be called when the handle is read from via the read or
sysread functions. Based on C<$offset> and C<$len>, it's possible to
end up with some really weird strings with null bytes in them.

=cut

sub READ {
    my ( $self, undef, $len, $offset ) = @_;

    if ( !$self->{'read'} ) {
        $! = EBADF;
        return undef;
    }

    # Validate $len the same way WRITE does — match real sysread behavior.
    unless ( $len =~ m/^-?[0-9.]+$/ ) {
        CORE::warn(qq{Argument "$len" isn't numeric in sysread at @{[ join ' line ', (caller)[1,2] ]}.\n});
        $! = EINVAL;
        return undef;
    }

    $len = int($len);

    if ( $len < 0 ) {
        CORE::warn(qq{Negative length at @{[ join ' line ', (caller)[1,2] ]}.\n});
        $! = EINVAL;
        return undef;
    }

    # If the caller's buffer is undef, we need to make it a string of 0 length to start out with.
    $_[1] = '' if !defined $_[1];

    my $data = $self->{'data'} or do {
        $! = EBADF;
        return 0;
    };

    my $contents_len = length $data->{'contents'};
    my $buf_len      = length $_[1];

    $offset //= 0;
    if ( $offset > $buf_len ) {
        $_[1] .= "\0" x ( $offset - $buf_len );
    }
    my $tell = $self->{'tell'};

    # If tell is at or past the end of contents, nothing to read (EOF)
    return 0 if $tell >= $contents_len;

    my $read_len = ( $contents_len - $tell < $len ) ? $contents_len - $tell : $len;

    substr( $_[1], $offset ) = substr( $data->{'contents'}, $tell, $read_len );

    $self->{'tell'} += $read_len;
    $self->_update_read_time() if $read_len;

    return $read_len;
}

=head2 CLOSE

This method will be called when the handle is closed via the close
function. The object is untied and the file contents (weak reference)
is removed. Further calls to this object should fail.

=cut

sub CLOSE {
    my ($self) = @_;

    # Remove this specific handle from the mock's fhs list.
    # Each handle has its own tied object, so we match by tied identity.
    # Try through the weak data ref first, then fall back to the global hash.
    my $mock = $self->{'data'};
    if ( !$mock && $self->{'file'} ) {
        $mock = $files_being_mocked->{ $self->{'file'} };
    }

    if ( $mock && $mock->{'fhs'} ) {
        @{ $mock->{'fhs'} } = grep {
            defined $_ && ( !ref $_ || ( tied( *{$_} ) || 0 ) != $self )
        } @{ $mock->{'fhs'} };
    }

    return 1;
}

=head2 UNTIE

As with the other types of ties, this method will be called when untie
happens. It may be appropriate to "auto CLOSE" when this occurs. See
The untie Gotcha below.

What's strange about the development of this class is that we were
unable to determine how to trigger this call. At the moment, the call
is just redirected to CLOSE.

=cut

sub UNTIE {
    my $self = shift;

    #print STDERR "# UNTIE!\n";
    return $self->CLOSE;
}

=head2 DESTROY

As with the other types of ties, this method will be called when the
tied handle is about to be destroyed. This is useful for debugging and
possibly cleaning up.

At the moment, the call is just redirected to CLOSE.

=cut

sub DESTROY {
    my ($self) = @_;

    # During global destruction, our weak ref or even $self may be
    # partially torn down. Guard before attempting cleanup.
    return unless $self && $self->{'file'};
    return $self->CLOSE;
}

=head2 EOF

This method will be called when the eof function is called. Based on
C<$self-E<gt>{'tell'}>, we determine if we're at EOF.

=cut

sub EOF {
    my ($self) = @_;

    my $data = $self->{'data'} or return 1;

    if ( !$self->{'read'} ) {
        my $path = $self->{'file'} // 'unknown';
        CORE::warn("Filehandle $path opened only for output");
    }
    return $self->{'tell'} >= length $data->{'contents'};
}

=head2 BINMODE

Binmode does nothing as whatever format you put the data into the file as
is how it will come out. Possibly we could decode the SV if this was done
but then we'd have to do it every time contents are altered. Please open
a ticket if you want this to do something.

No L<perldoc
documentation|http://perldoc.perl.org/perltie.html#Tying-FileHandles>
exists on this method.

=cut

sub BINMODE {
    my ($self) = @_;
    return;
}

=head2 OPEN

B<UNIMPLEMENTED>: Open a ticket in
L<github|https://github.com/cpanel/Test-MockFile/issues> if you need
this feature.

No L<perldoc
documentation|http://perldoc.perl.org/perltie.html#Tying-FileHandles>
exists on this method.

=cut

sub OPEN {
    my ($self) = @_;
    die('Unimplemented');
}

=head2 FILENO

B<UNIMPLEMENTED>: Open a ticket in
L<github|https://github.com/cpanel/Test-MockFile/issues> if you need
this feature.

No L<perldoc
documentation|http://perldoc.perl.org/perltie.html#Tying-FileHandles>
exists on this method.

=cut

sub FILENO {
    my ($self) = @_;
    die 'fileno is purposefully unsupported';
}

=head2 SEEK

Arguments passed are:C<( $self, $pos, $whence )>

Moves the location of our current tell location.

C<$whence> controls the seek origin:

=over 4

=item C<0> (SEEK_SET) - seek to C<$pos> from start of file

=item C<1> (SEEK_CUR) - seek to C<$pos> relative to current position

=item C<2> (SEEK_END) - seek to C<$pos> relative to end of file

=back

No L<perldoc
documentation|http://perldoc.perl.org/perltie.html#Tying-FileHandles>
exists on this method.

=cut

sub SEEK {
    my ( $self, $pos, $whence ) = @_;

    my $data = $self->{'data'} or do {
        $! = EBADF;
        return 0;
    };

    my $file_size = length $data->{'contents'};

    my $new_pos;

    my $SEEK_SET = 0;
    my $SEEK_CUR = 1;
    my $SEEK_END = 2;

    if ( $whence == $SEEK_SET ) {
        $new_pos = $pos;
    }
    elsif ( $whence == $SEEK_CUR ) {
        $new_pos = $self->{'tell'} + $pos;
    }
    elsif ( $whence == $SEEK_END ) {
        $new_pos = $file_size + $pos;
    }
    else {
        $! = EINVAL;
        return 0;
    }

    if ( $new_pos < 0 ) {
        return 0;
    }

    $self->{'tell'} = $new_pos;
    return $new_pos == 0 ? '0 but true' : $new_pos;
}

=head2 TELL

Returns the numeric location we are in the file. The C<TELL> tells us
where we are in the file contents.

No L<perldoc
documentation|http://perldoc.perl.org/perltie.html#Tying-FileHandles>
exists on this method.

=cut

sub TELL {
    my ($self) = @_;
    return $self->{'tell'};
}

# Update mtime and ctime after a successful write operation.
sub _update_write_times {
    my ($self) = @_;
    my $data = $self->{'data'} or return;
    my $now = time;
    $data->{'mtime'} = $now;
    $data->{'ctime'} = $now;
    return;
}

# Update atime after a successful read operation.
sub _update_read_time {
    my ($self) = @_;
    my $data = $self->{'data'} or return;
    $data->{'atime'} = time;
    return;
}

1;
