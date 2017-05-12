###########################################################################
#
# Win32::CtrlGUI - a Module for controlling Win32 GUIs based on Win32::Setupsup
#
###########################################################################
# Copyright 2000, 2001, 2004 Toby Ovod-Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at toby@ovod-everett.org
##########################################################################
package Win32::CtrlGUI;

use strict;

use Win32::Setupsup;

use Win32::CtrlGUI::Criteria;
use Win32::CtrlGUI::State;
use Win32::CtrlGUI::Window;


our $wait_intvl;

our $VERSION = '0.32'; # VERSION from OurPkgVersion

&init;

#ABSTRACT: Remote-control Win32 GUI applications


sub enum_windows {
	Win32::Setupsup::EnumWindows(\my @windows) or return undef;
	return (map {Win32::CtrlGUI::Window->_new($_)} @windows);
}


sub wait_for_window {
	my($criteria, $childcriteria, $timeout) = @_;

	$timeout = defined $timeout ? $timeout : -1;

	if (!ref($criteria) && !defined($childcriteria)) {
		while (1) {
			my $subtime = $timeout > 10 || $timeout < 0 ? 10 : $timeout;
			if (Win32::Setupsup::WaitForWindow($criteria, \my $window, int($subtime*1000), $wait_intvl)) {
				return Win32::CtrlGUI::Window->_new($window);
			}
			$timeout -= $subtime if $timeout > 0;
			$timeout == 0 and return undef;
		}
	} else {
		my $end_time = $timeout >= 0 ? Win32::GetTickCount()+$timeout*1000 : 0;
		while (1) {
			my $window = &get_windows($criteria, $childcriteria, 1);
			$window and return $window;

			($end_time && $end_time <= Win32::GetTickCount()) and return undef;
			Win32::Sleep($wait_intvl);
		}
	}
}


sub get_windows {
	my($criteria, $childcriteria, $justone) = @_;

	my(@retval);
	Win32::Setupsup::EnumWindows(\my @windows);

	foreach my $i (@windows) {
		Win32::Setupsup::GetWindowText($i, \my $temp);

		my $test = 0;
		if (ref $criteria eq 'CODE') {
			$_ = Win32::CtrlGUI::Window->_new($i);
			&$criteria and $test = 1;
		} elsif (ref $criteria eq 'Regexp') {
			$temp =~ /$criteria/ and $test = 1;
		} elsif (ref $criteria eq 'SCALAR') {
			$i == $Win32::CtrlGUI::Window::named_windows{${$criteria}} and $test = 1;
		} else {
			lc($temp) eq lc($criteria) and $test = 1;
		}

		if ($test) {
			my $window = Win32::CtrlGUI::Window->_new($i);
			if (!defined $childcriteria || $window->has_child($childcriteria)) {
				$justone and return $window;
				push(@retval, $window);
			}
		}
	}
	return @retval;
}

sub init {
	$wait_intvl = 100;
}


1;

__END__

=head1 NAME

Win32::CtrlGUI - Remote-control Win32 GUI applications

=head1 VERSION

This document describes version 0.32 of
Win32::CtrlGUI, released January 10, 2015
as part of Win32-CtrlGUI version 0.32.

=head1 SYNOPSIS

  use Win32::CtrlGUI

  my $window = Win32::CtrlGUI::wait_for_window(qr/Notepad/);
  $window->send_keys("!fx");

=head1 DESCRIPTION

C<Win32::CtrlGUI> makes it much easier to use C<Win32::Setupsup> to control
Win32 GUIs.  It relies completely on C<Win32::Setupsup> for its underlying
interaction with the GUI, but it provides a very powerful and somewhat
user-friendly OO interface to make things easier.

There are a number of modules in the system, so a brief overview will be
provided to make it easier to understand.

=over 4

=item C<Win32::CtrlGUI>

This module provides a set of methods for identifying and enumerating windows.

=item C<Win32::CtrlGUI::Window>

