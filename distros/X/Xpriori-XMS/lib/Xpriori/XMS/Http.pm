package Xpriori::XMS::Http;
use utf8;
use strict;
use warnings;
#require Exporter;
#our @ISA = qw(Exporter);

use LWP;
use HTTP::Request;
use URI::Escape;
use Digest::MD5 qw(md5_hex);    # Needed to encrypt login
use Xpriori::XMS::Config;

our $VERSION = '0.03';

use constant CstCRLF => "\x0d\x0a";
use constant CstGETLIMIT => 256; #1024;
use constant CstNeoAdmin => 'neoadmin';
use constant CstNeoQuery => 'neoquery';
#---------------------------------------------------------------------
# new: constructor
#---------------------------------------------------------------------
sub new($$$;%)
{
    my $sClass = shift(@_);
    my $sUrl = shift(@_);
    my ($sUsr, $sPasswd, $iConn);
    if(ref($_[0]) eq 'HASH')
    {
      my $rhConn = shift(@_);
      $iConn = $rhConn->{sid};
    }
    else
    {
      $sUsr    = shift(@_);
      $sPasswd = shift(@_);
    }
    my %hPrmW = @_;

    my %hConf = %Xpriori::XMS::Config::_cnf;
    while(my($sKey, $sVal) = each(%hPrmW))
    {
        $hConf{$sKey} = $sVal;
    }
    my $oSelf = \%hConf;
    bless $oSelf, $sClass;
    $sUrl ||= $Xpriori::XMS::Config::_connect{METHOD} . '://' . 
              $Xpriori::XMS::Config::_connect{SERVER} . ':' . 
              $Xpriori::XMS::Config::_connect{PORT};

    $oSelf->{fullUrl} = $sUrl;
    $oSelf->{_lwpUa} = LWP::UserAgent->new();

    if($iConn)
    {
      $oSelf->{_sid} = $iConn;
    }
    else
    {
      my $sRes = $oSelf->_sendQueryPost(CstNeoAdmin, 
                               ('cmd'    => 'GETSESSION', 
                                'user'   => $sUsr, 
                                'passwd' => md5_hex($sPasswd))
                              );
      #get SID from 2nd-line
      my (undef, $xmlContent) = split("\n", $sRes, 2);
      if ($xmlContent =~ m|^\s*<.+>(.+)</.+>\s*$| )
      {
          $oSelf->{_sid} = $1;
      }
      else
      {
          die($sRes);
      }
    }
    return $oSelf;
}
#---------------------------------------------------------------------
# getSID method
#---------------------------------------------------------------------
sub getSID
{
    my($oSelf) = @_;
    return $oSelf->{_sid};
}
#---------------------------------------------------------------------
# setMethod method
#---------------------------------------------------------------------
sub setMethod
{
    my($oSelf, $sMethod) = @_;
    $oSelf->{METHOD} = $sMethod;
}
#---------------------------------------------------------------------
# setServer method
#---------------------------------------------------------------------
sub setServer
{
    my($oSelf, $sSvr) = @_;
    $oSelf->{SERVER} = $sSvr;
}
#---------------------------------------------------------------------
# setPort method
#---------------------------------------------------------------------
sub setPort
{
    my($oSelf, $iPort) = @_;
    $oSelf->{PORT} = $iPort;
}
#---------------------------------------------------------------------
# setCharset method
#---------------------------------------------------------------------
sub setCharset
{
    my($oSelf, $sChar) = @_;
    $oSelf->{CHARSET} = $sChar;
}
#---------------------------------------------------------------------
# setLanguage method
#---------------------------------------------------------------------
sub setLanguage
{
    my($oSelf, $sLng) = @_;
    $oSelf->{LANGUAGE} = $sLng;
}
#---------------------------------------------------------------------
# getMethod method
#---------------------------------------------------------------------
sub getMethod
{
    my($oSelf) = @_;
    return $oSelf->{METHOD};
}
#---------------------------------------------------------------------
# getServer method
#---------------------------------------------------------------------
sub getServer
{
    my($oSelf) = @_;
    return $oSelf->{SERVER};
}
#---------------------------------------------------------------------
# getPort method
#---------------------------------------------------------------------
sub getPort
{
    my($oSelf) = @_;
    return $oSelf->{PORT};
}
#---------------------------------------------------------------------
# getCharset method
#---------------------------------------------------------------------
sub getCharset
{
    my($oSelf) = @_;
    return $oSelf->{CHARSET};
}
#---------------------------------------------------------------------
# getLanguage method
#---------------------------------------------------------------------
sub getLanguage
{
    my($oSelf) = @_;
    return $oSelf->{LANGUAGE};
}
#---------------------------------------------------------------------
# _buildParam : for request
#---------------------------------------------------------------------
sub _buildParam($%)
{
    my($oSelf, %hParam) = @_;
    my $sPrm = '';
    if(%hParam)
    {
        while(my($sKey, $sVal) = each(%hParam))
        {
            $sPrm .= '&' if($sPrm ne '');
            #$sVal = ($sVal)? URI::Escape::uri_escape($sVal) : '';
            $sVal = ($sVal)? URI::Escape::uri_escape_utf8($sVal) : '';
            $sPrm .= "$sKey=$sVal";
        }
    }
    return $sPrm;
}
#---------------------------------------------------------------------
# _setHeader : for Request
#---------------------------------------------------------------------
sub _setHeader($$)
{
    my($oSelf, $oReq) = @_;
    $oReq->header('Accept-Charset',  $oSelf->{CHARSET});
    $oReq->header('Accept-Language', $oSelf->{LANGUAGE});
    $oReq->header('sid' => $oSelf->{_sid}) if(defined($oSelf->{_sid}));
}
#---------------------------------------------------------------------
# READ File and replace \n -> CRLF
#---------------------------------------------------------------------
sub _readFileCRLF
{
    my ($sFile) = @_;
    #If exists get contents
    {
        local(*XMLFILE, $/);
        open(XMLFILE, '<', $sFile) or 
                     die( "Can't open $sFile: $!");
        my $sXml = <XMLFILE>;
        close XMLFILE;
        my $sCRLF = CstCRLF;
        $sXml =~ s/\n+/$sCRLF/sg;
        return $sXml;
    }
}
#---------------------------------------------------------------------
# sendQueryGet : send query with GET
#---------------------------------------------------------------------
sub _sendQueryGet($$;@)
{
    my($oSelf, $sPath, %hParam) = @_;
    my $sxPath = $oSelf->{fullUrl} .  "/$sPath";
    my $sPrm = $oSelf->_buildParam(%hParam);
    $sxPath .= '?' . $sPrm if($sPrm);

    my $oReq = new HTTP::Request('GET', $sxPath);
    $oReq->header('Content-Type',    q{text/xml; charset='} . $oSelf->{CHARSET} . q{'});
    $oSelf->_setHeader($oReq);
    my $response = $oSelf->{_lwpUa}->request($oReq);
    if ($response->is_success)
    {
        return scalar($response->content());
    }
    else
    {
        return $response->as_string;
    }
}
#---------------------------------------------------------------------
# sendQueryPost : send query with POST
#---------------------------------------------------------------------
sub _sendQueryPost($$;@)
{
    my($oSelf, $sPath, %hParam) = @_;
    my $sURL = $oSelf->{fullUrl} .  "/$sPath";
    my $sPrm = $oSelf->_buildParam(%hParam);

    my $oReq = new HTTP::Request('POST', $sURL);
    $oReq->header('Content-Type',    q{text/xml; charset='} . $oSelf->{CHARSET} . q{'});
    $oSelf->_setHeader($oReq);
    $oReq->add_content($sPrm . CstCRLF);

    my $response = $oSelf->{_lwpUa}->request($oReq);
    if ($response->is_success)
    {
        return $response->content;
    }
    else
    {
        return $response->as_string;
    }
}
#---------------------------------------------------------------------
# make request that has Multipart
#---------------------------------------------------------------------
sub _mkReqMultipart($$@)
{
    my ($oSelf, $request, @aPrm) = @_;

    #   Create POST method boundary
    my $boundaryHeader = ('-' x 27) . sprintf("%lx", time());
    my $boundary = '--' . $boundaryHeader;
    $request->header('Content-Type', 'multipart/form-data; '.
                        'charset=' . $oSelf->{CHARSET} . '; ' .
                        'boundary=' . $boundaryHeader);
    if(@aPrm)
    {
        my $bInit = 1;
        foreach my $rhPrm  (@aPrm)
        {
            if($bInit == 1)
            {
                $bInit = 0;
                $request->content($boundary . CstCRLF);
            }
            else
            {
                $request->add_content(CstCRLF . $boundary . CstCRLF);
            }
            $request->add_content(
                   'Content-Disposition: form-data; ' .
                   'name="' . $rhPrm->{name} . '"; '. 
                   'filename="' . $rhPrm->{filename} . '"' . CstCRLF);
            if($rhPrm->{type})
            {
                $request->add_content(
                        'Content-Type: ' . $rhPrm->{type} . CstCRLF . CstCRLF);
            }
            my $sCnt = $rhPrm->{content};
            utf8::encode($sCnt);
            $request->add_content($sCnt);
        }
        $request->add_content(CstCRLF  . $boundary . '--');
    }
    return $request;
}
#---------------------------------------------------------------------
# _sendQueryPostMultipart : 
#---------------------------------------------------------------------
sub _sendQueryPostMultipart
{
    my($oSelf, $sPath, $cmd, @aPrm) = @_;
    my $uri= $oSelf->{fullUrl} . '/' . $sPath . '?' . 'cmd=' . $cmd;
    my $request = new HTTP::Request('POST', $uri);
    $oSelf->_setHeader($request);
    $oSelf->_mkReqMultipart($request, @aPrm);

    my $response = $oSelf->{_lwpUa}->request($request);
    if ($response->is_success)
    {
        return $response->content;
    }
    else
    {
        return $response->as_string;        
    }
}
#---------------------------------------------------------------------
# _queryGeneralCmd:
#---------------------------------------------------------------------
sub _queryGeneralCmd($$;$@)
{
    my ($oSelf, $sCmd, $sInput, %hOpt) = @_;
    my %hPrm = ();
    %hPrm = %hOpt if(%hOpt);
    $hPrm{'cmd'}   = $sCmd;
    $hPrm{'input'} = $sInput if(defined($sInput));
    return $oSelf->_sendQueryGet(CstNeoQuery, %hPrm);
}
#---------------------------------------------------------------------
# logout
#---------------------------------------------------------------------
sub logout
{
    my($oSelf) = @_;
    return $oSelf->_sendQueryGet(CstNeoAdmin, 'cmd' => 'ENDSESSION');
}
#---------------------------------------------------------------------
# setTraceLevels method
#---------------------------------------------------------------------
sub setTraceLevels
{
    my($oSelf, $sLvl) = @_;
    return $oSelf->_sendQueryGet(CstNeoAdmin, 
                         'cmd' => 'TRCLVL', 
                         'RHTRCLVL' => $sLvl,
                        );
}
#---------------------------------------------------------------------
# getTraceLevels method
#---------------------------------------------------------------------
sub getTraceLevels
{
    my($oSelf) = @_;
    return $oSelf->_sendQueryGet(CstNeoAdmin, 
                         'cmd' => 'GETTRCLVL', 
                        );
}
#---------------------------------------------------------------------
# activateAccessControl method
#---------------------------------------------------------------------
sub activateAccessControl
{
    my($oSelf) = @_;
    return $oSelf->_sendQueryGet(CstNeoAdmin, 
                         'cmd' => 'ACTIVATEAC', 
                        );
}
#---------------------------------------------------------------------
#   setPassword method
#---------------------------------------------------------------------
sub setPassword
{
    my ($oSelf, $sUser, $sPasswd) = @_;
    return $oSelf->_sendQueryPost(CstNeoAdmin, 
                         'cmd'    => 'SETPASSWD', 
                         'user'   => $sUser,
                         'passwd' => md5_hex($sPasswd)
                        );
}
#---------------------------------------------------------------------
# setIsolationLevel method
#
# IsolationLevel can be READ_COMMITTED, READ_UNCOMMITTED,
# REPEATABLE_READ (SERIALIZABLE is no longer supported) 
#---------------------------------------------------------------------
sub setIsolationLevel
{
    my($oSelf, $iIsoLvl) = @_;
    return $oSelf->_queryGeneralCmd('TRANSACTION_ISOLATION', $iIsoLvl);
}
#---------------------------------------------------------------------
# startTransaction method
# no parameter version of this method
#---------------------------------------------------------------------
sub startTransaction
{
    my ($oSelf, @aPrm) = @_;
    if ( @aPrm == 3)
    {
        #my ($tx_flush, $maxdur, $inactdur) = @aPrm;
        return $oSelf->_queryGeneralCmd('TRANSACTION_START', $aPrm[0], 
                                  MAXDURATION => $aPrm[1], 
                                  INACTIVITYDURATION => $aPrm[2]);
    }
    elsif ( @aPrm == 1)
    {
        return $oSelf->_queryGeneralCmd('TRANSACTION_START', $aPrm[0]);
    }
    else
    {
        return $oSelf->_queryGeneralCmd('TRANSACTION_START');
    }
}
#---------------------------------------------------------------------
# commitTransaction method
#---------------------------------------------------------------------
sub commitTransaction
{
    my ($oSelf) = @_;
    return $oSelf->_queryGeneralCmd('TRANSACTION_COMMIT');
}
#---------------------------------------------------------------------
# rollbackTransaction method
#---------------------------------------------------------------------
sub rollbackTransaction
{
    my ($oSelf) = @_;
    return $oSelf->_queryGeneralCmd('TRANSACTION_ROLLBACK');
}
#---------------------------------------------------------------------
# queryXML method : 
#---------------------------------------------------------------------
sub queryXML
{
    my ($oSelf, $query, $rhOpt) = @_;
    if ( $rhOpt->{POST} || (length($query) > CstGETLIMIT ))
    {
        return $oSelf->_sendQueryPostMultipart(CstNeoQuery, 'QUERY', 
                {
                    name => 'input', 
                    filename => '',
                    content => $query,
                }
                );
    }
    else
    {
        return $oSelf->_queryGeneralCmd('QUERY', $query);
    }
}
#---------------------------------------------------------------------
# deleteXML
#---------------------------------------------------------------------
sub deleteXML
{
    my($oSelf, $query) = @_;
    return $oSelf->_queryGeneralCmd('DELETE', $query);
}
#---------------------------------------------------------------------
# insertXML method
#---------------------------------------------------------------------
sub insertXML_File
{
    my ($oSelf, $query, $fXml, $rhOpt) = @_;
    return $oSelf->insertXML($query, 
                            _readFileCRLF($fXml), $rhOpt);
}
#---------------------------------------------------------------------
# insertXML method
#---------------------------------------------------------------------
sub insertXML
{
    my ($oSelf, $query, $insertString, $rhOpt) = @_;
    if ($rhOpt->{POST} || (length($query) + length($insertString) > CstGETLIMIT ))
    {
        return $oSelf->_sendQueryPostMultipart(CstNeoQuery, 
                'INSERT', (
                {
                    name => 'input', 
                    filename => '',
                    content => $query,
                },
                {
                    name => 'data', 
                    filename => '',
                    content => $insertString,
                },
                ));
    }
    else
    {
        return $oSelf->_queryGeneralCmd('INSERT', $query, 
                                 'data' => $insertString);
    }
}
#---------------------------------------------------------------------
# modifyXML method
#---------------------------------------------------------------------
sub modifyXML_File
{
    my ($oSelf, $query, $modXML, $rhOpt) = @_;
    return $oSelf->modifyXML($query, 
                            _readFileCRLF($modXML), $rhOpt);
}
#---------------------------------------------------------------------
# modifyXML method
#---------------------------------------------------------------------
sub modifyXML
{
    my ($oSelf, $query, $modString, $rhOpt) = @_;
    if ($rhOpt->{POST} || (length($query) + length($modString) > CstGETLIMIT ))
    {
        return $oSelf->_sendQueryPostMultipart(CstNeoQuery, 
                           'MODIFY', (
                {
                    name => 'input', 
                    filename => '',
                    content => $query,
                },
                {
                    name => 'data', 
                    filename => '',
                    content => $modString,
                },
                ));
    }
    else
    {
        return $oSelf->_queryGeneralCmd('MODIFY', $query, 
                                 'data' => $modString);
    }
}
#---------------------------------------------------------------------
# copyXML method : ? 
#---------------------------------------------------------------------
sub copyXML
{
    my ($oSelf, $query) = @_;
    return $oSelf->_queryGeneralCmd('COPY', $query);
}
#---------------------------------------------------------------------
# queryFlatXML : ?
#---------------------------------------------------------------------
sub queryFlatXML
{
    my ($oSelf, $query) = @_;
    return $oSelf->_queryGeneralCmd('FLAT', $query);
}
#---------------------------------------------------------------------
# queryXMLUpdateIntent : ?
#---------------------------------------------------------------------
sub queryXMLUpdateIntent
{
    my ($oSelf, $query) = @_;
    return $oSelf->_queryGeneralCmd('QUERYUPDATE', $query);
}
#---------------------------------------------------------------------
# queryCountXML : ?
#---------------------------------------------------------------------
sub queryCountXML
{
    my ($oSelf, $query, $bNotAcid) = @_;
    if($bNotAcid)
    {
        return $oSelf->_queryGeneralCmd('COUNTNOTACID', $query);
    }
    else
    {
        return $oSelf->_queryGeneralCmd('COUNT', $query);
    }
}
#---------------------------------------------------------------------
# queryTreeXML : get node name 
#---------------------------------------------------------------------
sub queryTreeXML
{
    my($oSelf, $query) = @_;
    return $oSelf->_queryGeneralCmd('TREE', $query);
}
#---------------------------------------------------------------------
# queryDataContextXML method
# The search string must be quoted
#---------------------------------------------------------------------
sub queryDataContextXML
{
    my($oSelf, $query) = @_;
    return $oSelf->_queryGeneralCmd('DATAQUERY', qq{"$query"});
}
#---------------------------------------------------------------------
# getServerStatistics method
# query_string parameter :
#  ''(=ALL), ADMIN, STORAGE, ACCESS, BUFFER, TRANSACTION, WINDOW
#---------------------------------------------------------------------
sub getServerStatistics
{
    my($oSelf, $sCmd) = @_;
    my $sCmdS = 'GETSTATS';
    $sCmdS .= '_' . $sCmd if($sCmd);
    return $oSelf->_queryGeneralCmd($sCmdS);
}
#---------------------------------------------------------------------
# clearServerStatistics method
#---------------------------------------------------------------------
sub clearServerStatistics
{
    my($oSelf) = @_;
    return $oSelf->_queryGeneralCmd('CLEARSTATS');
}
#---------------------------------------------------------------------
# getServerVersion method
#---------------------------------------------------------------------
sub getServerVersion
{
    my($oSelf) = @_;
    return $oSelf->_queryGeneralCmd('VERSION');
}
#---------------------------------------------------------------------
# storeXML_File
#---------------------------------------------------------------------
sub storeXML_File
{
    my ($oSelf, $xml, $schemaURI, $prefix) = @_;
    my $xmlString = _readFileCRLF($xml);
    return $oSelf->storeXML($xmlString, $schemaURI, $prefix);
}
#---------------------------------------------------------------------
#   storeXML method
#   stores an XML string
#   if only used with one parameter, assumes schemaURI and prefix are null
#---------------------------------------------------------------------
sub storeXML
{
    my ($oSelf, $xmlString, $schemaURI, $prefix) = @_;
    my @aPrm = ();
    push(@aPrm, {
               name     => 'schemafile', 
               filename => '', 
               content  => $schemaURI,
          }) if($schemaURI);
    push(@aPrm, {
               name     => 'prefixfile', 
               filename => $prefix, 
               type     => 'text/xml',
               content  => $prefix,
          }) if($prefix);
    push(@aPrm, 
          {
               name     => 'xmlsourcefile', 
               filename => '', 
               type     => 'text/xml',
               content  => $xmlString,
          },
        );
    return $oSelf->_sendQueryPostMultipart(CstNeoQuery, 'STORE', @aPrm);
}
sub DESTROY
{
  my($oSelf) = @_;
  local $@; #Keep previous die-message.
  $oSelf->logout() 
        if($oSelf->{AUTO_LOGOUT} && $oSelf->{_sid});
}
1;

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Xpriori::XMS - Perl extension for Xpriori::XMS Database.

