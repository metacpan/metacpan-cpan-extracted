package Unix::Mknod;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Unix::Mknod qw(:all);
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	mknod major minor makedev
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} });

our @EXPORT = qw(

);

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Unix::Mknod', $VERSION);

1;
__END__

=head1 NAME

Unix::Mknod - Perl extension for mknod, major, minor, and makedev

=head1 SYNOPSIS

 use Unix::Mknod qw(:all);
 use File::stat;
 use Fcntl qw(:mode);

 $st=stat('/dev/null');
 $major=major($st->rdev);
 $minor=minor($st->rdev);

 mknod('/tmp/special', S_IFCHR|0600, makedev($major,$minor+1));

=head1 DESCRIPTION

This module allows access to the device routines major()/minor()/makedev()
that may or may not be macros in .h files.    

It also allows access to the C<mknod(2)> system call.

=head1 FUNCTIONS

=over 4

=item I<mknod($filename, $mode, $rdev)>

Creates a block or character device special file named I<$filename>. 
Must be run as a privileged user, usually I<root>.  Returns 0 on success
and -1 on failure, like C<POSIX::mkfifo> does.

=item I<$major = major($rdev)>

Returns the major number for the device special file as defined by the 
st_rdev field from the C<stat(3)> call.

=item I<$minor = minor($rdev)>

Returns the minor number for the device special file as defined by the 
st_rdev field from the C<stat(3)> call.

=item I<$rdev = makedev($major, $minor)>

Returns the st_rdev number for the device special file from the I<$major>
and I<$minor> numbers.

=back

=head1 NOTES

There are 2 other perl modules that implement the C<mknod(2)> system call,
but they have problems working on some platforms.  C<Sys::Mknod> does not
work on AIX because it uses the C<syscall(2)> generic system call which
AIX does not have.  C<Mknod> implements S_IFIFO, which on most platforms
is not implemented in C<mknod(1)>, but rather C<mkfifo(1)> (which is
implemented in POSIX perl module).

The perl module C<File::Stat::Bits> also implements major() and minor() (and
a version of makedev() called dev_join).  They are done as a program to
get the bit masks at compile time, but if major() and minor() are 
implemented as sub routines, the arugment could be something as simple
as an index to a lookup table (and thereby having no decernable relation
to its result).

=head1 BUGS

Running C<make test> as non root will not truly test the functions, as in
most UNIX like OSes, C<mknod(2)> needs to be invoked by a privelaged user, 
usually I<root>.

=head1 SEE ALSO

C<$ERRNO> or C<$!> for the specific error message.

L<File::Stat::Bits>, L<Mknod>, L<POSIX>, L<Sys::Mknod>

C<major(9)>, C<minor(9)>, C<mkfifo(1)>, C<mknod(8)>

ftp://ftp-dev.cites.uiuc.edu/pub/Unix-Mknod

=head1 AUTHOR

Jim Pirzyk, E<lt>pirzyk@uiuc.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2008 University of Illinois Board of Trustees
All rights reserved.

Developed by: Campus Information Technologies and Educational Services,
              University of Illinois at Urbana-Champaign

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
``Software''), to deal with the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimers.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimers in the
  documentation and/or other materials provided with the distribution.

* Neither the names of Campus Information Technologies and Educational
  Services, University of Illinois at Urbana-Champaign, nor the names
  of its contributors may be used to endorse or promote products derived
  from this Software without specific prior written permission.

THE SOFTWARE IS PROVIDED ``AS IS'', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR
ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS WITH THE SOFTWARE.

=cut