C<Win32::CtrlGUI::Window> objects represent GUI windows.  Internally, they
simply store the window handle.  Stringification is overloaded to return the
window text, whereas numification and numeric comparison are overloaded to
operate on the handle.  Friendlier versions of the methods applicable to
windows are provided.  Finally, a C<send_keys> method is provided that uses a
(IMHO) friendlier syntax (it's based on that used by WinBatch).  Instead of
sending the string C<\\ALT+\\f\\ALT-\\x>, one sends C<!fx>.  Instead of sending
C<\\RET\\>, one sends C<{ENTER}> or C<{RET}>.  Instead of sending
C<\\DOWN\\\\DOWN\\\\DOWN\\>, one can send C<{DOWN 3}>.

=item C<Win32::CtrlGUI::State>

The C<Win32::CtrlGUI::State> hierarchy of modules provides for a very powerful
state machine system for responding to windows and executing actions as a
result.  If you're using C<Win32::CtrlGUI> to script any sort of process, I
strongly encourage you to look at the documentation in
C<Win32::CtrlGUI::State>.  Yes, it's complicated.  But so is writing your own
code to deal with optional windows, sequence forking, and so forth.  For now,
there isn't much documentation.  See the demo.pl script for some ideas, and
beyond that, feel free to contact me if you have questions.

Also, there is a Tk debugger now.  It requires, of course, that Tk be
installed.  I haven't done much testing to see how it behaves on anything other
than Perl 5.6.0 with Tk 800.022.  Take a look at demotk.pl for an example.

=item C<Win32::CtrlGUI::Criteria>

The C<Win32::CtrlGUI::Criteria> hierarchy supports the C<Win32::CtrlGUI::State>
hierarchy by providing an OO interface to state criteria.

=back

=head2 Installation instructions

C<Win32::CtrlGUI> depends on C<Win32::Setupsup>, available from
http://www.cpan.org/modules/by-module/Win32/setupsup.1.0.1.0.zip, although you
might want to check that folder to see if there is a more recent version.

If you want to use the Tk debugger/observer, you will need C<Tk> and
C<Win32::API>.  Both are available from CPAN and via PPM.

Standard C<Make::Maker> approach or just move everything in C<Win32> into
C<site/lib/Win32>.

=head1 METHODS

=head2 enum_windows

This method returns a list of C<Win32::CtrlGUI::Window> objects representing
the windows currently open.  It uses C<Win32::Setupsup::EnumWindows> for the
underlying call.

=head2 wait_for_window

This method waits a for a window matching the passed criteria.  It accepts
three parameters - criteria for the window, criteria for the child window, and
a timeout.  The last two parameters are optional.  If you need to specify a
timeout, but don't want to specify criteria for the child window, pass C<undef>
as the child window criteria.

Criteria can be one of three things:

=over

=item *

A string.  In this case, the string will be matched case insensitively against
the window title.

=item *

A regular expression.  These should be passed using the C<qr/ . . . /> syntax.

=item *

A code reference (i.e. C<sub { . . . }>).  Code references will have access to
a C<Win32::CtrlGUI::Window> object in C<$_> and should return true or false.

=back

These three formats can be used both for the window and the child window
criteria.  In the special case of a string match on the window and no child
window criteria, C<Win32::Setupsup::WaitForWindow> will be used.  In all other
cases, a busy loop is executed using the default wait interval in
C<$Win32::CtrlGUI::wait_intvl> (specified in milliseconds).

The call will return a C<Win32::CtrlGUI::Window> object if successful or
C<undef> if it timesout. If the timeout value is unspecified or negative, it
waits indefinitely.  Timeout values are specified in seconds (fractional
seconds are allowed).

=head2 get_windows

This method returns a list of all windows matching the passed criteria.  Same
criteria format as for C<wait_for_window>.  Instead of a timeout, the third
parameter is the optional justone parameter. If it is true, C<get_windows>
returns only the first window to match the criteria.  The returned windows are,
of course, C<Win32::CtrlGUI::Window> objects.

=for Pod::Coverage
init

=head1 CONFIGURATION AND ENVIRONMENT

Win32::CtrlGUI requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Win32::Setupsup>, which is available on CPAN.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Toby Ovod-Everett  S<C<< <toby AT ovod-everett.org> >>>

Win32::CtrlGUI is now maintained by
Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Win32-CtrlGUI AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Win32-CtrlGUI >>.

You can follow or contribute to Win32-CtrlGUI's development at
L<< http://github.com/madsen/win32-ctrlgui >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Toby Ovod-Everett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

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