Xpriori::XMS::Http - Perl extension for communicating with Xpriori::XMS Database.

=head1 SYNOPSIS

1. Normal
  use strict;
  use Xpriori::XMS::Http;
  my $oXpH = new Xpriori::XMS('http://localhost:7700/', 'Administrator', 'admin');
  $oXpH->storeXML('<sample><base/></sample>');
  $oXpH->insertXML('/ND/sample/base', '<XYZ>xyz</XYZ>');
  my $sRes = $oXpH->queryXML('/ND/sample/XYZ');

2. Use Previous Connect
  use strict;
  use Xpriori::XMS::Http;
  my $oXpH = new Xpriori::XMS('http://localhost:7700/', 'Administrator', 'admin');
  my $iSid = $oXpH->getSid();
  (snip)
  #Use Previous Connect(Even other scripts!)
  my $oNew = new Xpriori::XMS('http://localhost:7700/', { sid => $iSid});

3. With auto logout
  use strict;
  use Xpriori::XMS::Http;
  my $oXpH = new Xpriori::XMS('http://localhost:7700/', 'Administrator', 'admin', 
                             AUTO_LOGOUT => 1);
  (or)
  my $oNew = new Xpriori::XMS('http://localhost:7700/', { sid => $iSid}
                            AUTO_LOGOUT => 1);


