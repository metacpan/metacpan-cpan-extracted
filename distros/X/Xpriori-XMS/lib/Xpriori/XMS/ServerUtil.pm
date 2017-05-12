use strict;
package Xpriori::XMS::ServerUtil;
use Xpriori::XMS::Config;
use Cwd;

#---------------------------------------------------------------------
# new : constructor
#---------------------------------------------------------------------
sub new($;$)
{
  my($sClass,%hPrmW) = @_;
  my %hConf = %Xpriori::XMS::Config::_svrCnf;
  while(my($sKey, $sVal) = each(%hPrmW))
  {
    $hConf{$sKey} = $sVal;
  }
  $hConf{_OSMODULE} = _getOsModule($hConf{'OSMODULE'});
  return bless \%hConf, $sClass;
}
#---------------------------------------------------------------------
# LOAD OS-depend module 
#---------------------------------------------------------------------
sub _getOsModule($)
{
    my($sMod) = @_;
    if($sMod)
    {
        require("Xpriori/XMS/ServerUtil/${sMod}.pm");
        my $oMod;
        eval('$oMod = new Xpriori::XMS::ServerUtil::' . $sMod . ';');
        return $oMod if($oMod);
        die('Cannot load Module for ' . $sMod);
    }
    else
    {
       die('Cannot get Module for ' . $sMod);
    }
}
#---------------------------------------------------------------------
# Start Server
#---------------------------------------------------------------------
sub startServer
{
    my($oSelf) = @_;
    my $oMod = $oSelf->{_OSMODULE};
    my $iSts = $oMod->getStatus();
    return -1 if($iSts);  #if running
    return $oMod->startServer();
}
#---------------------------------------------------------------------
# Stop Server
#---------------------------------------------------------------------
sub stopServer
{
    my($oSelf) = @_;
    my $oMod = $oSelf->{_OSMODULE};
    my $iSts = $oMod->getStatus();
    return -1 unless($iSts);  #if not running
    return $oMod->stopServer();
}
#---------------------------------------------------------------------
# Create DB
#---------------------------------------------------------------------
sub createDb
{
    my($oSelf) = @_;
    my $oMod = $oSelf->{_OSMODULE};

    #1. Stop
    $oMod->stopServer();
    sleep 5;
    #2. DELETE old files
    #delete Files $NEOHOME/log/*.log, $NEOHOME/db/*
    my $sNeoHome = $oSelf->{NEOHOME};
    my $currDir = getcwd();
    chdir $sNeoHome || die "Cannot cd to $sNeoHome: $!\n";
    foreach my $sFile (<log/*.log db/*>)
    {
        unlink($sFile) || die("Cannot delete $sFile: $!");
    }
    chdir $currDir || die "Cannot cd to $currDir: $!";
    #3. Create Database
    $oMod->createDb($sNeoHome, $oSelf->{PASSWORD});
    #4. Start Server
    return $oMod->startServer();
}
1;
__END__


=head1 NAME

Xpriori::XMS::ServerUtil - Start/Stop/Get Status/Create Database of Xpriori::XMS Database

=head1 SYNOPSIS

    use strict;
    use Xpriori::XMS::ServerUtil;
    my $oSvr = Xpriori::XMS::ServerUtil->new();
    #Create DB
    print "CREATE: " . $oSvr->createDb() . "\n";
    #STOP Server
    print "STOP  : " . $oSvr->stopServer() . "\n";
    #START Server
    print "START : " . $oSvr->startServer() . "\n";

=head1 DESCRIPTION

Xpriori::XMS::ServerUtil is a module for Start/Stop/Get Status/Create Database of 
Xpriori::XMS Database

=head2 new

I<$oSvr> = Xpriori::XMS::ServerUtil->new();

Constructor. 
Creates a Xpriori::XMS::ServerUtil object.

=head2 startServer

I<$iRes> = $oSvr->startServer();

starts Xpriori::XMS server. returns 1: OK, 0: NG, -1: Already started.

=head2 stopServer

I<$iRes> = $oSvr->stopServer();

stops Xpriori::XMS server. returns 1: OK, 0: NG, -1: Already stopped.

=head2 createDb

I<$iRes> = $oSvr->createDb();

deletes old one and creates new database. 
Path of Xpriori::XMS utility and administrator's password will be read 
from Xpriori::XMS::Config.(see %Xpriori::XMS::Config::_svrCnf).

CAUTION : Existed Database will be deleted completely.

=head2 getStatus

I<$iRes> = $oSvr->getStatus();

gets 


=head1 NOTICE

This module was tested under only Win32.

=head1 SEE ALSO

Xpriori::XMS::ServerUtil::Win32, Xpriori::XMS::ServerUtil::Solaris, Xpriori::XMS::Config

=head1 AUTHOR

KAWAI,Takanori kwitknr@cpan.org

=head1 COPYRIGHT

The Xpriori::XMS::ServerUtil module is Copyright (c) 2009 KAWAI,Takanori, Japan.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
