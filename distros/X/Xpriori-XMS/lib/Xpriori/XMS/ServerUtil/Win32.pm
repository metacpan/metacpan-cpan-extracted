use strict;
package Xpriori::XMS::ServerUtil::Win32;
use Win32::Service;
sub new($)
{
  return bless {}, shift(@_);
}
sub startServer($)
{
    my ($oSelf) = @_;
    return Win32::Service::StartService('', 'NeoServer');
}
sub stopServer($)
{
    my ($oSelf) = @_;
    return Win32::Service::StopService('', 'NeoServer');
}
sub getStatus($)
{
    my ($oSelf) = @_;
    my $iStsW = $oSelf->getStatusWin();
    return ($iStsW == 1)? 0 : 1; #STOPPED or NOT
}
sub createDb($$$)
{
  my($oSelf, $sNeoHome, $sPasswd) = @_;
  return qx{${sNeoHome}/bin/neoXMLUtils CreateDB_batch ${sNeoHome}/config ${sPasswd} AC_ON};
}
sub getStatusWin($)
{
    my ($oSelf) = @_;
    my %hRes;
    Win32::Service::GetStatus('', 'NeoServer', \%hRes);
    $hRes{CurrentStateText} = 
           $oSelf->getStatusWinTxt($hRes{CurrentState});
    return (wantarray())?  %hRes : $hRes{CurrentState};
}
sub getStatusWinTxt($$)
{
  my($oSelf, $iSts) = @_;
  my %_hStatus = (
    1 => 'SERVICE_STOPPED',
    2 => 'SERVICE_START_PENDING',
    3 => 'SERVICE_STOP_PENDING',
    4 => 'SERVICE_RUNNING', 
    5 => 'SERVICE_CONTINUE_PENDING',
    6 => 'SERVICE_PAUSE_PENDING',
    7 => 'SERVICE_PAUSED',
  );
  return $_hStatus{$iSts} if(defined($iSts));

  my %hRes;
  Win32::Service::GetStatus('', 'NeoServer', \%hRes);
  return $_hStatus{$hRes{CurrentState}};
}
1;
__END__


=head1 NAME

Xpriori::XMS::ServerUtil::Win32 - subclass of Xpriori::XMS::ServerUtils for Win32.

=head1 SYNOPSIS

This module is not intended to use directly.

=head1 DESCRIPTION

subclass of Xpriori::XMS::ServerUtils for Win32.

=head1 NOTICE

This module needs Win32::Service.

=head1 AUTHOR

KAWAI,Takanori kwitknr@cpan.org

=head1 COPYRIGHT

The Xpriori::XMS::ServerUtil::Win32 module is Copyright (c) 2009 KAWAI,Takanori, Japan.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

Xpriori::XMS::ServerUtil, Xpriori::XMS::ServerUtil::Solaris

=cut