=head1 DESCRIPTION

Xpriori::XMS is a module enables you to talk to Xpriori::XMS Database with http using LWP.

=head2 new($$$%)

I<$oXpH> = Xpriori::XMS::Http->new(I<$URL>, I<$User>, I<$Passwd> [, I<$sID>, I<%Option>]);

Constructor. 
Creates a Xpriori::XMS::Http object and start session.
If I<$URL> is undef or empty string, 
Xpriori::XMS::Config::_connect will be used.

IF I<$sID> is not set, this will login with I<$User>, I<$Passwd>.
IF I<$sID> is set, this will this SID for request without login.

=head2 getSID

I<$oXpH> = $oXpH->getSID();

return SID.

=head2 logout

I<$sXml> = $oXpH->logout();

ends up session.

=head2 setTraceLevels

I<$sXml> = $oXpH->setTraceLevels(I<$sTraceLevel>);

sets trace levels. (ex. 'INFO:LOG_Performance')

=head2 getTraceLevels

I<$sXml> = $oXpH->getTraceLevels();

gets current trace levels. 
(ex. '<TraceLevel>FATAL:LOG_all;WARNING:LOG_all;ERR:LOG_all</TraceLevel>')

=head2 activateAccessControl

I<$sXml> = $oXpH->activateAccessControl();

