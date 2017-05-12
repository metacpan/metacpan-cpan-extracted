#---------------------------------------------------------------------
package Win32::Mutex;
#
# Copyright 1998-2012 Christopher J. Madsen
#
# Created: 3 Feb 1998 from the ActiveWare version
#   (c) 1995 Microsoft Corporation. All rights reserved.
#       Developed by ActiveWare Internet Corp., http://www.ActiveState.com
#
#   Other modifications (c) 1997 by Gurusamy Sarathy <gsar@cpan.org>
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Use Win32 mutex objects from Perl
#---------------------------------------------------------------------

use 5.006;
use strict;
use warnings;

use Win32::IPC 1.00 '/./';      # Import everything

BEGIN
{
  our $VERSION = '1.09';
  # This file is part of {{$dist}} {{$dist_version}} ({{$date}})

  our @ISA = qw(Win32::IPC);    # Win32::IPC isa Exporter
  our @EXPORT_OK = qw(
    wait_any wait_all INFINITE
  );

  require XSLoader;
  XSLoader::load('Win32::Mutex', $VERSION);
} # end BEGIN bootstrap

# Deprecated ActiveWare functions:
sub Create  { $_[0] = Win32::Mutex->new(@_[1..2]) }
sub Open  { $_[0] = Win32::Mutex->open($_[1]) }
*Release = \&release;           # Alias release to Release

1;

=head1 NAME

Win32::Mutex - Use Win32 mutex objects from Perl

=head1 VERSION

This document describes version 1.09 of
Win32::Mutex, released November 15, 2014
as part of Win32-IPC version 1.11.

=head1 SYNOPSIS

	require Win32::Mutex;

	$mutex = Win32::Mutex->new($initial,$name);
	$mutex->wait;

=head1 DESCRIPTION

This module allows access to the Win32 mutex objects.  The C<wait>
method and C<wait_all> & C<wait_any> functions are inherited from the
L<Win32::IPC> module.

=head2 Methods

=over 4

=item $mutex = Win32::Mutex->new([$initial, [$name]])

Constructor for a new mutex object.  If C<$initial> is true, requests
immediate ownership of the mutex (default false).  If C<$name> is
omitted or C<undef>, creates an unnamed mutex object.

If C<$name> signifies an existing mutex object, then C<$initial> is
ignored and the object is opened.  If this happens, C<$^E> will be set
to 183 (ERROR_ALREADY_EXISTS).

=item $mutex = Win32::Mutex->open($name)

Constructor for opening an existing mutex object.

=item $mutex->release

Release ownership of a C<$mutex>.  You should have obtained ownership
of the mutex through C<new> or one of the wait functions.  Returns
true if successful, or zero if it fails (additional error
information can be found in C<$^E>).

=item $mutex->wait([$timeout])

Wait for ownership of C<$mutex>.  See L<Win32::IPC>.

If this thread has already obtained ownership of C<$mutex>, additional
calls to C<wait> will always succeed.  You must call C<release> once
for each successful call to C<wait>.

=back

=head2 Deprecated Functions and Methods

Win32::Mutex still supports the ActiveWare syntax, but its use is
deprecated.

=over 4

=item Create($MutObj,$Initial,$Name)

Use C<$MutObj = Win32::Mutex-E<gt>new($Initial,$Name)> instead.

=item Open($MutObj,$Name)

Use C<$MutObj = Win32::Mutex-E<gt>open($Name)> instead.

=item $MutObj->Release()

Use C<$MutObj-E<gt>release> instead.

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Win32::Mutex requires no configuration files or environment variables.

It runs under 32-bit or 64-bit Microsoft Windows, either natively or
under Cygwin.

=head1 DEPENDENCIES

L<Win32::IPC>

=head1 INCOMPATIBILITIES

Prior to version 1.06, the Win32 IPC modules treated C<undef> values
differently.  In version 1.06 and later, passing C<undef> as the value
of an optional parameter is the same as omitting that parameter.  In
previous versions, C<undef> was interpreted as either the empty string
or 0 (along with a warning about "Use of uninitialized value...").

=head1 BUGS AND LIMITATIONS

Signal handlers will not be called during the C<wait> method.
See L<Win32::IPC/"BUGS AND LIMITATIONS"> for details.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Win32-IPC AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Win32-IPC >>.

You can follow or contribute to Win32-IPC's development at
L<< https://github.com/madsen/win32-ipc >>.

Loosely based on the original module by ActiveWare Internet Corp.,
L<http://www.ActiveState.com>

=head1 COPYRIGHT AND LICENSE

Copyright 1998-2014 Christopher J. Madsen

Created: 3 Feb 1998 from the ActiveWare version
  (c) 1995 Microsoft Corporation. All rights reserved.
      Developed by ActiveWare Internet Corp., http://www.ActiveState.com

  Other modifications (c) 1997 by Gurusamy Sarathy <gsar AT cpan.org>

This module is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

__END__


# Local Variables:
# tmtrack-file-task: "Win32::Mutex"
# End:
