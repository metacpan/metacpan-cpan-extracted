package Thread::Tie::Handle;

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = '0.13';
use strict;

# Load only the stuff that we really need

use load;

# Satisfy -require-

1;

#---------------------------------------------------------------------------

# Following subroutines are loaded on demand only

__END__

#---------------------------------------------------------------------------

# standard Perl features

#---------------------------------------------------------------------------
#  IN: 1 class for which to bless
#      2..N any parameters passed to open()
# OUT: 1 instantiated object

sub TIEHANDLE {

# Obtain the class
# Obtain a reference to an undefined scalar
# Bless it so we can use it to call ourselves

    my $class = shift;
    my $handle = \do { local *TIEHANDLE }; # basically rw \undef
    bless $handle,$class;

# Open it if there are any parameters
# Return the instantiated object

    $handle->OPEN( @_ ) if @_;
    $handle;
} #TIEHANDLE

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 flag: whether at end of file

sub EOF { eof( $_[0] ) } #EOF

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 position at which the filepointer is located

sub TELL { tell( $_[0] ) } #TELL

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 fileno of handle

sub FILENO { fileno( $_[0] ) } #FILENO

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 position to seek to
#      3 type of offset
# OUT: 1 result of seek()

sub SEEK { seek( $_[0],$_[1],$_[2] ) } #SEEK

#---------------------------------------------------------------------------
#  IN: 1 instantiated object

sub CLOSE { close( $_[0] ) } #CLOSE

#---------------------------------------------------------------------------
#  IN: 1 instantiated object

sub BINMODE { binmode( $_[0] ) } #BINMODE

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N any parameters passed to open()
# OUT: 1 result of open()

sub OPEN {

# Close any file that is already opened here
# Perform a 2 or 3 argument open and return the result

    $_[0]->CLOSE if defined($_[0]->FILENO);
    @_ == 2 ? open( $_[0], $_[1] ) : open( $_[0],$_[1],$_[2] );
} #OPEN

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 reference to scalar to read into
#      3 number of bytes/characters to read
#      4 offset into variable

sub READ { read( $_[0],$_[1],$_[2] ) } #READ

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 line read

sub READLINE { scalar(readline( $_[0] )) } #READLINE

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
# OUT: 1 character read

sub GETC { getc( $_[0] ) } #GETC

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N stuff to print
# OUT: 1 result

sub PRINT {

# Obtain the object
# Get local copy of what needs to be printed including extra $\ if needed
# Write the stuff that we need and return the result

    my $self = shift;
    my $buffer = join( $, || '',@_,'' ); # || to calm if $, is undef in -w
    $self->WRITE( $buffer,length($buffer),0 );
} #PRINT

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 format with which to printf
#      3..N stuff to print
# OUT: 1 result

sub PRINTF {

# Obtain the object
# Get the stuff in the right format
# Write the stuff that we need and return the result

    my $self = shift;
    my $buffer = sprintf( shift,@_ ); # can't use @_ because of tokenization
    $self->WRITE( $buffer,length($buffer),0 );
} #PRINTF

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 reference to scalar to write from
#      3 number of bytes/characters to write
#      4 offset into variable
# OUT: 1 number of bytes/characters written

sub WRITE { syswrite( $_[0],$_[1],$_[2],$_[3] ) } #WRITE

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Tie::Handle - default class for tie-ing handles to threads

=head1 DESCRIPTION

Helper class for L<Thread::Tie>.  See documentation there.

=head1 CREDITS

Implementation inspired by L<Tie::StdHandle>.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002-2003 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Thread::Tie>.

=cut