ativates access controls.

=head2 setPassword

I<$sXml> = $oXpH->setPassword(I<$User>, I<$Passwd>);

changes I<$User>'s password to I<$Passwd>.

=head2 setIsolationLevel

I<$sXml> = $oXpH->setIsolationLevel(I<$sLvl>);

sets isolation level. 
You can set I<$sLvl> to READ_COMMITTED, READ_UNCOMMITTED and REPEATABLE_READ

=head2 startTransaction

I<$sXml> = $oXpH->startTransaction();
I<$sXml> = $oXpH->startTransaction(I<$Flush>);
I<$sXml> = $oXpH->startTransaction(I<$Flush>, I<$MaxDuration>, I<InactivityDuraion>);

starts trasaction.
You can set I<$Flush> FLUSH (immediately flush after commit) or 
NOFLUSH (flushed by background process).

I<$MaxDuration> is maximum duraion of transaction.
I<$InactivetyDuration> is maximum duraion of transaction is inactive.

=head2 commitTransaction


I<$sXml> = $oXpH->commitTransaction();

commits transaction.

=head2 rollbackTransaction

I<$sXml> = $oXpH->rollbackTransaction();

rollbacks transaction.

=head2 queryXML

I<$sXml> = $oXpH->query(I<$Xquery>);

