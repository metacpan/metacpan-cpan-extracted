package Win32::Elevate;

use 5.018000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::Elevate ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Win32::Elevate', $VERSION);

# Preloaded methods go here.

1; # True! YES!
__END__
# Below is stub documentation for your module. You'd better edit it!

=encoding utf8

=head1 NAME

Win32::Elevate - Perl module for gaining higher access privilege

=head1 SYNOPSIS

  use Win32::Elevate;
  
  # Gaining NT AUTHORITY\SYSTEM privilege to access files and registry
  # entries locked away from normal users
  Win32::Elevate::BecomeSystem();
  
  # Some files and especially registry entries are not even acessible
  # by SYSTEM. We need TrustedInstaller privilege for that.
  Win32::Elevate::BecomeTI();
  
  # Do some totally not shady stuff…
  
  # Done! Go back to user context.
  Win32::Elevate::RevertToSelf();

=head1 DESCRIPTION

The purpose of this module is to provide a couple of functions to
access files and registry entries to which not even an elevated
administrative user has access to. For this to work, the current
process already needs to have elevated permissions.


B<WARNING!> If you don't know, what you are doing, this can obviously
be fatally dangerous, such as an unbootable system. So do your research
and, especially, test your code thoroughly.

=head2 Functions

=over

=item B<Win32::Elevate::BecomeSystem()>

Elevates the B<first thread> of the current process to gain
NT AUTHORITY/SYSTEM privilege.

Returns a positive value on success. On faliure, it returns C<0> and the
thread is not altered.

=item B<Win32::Elevate::BecomeTI()>

Elevates the B<first thread> of the current process to gain
NT SERVICE/TrustedInstaller privilege.

Returns a positive value on success. On faliure, it returns C<0> and the current
thread is not altered.

=item B<Win32::Elevate::RevertToSelf()>

Undoes the priviledge changes made by C<Win32::Elevate::BecomeSystem()> and/or 
C<Win32::Elevate::BecomeTI()>. The current thread reverts to the same 
privilege as before any of these two functions were called.

Returns a positive value on success. On faliure, it returns C<0> and the current
thread is not altered.

=back

=head2 Error Checking

You can check C<$^E> or use C<Win32::FormatMessage( Win32::GetLastError() )>
to get a descriptive error, but it might not be very informative. The C code
calls several Win32 APIs. Since C<$^E> is set to the latest API call, you 
won't know where it went bang!


=head1 CAVEATS

Obviously, this module only works on Windows. Also, it only works on the first
thread of the current process. So you cannot spawn another thread and expect it
to have the same privileges…

This module is tested on Windows 7 and 10.


=head1 UNDER THE HOOD

This module uses well known security design shortcomings in the Win32 API to gain privilege usually reserved for system processes. In short, a process running as an elevated user who is a member of the I<Administrator> group can obtain C<SeDebugPrivilege>. This in turn allows that process to copy and modify access tokens of system processes and use such a token to impersonate its access rights. Check the L<links|"SEE ALSO"> below for more in-depth information.

=head1 SEE ALSO

=over

=item L<https://www.tiraniddo.dev/2017/08/the-art-of-becoming-trustedinstaller.html>

=item L<https://posts.specterops.io/understanding-and-defending-against-access-token-theft-finding-alternatives-to-winlogon-exe-80696c8a73b>

=item L<https://github.com/lab52io/StopDefender>. The C code of this module is mostly adapted from this program.

=back

=head1 BUGS

The issue tracker is located on L<github|https://github.com/subjut/Win32-Elevate/issues>.

=head1 SOURCE

The source repository can be found on L<github|https://github.com/subjut/Win32-Elevate>.

=head1 AUTHOR

Daniel Just

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Daniel Just

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>


=cut
