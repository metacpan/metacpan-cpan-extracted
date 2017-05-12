package VMS::Stat;

use strict;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter AutoLoader DynaLoader);

# This allows declaration	use VMS::Stat qw( &vmsmkdir &get_fab );
# as well as 			use VMS::Stat ':all';
my %EXPORT_TAGS = ( 'all' => [ qw( &vmsmkdir &get_fab ) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = ();

$VERSION = '0.03';

bootstrap VMS::Stat $VERSION ;

1;
__END__

=head1 NAME

VMS::Stat - Perl extension for access to File Access Blocks (read-only) and HP C extensions to the mkdir() function in the C RTL.

=head1 SYNOPSIS

  use VMS::Stat qw(&vmsmkdir &get_fab);
  vmsmkdir( 'SYS$DISK:[.MARS]',0777,,1 ); # Equivalent to DCL: $ create/directory/version_limit=1 [.MARS]
  my %fab = get_fab( 'SYS$LOGIN:LOGIN.COM' );

=head1 DESCRIPTION

=over 4

=item vmsmkdir

The C<vmsmkdir> function enables you to specify optional RMS arguments
to the VMS CRTL when creating a directory.  Its operation is similar to the built-in
Perl C<mkdir> function (see L<perlfunc> for a complete description).
Up to 4 optional arguments may follow the directory name.  These arguments should 
be numbers which specify optional directory characteristics as allowed by the CRTL. 
(See the CRTL reference manual description of mkdir() and chmod() for details.)
If successful, C<vmsmkdir> returns a true value;
error occurs, it returns C<undef>.

Directory characteristic options:

=over 2

=item mode

A file protection.

=item uic

The user identification code that identifies the owner of the created directory.

=item max_versions

The maximum number of file versions to be retained in the created directory.

=item r_v_number

The volume or device on which to place the created directory if the device
is part of a volume set.

=back

=item get_fab

For an accessible file returns a keyed list of integers and bit settings 
from the File Access Block (FAB).  Many of the keys are similar to 
the item (second) argument that would be passed in a call to the C<F$FILE_ATTRIBBUTES()> 
lexical function in DCL.  Not all items supported by the lexical function are currently 
supported by C<get_fab()>.  

In particular the following are available:

=over 2

=item ai

Returns a perl true value if after image journaling is
enabled; perl false (but defined()) if disabled.

=item alq

Allocation quantity in blocks.

=item bi

Returns a perl true value if before image journaling is
enabled; perl false (but defined()) if disabled.

=item bls

Block size (for tape?).

=item ctg

Returns a perl true value if the file is contiguous;
perl false (but defined()) otherwise.

=item deq

Default extension or allocation quantity.

=item erase

Returns a perl true value if a file's contents are erased before a
file is deleted (erase regardless of lock); otherwise perl false 
(but defined) is returned.

=item fsz

Fixed header (control area) size.

=item gbc

Global buffer count.

=item mrn

Maximum record number.

=item mrs

Maximum record size.

=item org

Organization: 0 for sequential, 16 for relative,
and 32 for indexed.

=item rat

Record attributes: 1 for Fortran, 2 for CR, 4 for PRN.

=item rfm

Record format: 0 for undefined, 1 for fixed, 2 for variable,
3 for variable fixed control, 4 for stream, 5 for stream LF,
6 for stream CR.

=item ru

Returns a perl true value if recovery unit journaling is enabled; 
otherwise perl false (but defined) is returned.

=item wck

Returns a perl true value if write checking is enabled; 
otherwise perl false (but defined) is returned.

=back

C<get_fab()> is implemented via a default access mode call 
to C<sys$open()> and a call to C<sys$close()>.  If either system call 
fails for any reason (e.g. does not exist, access locked,
security blocked, etc.); the undef value will be returned.

=back

=head1 HISTORY

=over 8

=item 0.03

Included the initial (simple) get_fab() xsub.

=item 0.02

Updated the README file.

=item 0.01

Original version; created by h2xs 1.22 with options -C -c -n VMS::Stat stat.h

=back

=head1 EXAMPLE

Here is a determination of a file allocation quantity:

    use VMS::Stat qw(&get_fab);
    my %fab = get_fab('SYS$LOGIN:LOGIN.COM');
    if ( defined( $fab{'alq'} ) {
        print "Login.com has $fab{'alq'} blocks allocated.\n";
    }
    else {
        print "Was unable to call get_fab for login.com:"
    }

=head1 SEE ALSO

The VMS::Stdio extension provides VMS::Stdio::vmsopen() as
an interface to the C RTL's fopen() function.  VMS::Stdio
ships with perl for VMS.

The rms extension on CPAN also provides indexfile access.

=head1 AUTHOR

Peter Prymmer, E<lt>pprymmer at best dot comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Peter Prymmer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