gets the result of I<$Xquery>.

=head2 queryFlatXML

I<$sXml> = $oXpH->queryFlatXML(I<$Xquery>);

gets the result of I<$Xquery> with flatten XML.

=head2 queryCountXML

I<$sXml> = $oXpH->queryCountXML(I<$Xquery>);

counts nodes from the result of I<$Xquery>.


=head2 queryTreeXML

I<$sXml> = $oXpH->queryTreeXML(I<$Xquery>);

gets the names of children tags from the result of I<$Xquery>.

=head2 queryXMLUpdateIntent

I<$sXml> = $oXpH->queryXMLUpdateIntent(I<$Xquery>);

queries and gets result of I<$Xquery> considering transaction and locks.

=head2 queryDataContextXML

I<$sXml> = $oXpH->queryDataContextXML(I<$Xquery>);

I<Sorry I can't find out the use of this method>.

=head2 deleteXML

I<$sXml> = $oXpH->deleteXML(I<$Xquery>);

deletes nodes where matches I<$Xquery>.

=head2 insertXML_File

I<$sXml> = $oXpH->insertXML_File(I<$Xquery>, I<$XmlFile>);

inserts contents of I<$XmlFile> at the point of I<$Xquery>.

=head2 insertXML

I<$sXml> = $oXpH->insertXML(I<$Xquery>, I<$Xml>);

