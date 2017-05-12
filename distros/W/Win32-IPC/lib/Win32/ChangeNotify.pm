#---------------------------------------------------------------------
package Win32::ChangeNotify;
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
# ABSTRACT: Monitor events related to files and directories
#---------------------------------------------------------------------

use 5.006;
use strict;
use warnings;

use Carp;
use Win32::IPC 1.00 '/./';      # Import everything

BEGIN
{
  our $VERSION = '1.09';
  # This file is part of {{$dist}} {{$dist_version}} ({{$date}})

  our @ISA = qw(Win32::IPC);        # Win32::IPC isa Exporter
  our @EXPORT = qw(
    FILE_NOTIFY_CHANGE_ATTRIBUTES
    FILE_NOTIFY_CHANGE_DIR_NAME
    FILE_NOTIFY_CHANGE_FILE_NAME
    FILE_NOTIFY_CHANGE_LAST_WRITE
    FILE_NOTIFY_CHANGE_SECURITY
    FILE_NOTIFY_CHANGE_SIZE
    INFINITE
  );
  our @EXPORT_OK = qw(
    wait_any wait_all
  );

  require XSLoader;
  XSLoader::load('Win32::ChangeNotify', $VERSION);
} # end BEGIN bootstrap

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    ($constname = our $AUTOLOAD) =~ s/.*:://;
    if ($constname =~ /^FILE_NOTIFY_CHANGE_/) {
        local $! = 0;
        my $val = constant($constname);
        croak("$constname is not defined by Win32::ChangeNotify") if $! != 0;
        do { local $@; eval "sub $AUTOLOAD () { $val } 1" } or die;
        goto &$AUTOLOAD;
    }
} # end AUTOLOAD

sub new {
    my ($class,$path,$subtree,$filter) = @_;

    if ($filter =~ /\A[\s|A-Z_]+\Z/i) {
        $filter = 0;
        foreach (split(/[\s|]+/, $_[3])) {
            $filter |= constant("FILE_NOTIFY_CHANGE_" . uc $_);
            carp "Invalid filter $_" if $!;
        }
    }
    _new($class,$path,$subtree,$filter);
} # end new

# Deprecated ActiveWare functions:
sub FindFirst { $_[0] = Win32::ChangeNotify->_new(@_[1..3]); }
*Close    = \&close;            # Alias close to Close
*FindNext = \&reset;            # Alias reset to FindNext

1;

=head1 NAME

Win32::ChangeNotify - Monitor events related to files and directories

=head1 VERSION

This document describes version 1.09 of
Win32::ChangeNotify, released November 15, 2014
as part of Win32-IPC version 1.11.

=head1 SYNOPSIS

	require Win32::ChangeNotify;

	$notify = Win32::ChangeNotify->new($Path,$WatchSubTree,$Events);
	$notify->wait or warn "Something failed: $!\n";
	# There has been a change.

=head1 DESCRIPTION

This module allows the user to use a Win32 change notification event
object from Perl.  This allows the Perl program to monitor events
relating to files and directory trees.

Unfortunately, the Win32 API which implements this feature does not
provide any indication of I<what> triggered the notification (as far
as I know).  If you're monitoring a directory for file changes, and
you need to know I<which> file changed, you'll have to find some other
way of determining that.  Depending on exactly what you're trying to
do, you may be able to check file timestamps to find recently changed
files.  Or, you may need to cache the directory contents somewhere and
compare the current contents to your cached copy when you receive a
change notification.

The C<wait> method and C<wait_all> & C<wait_any> functions are
inherited from the L<Win32::IPC> module.

=head2 Methods

=over 4

=item $notify = Win32::ChangeNotify->new($path, $subtree, $filter)

Constructor for a new ChangeNotification object.  C<$path> is the
directory to monitor.  If C<$subtree> is true, then all directories
under C<$path> will be monitored.  C<$filter> indicates what events
should trigger a notification.  It should be a string containing any
of the following flags (separated by whitespace and/or C<|>).

   ATTRIBUTES	Any attribute change
   DIR_NAME     Any directory name change
   FILE_NAME    Any file name change (creating/deleting/renaming)
   LAST_WRITE   Any change to a file's last write time
   SECURITY     Any security descriptor change
   SIZE         Any change in a file's size

(C<$filter> can also be an integer composed from the
C<FILE_NOTIFY_CHANGE_*> constants.)

Under Cygwin, C<$path> must be a Windows pathname, not a Cygwin
Unix-like pathname.

=item $notify->close

Shut down monitoring.  You could just C<undef $notify> instead (but
C<close> works even if there are other copies of the object).  This
happens automatically when your program exits.

=item $notify->reset

Resets the ChangeNotification object after a change has been detected.
The object will become signalled again after the next change.  (It is
OK to call this immediately after C<new>, but it is not required.)
Returns true if successful, or zero if it fails (additional error
information can be found in C<$^E>).

=item $notify->wait

See L<Win32::IPC>.  Remember to call C<reset> afterwards if you want
to continue monitoring.

=back

=head2 Deprecated Functions and Methods

Win32::ChangeNotify still supports the ActiveWare syntax, but its
use is deprecated.

=over 4

=item FindFirst($Obj,$PathName,$WatchSubTree,$Filter)

Use

  $Obj = Win32::ChangeNotify->new($PathName,$WatchSubTree,$Filter)

instead.

=item $obj->FindNext()

Use C<$obj-E<gt>reset> instead.

=item $obj->Close()

Use C<$obj-E<gt>close> instead.

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Win32::ChangeNotify requires no configuration files or environment variables.

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

=for Pod::Coverage
^constant$

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
# tmtrack-file-task: "Win32::ChangeNotify"
# End:
