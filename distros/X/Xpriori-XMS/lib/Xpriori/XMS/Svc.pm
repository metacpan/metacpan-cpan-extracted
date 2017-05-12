package Xpriori::XMS::Svc;

use Xpriori::XMS::Http;
our $CstNeoCoreURL;
our $CstNeoCoreUsr;
our $CstNeoCorePwd;

sub _connect(;$)
{
  my ($sConn) = @_;
  require 'Xpriori::XMS/NeoCoreSvc.cfg' if(!defined($CstNeoCoreURL));
  return new Xpriori::XMS::Http(
             $CstNeoCoreURL, 
             $CstNeoCoreUsr, 
             $CstNeoCorePwd, $sConn);
}
sub login($)
{
  my ($oSelf) = @_;
  my $oXpH = _connect();
  my $sRes = $oXpH->getSID();
  return $sRes;
}
sub logout($$)
{
  my ($oSelf, $sConn) = @_;
  my $oXpH = _connect($sConn);
  return $oXpH->logout();
}
sub AUTOLOAD($$@)
{
  my($oSelf, $sConn, @aPrm) = @_;
  my $sPref = ref($oSelf);
  $sPref ||= $oSelf;
  $sPref .= '::';

  my $sMethod = $AUTOLOAD;
  $sMethod = substr($sMethod, length($sPref));
  if (grep {$_ eq $sMethod}
      qw(
       setTraceLevels getTraceLevels setIsolationLevel
       startTransaction commitTransaction rollbackTransaction
       queryXML deleteXML insertXML modifyXML copyXML
       queryFlatXML queryXMLUpdateIntent queryCountXML queryTreeXML
       queryDataContextXML getServerStatistics clearServerStatistics
       getServerVersion storeXML
      ))
  {
    my $oXpH = _connect($sConn);
    my $sRes = $oXpH->$sMethod(@aPrm);
    $oXpH->logout() unless($sConn);
    return $sRes;
  }
  else
  {
    return "ERROR: No Method : >$sMethod< >>$sPref<<";
  }
}
1;
__END__

=head1 NAME

Xpriori::XMS::Svc - Perl implementaion of Web Service for communicating with Xpriori::XMS Database.

=head1 SYNOPSIS

  #>> Sample for SOAP
    #!c:/perl/bin/perl
    use strict;
    use Xpriori::XMS::Svc;
    use SOAP::Transport::HTTP;
      SOAP::Transport::HTTP::CGI   
      -> dispatch_to('Xpriori::XMS::Svc')     
      -> handle;

  #>> Sample for JavaScript
    #!c:/perl/bin/perl
    use strict;
    use CGI;
    use JSON;
    use Xpriori::XMS::Svc;
    my $oCgi = new CGI();
    my $sMethod = $oCgi->param('_method');
    my $sConn   = $oCgi->param('_connect');
    my $raPrm   = from_json($oCgi->param('_param'));
    my $sRes = Xpriori::XMS::Svc->$sMethod($sConn, @$raPrm);
    print <<EOD;
    Content-Type: text/plain
    
    $sRes
    EOD
  # See sample/JavaScript/* more details


=head1 DESCRIPTION

Xpriori::XMS::Svc is a base class for Web Service for Xpriori::XMS Database.

URL, User and  Password should be set in 'NeoCoreSvc.cfg' included in the same directory.

=head2 login($$$%)

I<$sConn> = Xpriori::XMS::Svc->login();

connect to Xpriori::XMS and return SID for furture use.
You can use SID for other methods.
Althogh you can call other methods without SID, it will create other sessions.
So if you want to use 'transaction', you should get I<$sConn> first and use it with 
every methods you want.


=head2 logout

I<$sXml> = Xpriori::XMS::Svc->logout(I<$sConn>);

ends up session.

=head2 Other Sessions

I<$sXml> = Xpriori::XMS::Svc->{method}(I<$sConn> [, $sPrm1, $sPrm2...]);
You can use many methods of Xpriori::XMS::HTTP showed below:

  setTraceLevels, getTraceLevels, setIsolationLevel,
  startTransaction, commitTransaction, rollbackTransaction,
  queryXML deleteXML, insertXML, modifyXML, copyXML,
  queryFlatXML, queryXMLUpdateIntent, queryCountXML, queryTreeXML,
  queryDataContextXML, getServerStatistics, clearServerStatistics,
  getServerVersion, storeXML

When you call these methods almost same way, except you should set I<$sConn>.

 ex.
  
=head1 SEE ALSO

Xpriori::XMS::HTTP

=head1 AUTHOR

KAWAI,Takanori kwitknr@cpan.org

=head1 COPYRIGHT

The Xpriori::XMS::Http module is Copyright (c) 2009 KAWAI,Takanori, Japan.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
