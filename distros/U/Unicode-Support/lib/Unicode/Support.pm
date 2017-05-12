package Unicode::Support;
use strict;

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

$VERSION = '0.001';

=encoding utf8

=head1 NAME

Unicode::Support - Test various things with Unicode

=head1 SYNOPSIS

	just run the test suite

=head1 DESCRIPTION

Eventually this will be a bunch of tests to try various Unicode things
in Perl.

=head2 Things to test

characters vs. grapheme clusters

changing normalizations

=head2 Testing the core

=head3 Directories

mkdir, rmdir, file tests

=head3 Filenames

open, file test operators, globs, unlink

=over 4

=item Mac OS X

NFD

http://developer.apple.com/library/mac/#qa/qa2001/qa1235.html

http://developer.apple.com/library/mac/#technotes/tn/tn1150.html

=item Windows

No normalization

http://stackoverflow.com/questions/2050973/what-encoding-are-filenames-in-ntfs-stored-as

http://msdn.microsoft.com/en-us/library/aa365247(v=vs.85).aspx

http://www.ntfs.com/ntfs_vs_fat.htm

=item Linux

http://hektor.umcs.lublin.pl/~mikosmul/computing/articles/linux-unicode.html

http://www.gentoo.org/doc/en/utf-8.xml

http://www.linux.com/archive/feed/39912?theme=print

=item FreeBSD

=item VMS

=back

=head3 String Operations

=head3 Regular Expressions

=head3 I/O layers

=head2 Modules

=head1 TO DO


=head1 SEE ALSO

=over 4

=item UTF-8 and Unicode FAQ for Unix/Linux

http://www.cl.cam.ac.uk/~mgk25/unicode.html

=item utf8 man page (7)

http://www.kernel.org/doc/man-pages/online/pages/man7/utf8.7.html

=back

=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/unicode-support/

=head1 AUTHOR

, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE


Copyright (c) 2011, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
