package Win32::MessageLoop;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Win32::MessageLoop - A simple Windows message loop with a timeout

=head1 VERSION

Version 0.01

=cut

use vars qw(@ISA $VERSION);
#@ISA = qw(Win32::MessageLoop);

$VERSION = '0.03';

require XSLoader;
XSLoader::load('Win32::MessageLoop', $VERSION);



=head1 SYNOPSIS

When using an OLE object with L<Win32::OLE>, and making use of the WithEvents option, the calling code generally uses the C<Win32::OLE->MessageLoop>
method to wait for events to come in from the OLE object. When the task is done, whatever it is, we issue C<Win32::OLE->QuitMessageLoop>.

With some objects (especially with Internet Explorer), though, this doesn't work well. At some point, events stop coming - but C<MessageLoop> won't
break out. Ever. Until the user finally gives up. This is a problem for L<Win32::IE::Mechanize> in particular, which follows no particular
rhyme or reason in the event sequences for different types of page retrieval.

The usual alternative has been to call C<SpinMessageLoop> with intervening C<sleep> calls - but the granularity of the sleep calls means rather
poor performance for the calling code.

The obvious solution is a timeout in C<MessageLoop>. That is provided by this module. Future versions might do other fancy things with the
MessageLoop, but today I just want a timeout.

   use Win32::MessageLoop
   
   # ... set up IE object or other object for event handling
   
   Win32::MessageLoop->MessageLoop(1000);    # Go into event-mediate message loop; break out after no more than 1000 ms.
   
That's it. You also have C<SpinMessageLoop> and C<QuitMessageLoop> in this package that simply duplicate the functionality of the L<Win32::OLE>
methods of the same name.  You might well be able to mix and match these with the methods in L<Win32::OLE>; be sure to tell me what happens.
Or, you know, don't do that.

Calling MessageLoop without a timeout value or with a timeout of 0 is equivalent to no timeout (i.e. the same behavior as L<Win32::OLE>).

=head1 CLASS METHODS

=head2 Win32::MessageLoop->MessageLoop, Win32::MessageLoop->MessageLoop (timeout)

The first variant runs the loop until you call C<QuitMessageLoop>; the second times out after I<timeout> milliseconds.

=head2 Win32::MessageLoop->SpinMessageLoop

Spins the message loop, just like in L<Win32::OLE>.

=head2 Win32::MessageLoop->QuitMessageLoop

Sends a break message to the loop, just like in L<Win32::OLE>.

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-win32-messageloop at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-MessageLoop>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Win32::MessageLoop


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-MessageLoop>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-MessageLoop>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-MessageLoop>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-MessageLoop/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Win32::MessageLoop
