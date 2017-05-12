package Xpriori::XMS::Soap;
use Xpriori::XMS::Svc;
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
       login logout
       setTraceLevels getTraceLevels setIsolationLevel
       startTransaction commitTransaction rollbackTransaction
       queryXML deleteXML insertXML modifyXML copyXML
       queryFlatXML queryXMLUpdateIntent queryCountXML queryTreeXML
       queryDataContextXML getServerStatistics clearServerStatistics
       getServerVersion storeXML
      ))
  {
    my $sRes = Xpriori::XMS::Svc->$sMethod($sConn, @aPrm);
    return SOAP::Data->name($sMethod . 'Result' => $sRes);
  }
  else
  {
    return "ERROR: No Method : >$sMethod< >>$sPref<<";
  }
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Xpriori::XMS::Soap - SOAP wrapper for Xpriori::XMS::Svc.

=head1 SYNOPSIS

  #>> Sample for SOAP (Server)
    #!c:/perl/bin/perl
    use strict;
    use Xpriori::XMS::Soap;
    use SOAP::Transport::HTTP;
      SOAP::Transport::HTTP::CGI   
      -> dispatch_to('Xpriori::XMS::Soap')     
      -> handle;

  #>> Sample for SOAP (Client)
      use strict;
      use SOAP::Lite qw(trace);
      my $oSoap = SOAP::Lite
          -> uri('Xpriori::XMS/Soap')
          -> proxy('http://localhost/cgi-bin/neo/NeoCoreSvcPerl.pl');
      
      my $sConn =  $oSoap->login()->result;
      print "CONN:$sConn\n";
      print $oSoap->queryXML('', '/ND//books')->result;
      print $oSoap->logout($sConn)->result;

=head1 DESCRIPTION

Xpriori::XMS::Soap is a wrapper of Xpriori::XMS::Svc for SOAP.

URL, User and  Password should be set in 'NeoCoreSvc.cfg' included in the same directory.
See Xpriori::XMS::Svc for methods and more detail.

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
