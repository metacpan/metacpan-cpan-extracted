use strict;
package Xpriori::XMS::ServerUtil::Solaris;
#---------------------------------------------------------------------
# new : constructor
#---------------------------------------------------------------------
sub new($)
{
  return bless {}, shift(@_);
}
#---------------------------------------------------------------------
# startServer
#---------------------------------------------------------------------
sub startServer()
{
    my (oSelf) = @_;
    my $iSts = system('/usr/openwin/bin/xterm -e sudo /etc/init.d/neocore start');
    return ($iSts)? 0 : 1;
}
#---------------------------------------------------------------------
# stopServer
#---------------------------------------------------------------------
sub stopServer()
{
    my (oSelf) = @_;
    my $iSts = system('/usr/openwin/bin/xterm -e sudo /etc/init.d/neocore stop');
    return ($iSts)? 0 : 1;
}
#---------------------------------------------------------------------
# createDb
#---------------------------------------------------------------------
sub createDb($$$)
{
  my($oSelf, $sNeoHome, $sPasswd);
  return system('/usr/openwin/bin/xterm -e ' .
       "${sNeoHome}/bin/NeoXMLUtils CreateDB_batch ${sNeoHome}/config ${sPassWd} AC_ON");
}
#---------------------------------------------------------------------
# getStatus
#---------------------------------------------------------------------
sub getStatus()
{
  my (oSelf) = @_;
  open(IN, 
    '/usr/openwin/bin/xterm -e ps -ef | ' .
    'grep NeoServer | grep -v grep | cut -d\"/\" -f6 | cut -c1-9 |')
        or die($!);
  my $sRes = <IN>;
  close IN;
  chomp($sRes);
  return ( $sRes eq 'NeoServer') 1: 0; # server is running or not
}
1;
__END__


=head1 NAME

Xpriori::XMS::ServerUtil::Solaris - subclass of Xpriori::XMS::ServerUtils for Solaris

=head1 SYNOPSIS

This module is not intended to use directly.

=head1 DESCRIPTION

subclass of Xpriori::XMS::ServerUtils for Solaris.

=head1 NOTICE

This module has not been tested yet.

=head1 AUTHOR

KAWAI,Takanori kwitknr@cpan.org

=head1 COPYRIGHT

The Xpriori::XMS::ServerUtil::Solaris module is Copyright (c) 2009 KAWAI,Takanori, Japan.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

Xpriori::XMS::ServerUtil, Xpriori::XMS::ServerUtil::Win32

=cut
