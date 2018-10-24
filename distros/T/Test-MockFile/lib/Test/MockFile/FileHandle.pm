# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Test::MockFile::FileHandle;

use strict;
use warnings;
use Errno qw/EBADF/;
use Scalar::Util ();

my $files_being_mocked;
{
    no warnings 'once';
    $files_being_mocked = \%Test::MockFile::files_being_mocked;
}

sub TIEHANDLE {
    my ( $class, $file, $mode ) = @_;

    length $file or die("No file name passed!");

    my $self = bless {
        'file'  => $file,
        'data'  => $files_being_mocked->{$file},
        'tell'  => 0,
        'read'  => $mode =~ m/r/ ? 1 : 0,
        'write' => $mode =~ m/w/ ? 1 : 0,
    }, $class;

    # This ref count can't hold the object from getting released.
    Scalar::Util::weaken( $self->{'data'} );

    return $self;
}

# This method will be triggered every time the tied handle is printed to with the print() or say() functions.
# Beyond its self reference it also expects the list that was passed to the print function.
sub PRINT {
    my ( $self, @list ) = @_;

    if ( !$self->{'write'} ) {

        # Filehandle $fh opened only for input at t/readline.t line 27, <$fh> line 2.
        # https://github.com/CpanelInc/Test-MockFile/issues/1
        CORE::warn("Filehandle ???? opened only for input at ???? line ???, <???> line ???.");
        $! = EBADF;
        return;
    }

    my $starting_bytes = length $self->{'data'}->{'contents'};
    $self->{'data'}->{'contents'} .= $_ foreach @list;

    return length( $self->{'data'}->{'contents'} ) - $starting_bytes;
}

# This method will be triggered every time the tied handle is printed to with the printf() function.
# Beyond its self reference it also expects the format and list that was passed to the printf function.
sub PRINTF {
    my $self   = shift;
    my $format = shift;

    return $self->PRINT( sprintf( $format, @_ ) );
}

# This method will be called when the handle is written to via the syswrite function.
sub WRITE {
    my ( $self, $buf, $len, $offset ) = @_;

    unless ( $len =~ m/^-?[0-9.]+$/ ) {
        $! = qq{Argument "$len" isn't numeric in syswrite at ??};
        return 0;
    }

    $len = int($len);    # Perl seems to do this to floats.

    if ( $len < 0 ) {
        $! = qq{Negative length at ???};
        return 0;
    }

    my $strlen = length($buf);
    $offset //= 0;

    if ( $strlen - $offset < abs($len) ) {
        $! = q{Offset outside string at ???.};
        return 0;
    }

    $offset //= 0;
    if ( $offset < 0 ) {
        $offset = $strlen + $offset;
    }

    return $self->PRINT( substr( $buf, $offset, $len ) );
}

# This method is called when the handle is read via <HANDLE> or readline HANDLE .
sub READLINE {
    my ($self) = @_;

    my $tell = $self->{'tell'};
    my $new_tell = index( $self->{'data'}->{'contents'}, $/, $tell ) + length($/);

    if ( $new_tell == 0 ) {
        $new_tell = length( $self->{'data'}->{'contents'} );
    }
    return undef if ( $new_tell == $tell );    # EOF

    my $str = substr( $self->{'data'}->{'contents'}, $tell, $new_tell - $tell );
    $self->{'tell'} = $new_tell;
    return $str;
}

# This method will be called when the getc function is called.
sub GETC {
    my ($self) = @_;

    ...;
}

# This method will be called when the handle is read from via the read or sysread functions.
sub READ {
    my ( $self, undef, $len, $offset ) = @_;

    my $contents_len = length $self->{'data'}->{'contents'};
    my $buf_len      = length $_[1];
    $offset //= 0;
    if ( $offset > $buf_len ) {
        $_[1] .= "\0" x ( $offset - $buf_len );
    }
    my $tell = $self->{'tell'};

    my $read_len = ( $contents_len - $tell < $len ) ? $contents_len - $tell : $len;

    substr( $_[1], $offset ) = substr( $self->{'data'}->{'contents'}, $tell, $read_len );

    $self->{'tell'} += $read_len;

    return $read_len;
}

# This method will be called when the handle is closed via the close function.
sub CLOSE {
    my ($self) = @_;

    delete $self->{'data'}->{'fh'};
    untie $self;

    return 1;
}

# As with the other types of ties, this method will be called when untie happens.
# It may be appropriate to "auto CLOSE" when this occurs. See The untie Gotcha below.
sub UNTIE {
    my $self = shift;
    $self->CLOSE;
    print "UNTIE!\n";
}

# As with the other types of ties, this method will be called when the tied handle is
# about to be destroyed. This is useful for debugging and possibly cleaning up.
sub DESTROY {
    my ($self) = @_;

    $self->CLOSE;
}

# This method will be called when the eof function is called.
sub EOF {
    my ($self) = @_;

    if ( !$self->{'read'} ) {
        CORE::warn(q{Filehandle STDOUT opened only for output});
    }
    return $self->{'tell'} == length $self->{'data'}->{'contents'};
}

sub BINMODE {
    my ($self) = @_;
    ...;
}

sub OPEN {
    my ($self) = @_;
    ...;
}

sub FILENO {
    my ($self) = @_;
    ...;
}

# seek FILEHANDLE, OFFSET, WHENCE
sub SEEK {
    my ( $self, $pos, $whence ) = @_;

    if ($whence) {
        ...;
    }
    my $file_size = length $self->{'data'}->{'contents'};
    return if $file_size < $pos;

    $self->{'tell'} = $pos;

    return 1;
}

sub TELL {
    my ($self) = @_;
    return $self->{'tell'};
}

1;
