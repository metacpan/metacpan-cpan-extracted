# $Id: Session.pm 136 2008-08-21 21:59:26Z oetiker $

package Win32::Monitoring::Session;

use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::Monitoring::Session ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
   GetLogonSessionData
   GetLogonSessionId
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.04';

bootstrap Win32::Monitoring::Session $VERSION;

# Preloaded methods go here.


use Win32::OLE qw(in);

sub GetLogonSessionId {
    my $pid = shift;   
    my $wmi= Win32::OLE->GetObject('winmgmts:\\\\.\\root\\cimv2')
        or carp("Opening wmi object $^E");
    my $sessionList =  $wmi->ExecQuery(<<"WQL_END",'WQL');
Associators of {Win32_Process='$$'}
      Where Resultclass = Win32_LogonSession 
            Assocclass = Win32_SessionProcess
WQL_END
    for my $session (in $sessionList) {
        return $session->{LogonId}
    }
    return undef;
}

1;
__END__

=head1 NAME

Win32::Monitoring::Session - Get information on the logon session

=head1 SYNOPSIS

   use Win32::Monitoring::Session qw(GetLogonSessionData GetLogonSessionId);
   my $sessionid = GetLogonSessionId($$);
   my $info = GetLogonSessionData($sessionid);
   print "Logon Time: ".localtime($info->{LogonTime});

=head1 DESCRIPTION

The Win32::Monitoring::Session module provides an interface to query Windows
for additional session information. Most notably the exact logon time which
seems to be rather difficult to get a hold of more or less portable way.

Note that windows seems to treat this kind of information as privileged. As
a normal user you can only get information about your own processes and your
own session. Admin will be better of in this respect.

=over

=item $sessionid=GetLogonSessionId($pid)

Returns the LogonSessionId for the process id specified in the argument.

=item $info_ptr=GetLogonSessionData($sessionid)

Ask the security subsystem for additional information about the
given logon session. The information is returned via hash pointer.
If there was a problem, there will be a special 'ERROR' and 'ERRORCODE' entries in the hash.
The following keys are returned if there is appropriate information available.

 UserName
 LogonDomain
 AuthenticationPackage 
 LogonTime (seconds since 1970 unix time format)

=back

=head1 SEE ALSO

Webpage: <http://oss.oetiker.ch/optools/>

=head1 COPYRIGHT

Copyright (c) 2008, 2009 by OETIKER+PARTNER AG. All rights reserved.

=head1 LICENSE

Win32::Monitoring::Session is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License 
as published by the Free Software Foundation, either version 3 of the 
License, or (at your option) any later version.

Win32::Monitoring::Session is distributed in the hope that it will 
be useful, but WITHOUT ANY WARRANTY; without even the implied warranty 
of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Win32::Monitoring::Session. If not, see 
<http://www.gnu.org/licenses/>.

=head1 AUTHORS

Tobias Oetiker,
Roman Plessl

=cut

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4
