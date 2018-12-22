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

=head1 NAME

Test::MockFile::FileHandle - Provides a class for L<Test::MockFile> to tie to on B<open> or B<sysopen>.

=head1 VERSION

Version 0.015

=cut

=head1 SYNOPSIS

This is a helper class for L<Test::MockFile>. It leverages data in the Test::MockFile namespace but
lives in its own package since it is the class that file handles are tied to when created in L<Test::MockFile>

    use Test::MockFile::FileHandle;
    tie *{ $_[0] }, 'Test::MockFile::FileHandle', $abs_path, $rw;


=head1 EXPORT

No exports are provided by this module.

=head1 SUBROUTINES/METHODS

=head2 TIEHANDLE

Args: ($class, $file, $mode)

Returns a blessed object for L<Test::MockFile> to tie against. There are no error conditions handled here.

One of the object variables tracked here is a pointer to the file contents in C<%Test::MockFile::files_being_mocked>.
In order to allow MockFiles to be DESTROYED when they go out of scope, we have to weaken this pointer.

See L<Test::MockFile> for more info.

=cut

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

=head2 PRINT

This method will be triggered every time the tied handle is printed to with the print() or say() functions.
Beyond its self reference it also expects the list that was passed to the print function.

We append to C<$Test::MockFile::files_being_mocked{$file}->{'contents'}> with what was sent. If the file
handle wasn't opened in a read mode, then this call with throw EBADF via $!

=cut

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
    foreach my $line (@list) {
        next if !defined $line;
        $self->{'data'}->{'contents'} .= $line;
    }

    return length( $self->{'data'}->{'contents'} ) - $starting_bytes;
}

=head2 PRINTF

This method will be triggered every time the tied handle is printed to with the printf() function.
Beyond its self reference it also expects the format and list that was passed to the printf function.

We use sprintf to format the output and then it is sent to L<PRINT>

=cut

sub PRINTF {
    my $self   = shift;
    my $format = shift;

    return $self->PRINT( sprintf( $format, @_ ) );
}

=head2 WRITE

This method will be called when the handle is written to via the syswrite function.

Arguments passed are:C<( $self, $buf, $len, $offset )>

This is one of the more complicated functions to mimic properly because $len and $offset have to be taken into
account. Reviewing how syswrite works reveals there are all sorts of weird corner cases.

=cut

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

=head2 READLINE

This method is called when the handle is read via <HANDLE> or readline HANDLE.

Based on the numeric location we are in the file (tell), we read until the EOF separator (C<$/>) is seen.
tell is updated after the line is read. undef is returned if tell is already at EOF.

=cut

sub READLINE {
    my ($self) = @_;

    my $tell     = $self->{'tell'};
    my $rs       = $/ // '';
    my $new_tell = index( $self->{'data'}->{'contents'}, $rs, $tell ) + length($rs);

    if ( $new_tell == 0 ) {
        $new_tell = length( $self->{'data'}->{'contents'} );
    }
    return undef if ( $new_tell == $tell );    # EOF

    my $str = substr( $self->{'data'}->{'contents'}, $tell, $new_tell - $tell );
    $self->{'tell'} = $new_tell;
    return $str;
}

=head2 GETC

B<UNIMPLEMENTED>: Open a ticket in L<github|https://github.com/cpanelinc/Test-MockFile/issues> if you need this feature.

This method will be called when the getc function is called.
It reads 1 character out of contents and adds 1 to tell. The character is returned.

=cut

sub GETC {
    my ($self) = @_;

    die('Unimplemented');
}

=head2 READ

Arguments passed are:C<( $self, $file_handle, $len, $offset )>

This method will be called when the handle is read from via the read or sysread functions.
Based on C<$offset> and C<$len>, it's possible to end up with some really weird strings with null bytes in them.

=cut

sub READ {
    my ( $self, undef, $len, $offset ) = @_;

    # If the caller's buffer is undef, we need to make it a string of 0 length to start out with.
    $_[1] = '' if !defined $_[1];    # TODO: test me

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

=head2 CLOSE

This method will be called when the handle is closed via the close function.
The object is untied and the file contents (weak reference) is removed. Further calls to this object should fail.

=cut

sub CLOSE {
    my ($self) = @_;

    delete $self->{'data'}->{'fh'};
    untie $self;

    return 1;
}

=head2 UNTIE

As with the other types of ties, this method will be called when untie happens.
It may be appropriate to "auto CLOSE" when this occurs. See The untie Gotcha below.

What's strange about the development of this class is that we were unable to determine how to trigger this call.
At the moment, the call is just redirected to CLOSE.

=cut

sub UNTIE {
    my $self = shift;

    #print STDERR "# UNTIE!\n";
    return $self->CLOSE;
}

=head2 DESTROY

As with the other types of ties, this method will be called when the tied handle is about
to be destroyed. This is useful for debugging and possibly cleaning up.

At the moment, the call is just redirected to CLOSE.

=cut

sub DESTROY {
    my ($self) = @_;

    return $self->CLOSE;
}

=head2 EOF

This method will be called when the eof function is called.
Based on C<$self-E<gt>{'tell'}>, we determine if we're at EOF.

=cut

sub EOF {
    my ($self) = @_;

    if ( !$self->{'read'} ) {
        CORE::warn(q{Filehandle STDOUT opened only for output});
    }
    return $self->{'tell'} == length $self->{'data'}->{'contents'};
}

=head2 BINMODE

B<UNIMPLEMENTED>: Open a ticket in L<github|https://github.com/cpanelinc/Test-MockFile/issues> if you need this feature.

No L<perldoc documentation|http://perldoc.perl.org/perltie.html#Tying-FileHandles> exists on this method.

=cut

sub BINMODE {
    my ($self) = @_;
    die('Unimplemented');
}

=head2 OPEN

B<UNIMPLEMENTED>: Open a ticket in L<github|https://github.com/cpanelinc/Test-MockFile/issues> if you need this feature.

No L<perldoc documentation|http://perldoc.perl.org/perltie.html#Tying-FileHandles> exists on this method.

=cut

sub OPEN {
    my ($self) = @_;
    die('Unimplemented');
}

=head2 FILENO

B<UNIMPLEMENTED>: Open a ticket in L<github|https://github.com/cpanelinc/Test-MockFile/issues> if you need this feature.

No L<perldoc documentation|http://perldoc.perl.org/perltie.html#Tying-FileHandles> exists on this method.

=cut

sub FILENO {
    my ($self) = @_;
    die('Unimplemented');
}

=head2 SEEK

Arguments passed are:C<( $self, $pos, $whence )>

Moves the location of our current tell location. 

B<$whence is UNIMPLEMENTED>: Open a ticket in L<github|https://github.com/cpanelinc/Test-MockFile/issues> if you need this feature.

No L<perldoc documentation|http://perldoc.perl.org/perltie.html#Tying-FileHandles> exists on this method.

=cut

sub SEEK {
    my ( $self, $pos, $whence ) = @_;

    if ($whence) {
        die('Unimplemented');
    }
    my $file_size = length $self->{'data'}->{'contents'};
    return if $file_size < $pos;

    $self->{'tell'} = $pos;

    return 1;
}

=head2 TELL

Returns the numeric location we are in the file. The C<TELL> tells us where we are in the file contents.

No L<perldoc documentation|http://perldoc.perl.org/perltie.html#Tying-FileHandles> exists on this method.

=cut

sub TELL {
    my ($self) = @_;
    return $self->{'tell'};
}

1;
