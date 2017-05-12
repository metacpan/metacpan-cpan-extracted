package Win32::RunAsAdmin;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Win32;
use Cwd;
use Win32::OLE;
use Devel::PL_origargv;

=head1 NAME

Win32::RunAsAdmin - Simple tools for handling Windows UAC

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Windows UAC (User Account Control) is the mechanism used by a program to request elevated privileges,
that is, to run as Administrator to make changes to the system. A program requests this when it is
executed, normally by means of a manifest embedded in the executable, which obviously doesn't work
for Perl.

Win32::RunAsAdmin allows you to fake this; you can detect if your script is running with elevated
privileges, and if not, you can request a restart with them. You can also simply use these tools to
run another process with elevated privileges.

This is still not a perfect solution, as Windows forces the new elevated process to run in a
separate console. But it's perfect for many purposes, would work beautifully for C<wperl.exe>-type
GUI programs, and still makes it easier to run I<other> things as admin.

If you simply want to make sure your script is running as admin, invocation truly couldn't be simpler:

    use Win32::RunAsAdmin qw(force);
    
Got it?  Do you want to see it again?  OK.

    use Win32::RunAsAdmin qw(force);
    
But maybe you'd rather do something else before requesting a restart with elevated privileges.

    use Win32::RunAsAdmin;
    
    if (not Win32::RunAsAdmin::check) {
       # Do some stuff... 
       Win32::RunAsAdmin::restart;
    }

But be warned: be sure you use Win32::RunAsAdmin before importing anything else that might
affect the current working directory! Otherwise Win32::RunAsAdmin won't actually know what
your original working directory was.  (It uses L<Devel::PL_origargv> to get the absolute
real command-line arguments, so that's safe.)

If you just want to use the infrastructure to run something else with elevated privileges,
that's simple, too:

    use Win32::RunAsAdmin;
    
    Win32::RunAsAdmin::run ($executable, $arguments, $directory);
    
This is also exposed as a command-line utility "elev" when you install this module.

=cut

our $starting_directory;

=head1 SUBROUTINES/METHODS

=head2 check

Call this to check whether you're already running with elevated privileges.

   if (Win32::RunAsAdmin::check) {
       # Do things to update Registry values
   } else {
       # Just read and report Registry values
   }
   
(It just uses Win32::IsAdminUser, but I find it easier to remember it like this.)

=cut

sub check { Win32::IsAdminUser(); }

=head2 run ($executable, [$arguments, [$working_directory]])

Call this to run anything with elevated privileges. C<$executable> is the full path to the
executable, C<$arguments> is a string containing the arguments to be passed to the executable,
and C<$working_directory> is the directory to run the process in (defaults to the current
directory, obviously).

=cut

sub run {
    my $shell = Win32::OLE->new("Shell.Application");
    $shell->ShellExecute (shift, shift, shift, 'runas');
}

=head2 escape_args (...)

This provides a quote-escaped string for the arguments you passed, e.g. if your
arguments are C<hi"> and C<'there>, you'll get back the string C<"hi\"" "'there">.

=cut

sub escape_args {
    return '' unless @_;
    my @args = ();
    foreach (@_) {
        my $a = $_;
        $a =~ s/"/\\"/g;
        push @args, $a;
    }
    return '"' . join ('" "', @args) . '"';
}

=head2 restart

Call this to restart the current script with its current command line in the current directory.

=cut

sub restart {
    my @actual_args = Devel::PL_origargv->get; # Thank you, Anonymous Monk!
    run (shift(@actual_args), shift(@actual_args) . ' ' . escape_args(@actual_args));
    exit;
}

sub import {
    $starting_directory = getcwd();
    restart if (defined $_[1] and $_[1] eq 'force' and not check);
}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

There is a short article going into a little more depth about different options with dealing with UAC
under Perl at L<http://www.vivtek.com/perl/perl_uac.html>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-win32-runasadmin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-RunAsAdmin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Win32::RunAsAdmin


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-RunAsAdmin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-RunAsAdmin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-RunAsAdmin>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-RunAsAdmin/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael Roberts.

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

1; # End of Win32::RunAsAdmin