inserts I<$Xml> at the point of I<$Xquery>.

=head2 modifyXML_File

I<$sXml> = $oXpH->modifyXML_File(I<$Xquery>, I<$XmlFile>);

modifies I<$Xquery> with the contents of I<$XmlFile>.

=head2 modifyXML

I<$sXml> = $oXpH->insertXML(I<$Xquery>, I<$Xml>);

modifies I<$Xquery> with I<$Xml>.

=head2 copyXML

I<$sXml> = $oXpH->copyXML(I<$Xquery>);

copies a document specified with I<$Xquery>.

=head2 storeXML_File

I<$sXml> = $oXpH->storeXML_File(I<$XmlFile> [, I<$schemaURI>, I<$prefix>]);

stores contents of I<$XmlFile>.

=head2 storeXML

I<$sXml> = $oXpH->storeXML(I<$Xml> [, I<$schemaURI>, I<$prefix>]);

stores I<$Xml>.

=head2 getServerStatistics

I<$sXml> = $oXpH->getServerStatistics(I<$Param>);

I<$Param> can be set :
  ''(=ALL, default), ADMIN, STORAGE, ACCESS, BUFFER, TRANSACTION, WINDOW.

=head2 clearServerStatistics

I<$sXml> = $oXpH->clearServerStatistics();

clears statistics.

=head2 getServerVersion

I<$sXml> = $oXpH->getServerVersion();

gets server version info.

=head2 setCharset

I<$sXml> = $oXpH->setCharset(I<$Charset>);

sets characterset.

=head2 setLanguage

I<$sXml> = $oXpH->setLanguage(I<$Language>);

sets language.

=head2 getCharset

I<$sXml> = $oXpH->getCharset();

gets current characterset.

=head2 getLanguage

I<$sXml> = $oXpH->getLanguage();

gets current language.

=head1 SEE ALSO

Xpriori::XMS::ServerUtil, Xpriori::XMS::Config

=head1 AUTHOR

KAWAI,Takanori kwitknr@cpan.org

=head1 COPYRIGHT

The Xpriori::XMS::Http module is Copyright (c) 2009 KAWAI,Takanori, Japan.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
