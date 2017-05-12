# Tie::MmapArray
# Copyright (C) 1999 Ford & Mason Ltd.  All rights reserved.
# You may use this software under the same terms as Perl.

package Tie::MmapArray;
$VERSION = '0.04';


use strict;
use vars qw($VERSION @ISA);
require DynaLoader;
@ISA = qw(DynaLoader);
bootstrap Tie::MmapArray $VERSION;
1;

__END__


=head1 NAME

Tie::MmapArray - mmap a file as a tied array

=head1 SYNOPSIS

    use Tie::MmapArray;

    tie @array, 'Tie::MmapArray', $filename;
    tie @array, 'Tie::MmapArray', $filename, $template;
    tie @array, 'Tie::MmapArray', $filename, { template => $template,
                                               nels     => 0,
					       mode     => "rw",
					       shared   => 1,
					       offset   => 0 };

    $len = (tied @array)->record_size;

=head1 DESCRIPTION

The Tie::MmapArray module lets you use mmap to map in a file as a perl
array rather than reading the file into dynamically allocated
memory. It depends on your operating system supporting UNIX or
POSIX.1b mmap, of course.  (Code to use the equivalent functions on
Win32 platforms has been contributed but has not been tested yet.)

The type of array elements is defined by the I<template> argument or
option.  This is a Perl pack()-style template, which defaults to "i".
The template may be an array reference, in which case the elements are
defined by pairs of name and template for each element.  A template
string may define multiple fields, in which case that element is
regarded as an array of fields (which need not be of the same type).

The following example shows the utmp file on Linux mapped to an array:

    tie @utmp, 'Tie::MmapArray', '/var/log/utmp',
        { mode     => "rw",
          template => [ ut_type    => 's',
                        ut_pid     => 'i',	# pid_t
                        ut_line    => 'a12',
                        ut_id      => 'a4',
                        ut_user    => 'a32',
                        ut_host    => 'a256',
                        ut_exit    => [ # struct exit_status
                                        e_termination => 's',
                                        e_exit        => 's' ],
                        ut_session => 'l',
                        ut_tv      => [ # struct timeval
                                        tv_sec  => 'l',
                                        tv_usec => 'l' ],
                        ut_addr_v6 => 'l4',
                        pad        => 'a20' ] };

This can be scanned as follows:

    for (my $i = 0; $i < @utmp; $i++) {
        printf("pid: %d, user: %s\n",
               $utmp[$i]->{ut_pid}, $utmp[$i]->{ut_user});
    }


The following subset of pack() template letters is supported:

=over 4

=item i

signed integer (default)

=item I

unsigned integer

=item c

signed character (one byte integer)

=item c

unsigned character (one byte integer)

=item s

signed short integer

=item S

unsigned short integer

=item n

unsigned short integer in network byte order

=item l

signed long integer

=item L

unsigned long integer

=item N

unsigned long integer in network byte order

=item f

float

=item d

double

=item aI<N>

fixed-length, null-padded ASCII string of length I<N>

=item AI<N>

fixed-length, space-padded ASCII string of length I<N>

=item ZI<N>

fixed-length, null-terminated ASCII string of length I<N>

=back

The size of the array is defined by the I<nels> option.  If this is
zero then it is calculated as the file size divided by the element
size.  

If the file size is smaller than the size required for the requested
elements then a single zero byte will be written to the final byte of
the requested size.  This seems to prevent the module dying with a
segmentation or bus error if memory is accessed beyond the end of the
file and generally results in a file with holes (unallocated blocks).
Precise details of the behaviour of the module are subject to change.


=head1 BUGS, RESTRICTIONS AND FUTURE DIRECTIONS

This is version 0.02 of the module and there are likely to be many
bugs.  The interface may change as the result of feedback.

The options I<mode> and I<shared> are not yet used.

Not all pack letters are implemented yet.

push, pop, shift, unshift, and splice operations are not yet
supported.  It is debateable whether they should be as they could be
very expensive if the mmaped file was large (say a Gigabyte or two).
Perhaps there should be an option to explicitly allow these
operations.

=head1 AUTHOR

Andrew Ford <A.Ford@ford-mason.co.uk>, 27 December 1999.

=head1 CREDITS

The module was inspired by Malcolm Beatie's Mmap module.

Reini Urban <rurban@x-ray.at> provided intial code for Win32 platforms.

=cut

