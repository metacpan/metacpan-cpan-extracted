package WebService::Hexonet::Connector::Test;
use 5.026_000;
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::RequiresInternet ( 'coreapi.1api.net' => 80 );

use version 0.9917; our $VERSION = version->declare('v2.1.0');

# T1-4: test import modules
use_ok('Config');
use_ok( 'POSIX',                          qw(uname) );
use_ok( 'Scalar::Util',                   qw(blessed) );
use_ok( 'WebService::Hexonet::Connector', $VERSION );
use_ok('Readonly');
use Readonly;
use Config;
use POSIX;
Readonly my $CMD_LIMIT          => 1000;
Readonly my $INDEX_NOT_FOUND    => -1;
Readonly my $TMP_ERR_423        => 423;
Readonly my $ERR_500            => 500;
Readonly my $RES_RUNTIME        => 0.12;
Readonly my $COLUMNS_LEN        => 6;
Readonly my $LAST_REC_IDX       => 3;
Readonly my @DEFAULT_TPL_KEYS   => qw(404 500 error httperror empty unauthorized expired);
Readonly my @EXPECTED_COL_KEYS  => qw(COUNT  DOMAIN FIRST LAST LIMIT TOTAL);
Readonly my @EXPECTED_COL_KEYS2 => qw(COUNT CURRENTPAGE FIRST LAST LIMIT NEXTPAGE PAGES PREVIOUSPAGE TOTAL);

# ---- Module "Column" ---- #
# - T7
my $col = WebService::Hexonet::Connector::Column->new( 'DOMAIN', ( 'mydomain1.com', 'mydomain2.com', 'mydomain3.com' ) );
my $cls = blessed($col);
is( $cls, 'WebService::Hexonet::Connector::Column', 'COLUMN: Instance type check' );
is( $col->getKey(), 'DOMAIN', 'COLUMN: Column Name check' );

# ---- Module "Record" ---- #
# - T9
my $data = {
    DOMAIN => 'mydomain.com',
    RATING => 1,
    RNDINT => 321,
    SUM    => 1
};
my $rec = WebService::Hexonet::Connector::Record->new($data);
$cls = blessed($rec);
is( $cls,                                 'WebService::Hexonet::Connector::Record', 'RECORD: Instance type check' );
is( $rec->getData(),                      $data,                                    'RECORD: Record Data check' );
is( $rec->getDataByKey('KEYNOTEXISTING'), undef,                                    'RECORD: Record Key Data check' );

# ---- Module "ResponseParser" ---- #
# T10
my $rtm = WebService::Hexonet::Connector::ResponseTemplateManager->getInstance();
$cls = blessed($rtm);
is( $cls, 'WebService::Hexonet::Connector::ResponseTemplateManager', 'RTM: Instance type check' );
$rtm->addTemplate( 'OK', $rtm->generateTemplate( '200', 'Command completed successfully' ) );
$rtm->addTemplate( 'listP0', "[RESPONSE]\r\nPROPERTY[TOTAL][0]=2701\r\nPROPERTY[FIRST][0]=0\r\nPROPERTY[DOMAIN][0]=0-60motorcycletimes.com\r\nPROPERTY[DOMAIN][1]=0-be-s01-0.com\r\nPROPERTY[COUNT][0]=2\r\nPROPERTY[LAST][0]=1\r\nPROPERTY[LIMIT][0]=2\r\nDESCRIPTION=Command completed successfully\r\nCODE=200\r\nQUEUETIME=0\r\nRUNTIME=0.023\r\nEOF\r\n" );

# T11 ~> parse method
my $plain = $rtm->generateTemplate( '421', q{} );
$plain =~ s/\r\nDESCRIPTION=//msx;
my $h = WebService::Hexonet::Connector::ResponseParser::parse($plain);
is( length $h->{DESCRIPTION}, 0, 'RP: Description Property length check' );

# T12 ~> serialize method #1
my $r = $rtm->getTemplate('OK');
$h = $r->getHash();
$h->{PROPERTY} = {
    DOMAIN => [ 'mydomain1.com', 'mydomain2.com', 'mydomain3.com' ],
    RATING => [ 0,               1,               2 ],
    SUM    => [ 2 ],
};
$plain = WebService::Hexonet::Connector::ResponseParser::serialize($h);
is( $plain, "[RESPONSE]\r\nPROPERTY[DOMAIN][0]=mydomain1.com\r\nPROPERTY[DOMAIN][1]=mydomain2.com\r\nPROPERTY[DOMAIN][2]=mydomain3.com\r\nPROPERTY[RATING][0]=0\r\nPROPERTY[RATING][1]=1\r\nPROPERTY[RATING][2]=2\r\nPROPERTY[SUM][0]=2\r\nCODE=200\r\nDESCRIPTION=Command completed successfully\r\nEOF\r\n", 'RP: Serialize result check #1' );

# T13 ~> serialize method #2
my $tpl = $rtm->getTemplate('OK');
$plain = WebService::Hexonet::Connector::ResponseParser::serialize( $tpl->getHash() );
is( $plain, $tpl->getPlain(), 'RP: Serialize result check #2' );

# T14 ~> serialize method #3
$r = $rtm->getTemplate('OK');
$h = $r->getHash();
delete $h->{CODE};
delete $h->{DESCRIPTION};
$plain = WebService::Hexonet::Connector::ResponseParser::serialize($h);
is( $plain, "[RESPONSE]\r\nEOF\r\n", 'RP: Serialize result check #3' );

# T15 ~> serialize method #4
$r              = $rtm->getTemplate('OK');
$h              = $r->getHash();
$h->{QUEUETIME} = '0';
$h->{RUNTIME}   = '0.12';
$plain          = WebService::Hexonet::Connector::ResponseParser::serialize($h);
is( $plain, "[RESPONSE]\r\nCODE=200\r\nDESCRIPTION=Command completed successfully\r\nQUEUETIME=0\r\nRUNTIME=0.12\r\nEOF\r\n", 'RP: Serialize result check #4' );

# ---- Module "SocketConfig" ---- #
# T16
my $sc = WebService::Hexonet::Connector::SocketConfig->new();
my $d  = $sc->getPOSTData();
is( %{$d}, 0, 'SocketConfig: Check initial POST data' );

# ---- Module "ResponseTemplate" ---- #
# - T17 ~> constructor test
$tpl = WebService::Hexonet::Connector::ResponseTemplate->new(q{});
is( $tpl->getCode(),        $TMP_ERR_423,         'ResponseTemplate: Check response code of template `empty` #1' );
is( $tpl->getDescription(), 'Empty API response', 'ResponseTemplate: Check response description of template `empty` #1' );

# - T19 ~> getHash method test
$tpl = WebService::Hexonet::Connector::ResponseTemplate->new();
$h   = $tpl->getHash();
is( $h->{CODE},        $TMP_ERR_423,         'ResponseTemplate: Check response code of template `empty` #2' );
is( $h->{DESCRIPTION}, 'Empty API response', 'ResponseTemplate: Check response description of template `empty` #2' );

# - T21 ~> getQueuetime method test
$tpl = WebService::Hexonet::Connector::ResponseTemplate->new();
is( $tpl->getQueuetime(), 0, 'ResponseTemplate: Check response queuetime of template `empty`' );
$tpl = WebService::Hexonet::Connector::ResponseTemplate->new("[RESPONSE]\r\ncode=423\r\ndescription=Empty API response\r\nqueuetime=0\r\nEOF\r\n");
is( $tpl->getQueuetime(), 0, 'ResponseTemplate: Check response queuetime' );

# - T23 ~> getRuntime method test
$tpl = WebService::Hexonet::Connector::ResponseTemplate->new();
is( $tpl->getRuntime(), 0, 'ResponseTemplate: Check response runtime of template `empty`' );
$tpl = WebService::Hexonet::Connector::ResponseTemplate->new("[RESPONSE]\r\ncode=423\r\ndescription=Empty API response\r\nruntime=0.12\r\nEOF\r\n");
is( $tpl->getRuntime(), $RES_RUNTIME, 'ResponseTemplate: Check response runtime' );

# ---- Module "ResponseTemplateManager" ---- #
# - T25 ~> getTemplate method test
$tpl = $rtm->getTemplate('IwontExist');
is( $tpl->getCode(), $ERR_500, 'RTM: Check response case for template not found [code]' );
is( $tpl->getDescription(), 'Response Template not found', 'RTM: Check response case for template not found [description]' );

# - T32 ~> getTemplates method test
my $tpls = $rtm->getTemplates();
my @keys = keys %{$tpls};
foreach my $key1 (@DEFAULT_TPL_KEYS) {
    my $found = 0;
    foreach my $key2 (@keys) {
        if ( $key1 eq $key2 ) {
            $found = 1;
        }
    }
    is( $found, 1, "RTM: Check existance of default template `${key1}`." );
}

# T33 ~> isTemplateMatchHash method test
$tpl = WebService::Hexonet::Connector::ResponseTemplate->new();
$h   = $tpl->getHash();
is( $rtm->isTemplateMatchHash( $h, 'empty' ), 1, 'RTM: Check hash template match.' );

# T34 ~> isTemplateMatchPlain method test
$tpl = WebService::Hexonet::Connector::ResponseTemplate->new();
is( $rtm->isTemplateMatchPlain( $tpl->getPlain(), 'empty' ), 1, 'RTM: Check plain template match.' );

# ---- Module "Response" ---- #
# - T36 ~> getCurrentPageNumber method test
$tpl = $rtm->getTemplate('listP0');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
is( $r->getCurrentPageNumber(), 1, 'R: Check current page number. #1' );
$tpl = $rtm->getTemplate('OK');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
is( $r->getCurrentPageNumber(), $INDEX_NOT_FOUND, 'R: Check current page number #2.' );

# - T38 ~> getFirstRecordIndex method test
$tpl = $rtm->getTemplate('OK');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
is( $r->getFirstRecordIndex(), undef, 'R: Check first record index #1.' );

$tpl = $rtm->getTemplate('OK');
$h   = $tpl->getHash();
$h->{PROPERTY} = { DOMAIN => [ 'mydomain1.com', 'mydomain2.com' ] };
$plain         = WebService::Hexonet::Connector::ResponseParser::serialize($h);
$r             = WebService::Hexonet::Connector::Response->new($plain);
is( $r->getFirstRecordIndex(), 0, 'R: Check first record index #2.' );

# T39 ~> getColumns method test
$tpl = $rtm->getTemplate('listP0');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
my $cols = $r->getColumns();
is( scalar @{$cols}, $COLUMNS_LEN, 'R: Check column list.' );

# - T41 ~> getColumnIndex method test
$tpl = $rtm->getTemplate('listP0');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
$d   = $r->getColumnIndex( 'DOMAIN', 0 );
is( $d, '0-60motorcycletimes.com', 'R: Check value of column index #1' );
$tpl = $rtm->getTemplate('listP0');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
$d   = $r->getColumnIndex( 'COLUMN_NOT_EXISTS', 0 );
is( $d, undef, 'R: Check value of column index #2' );

# T42 ~> getColumnKeys method test
$tpl = $rtm->getTemplate('listP0');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
my $colkeys = $r->getColumnKeys();
is( scalar @{$colkeys}, $COLUMNS_LEN, 'R: Check column name list' );
foreach my $key1 (@EXPECTED_COL_KEYS) {
    my $found = 0;
    foreach my $key2 ( @{$colkeys} ) {
        if ( $key1 eq $key2 ) {
            $found = 1;
        }
    }
    is( $found, 1, "RTM: Check existance of expected column name `${key1}`." );
}

# - T44 ~> getCurrentRecord method test
$tpl = $rtm->getTemplate('listP0');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
$rec = $r->getCurrentRecord();
$d   = {
    COUNT  => '2',
    DOMAIN => '0-60motorcycletimes.com',
    FIRST  => '0',
    LAST   => '1',
    LIMIT  => '2',
    TOTAL  => '2701'
};
is_deeply( $rec->getData(), $d, 'R: Check returned current record. #1' );
$tpl = $rtm->getTemplate('OK');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
is( $r->getCurrentRecord(), undef, 'R: Check returned current record. #2' );

# T45 ~> getListHash method test
$tpl = $rtm->getTemplate('listP0');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
$h   = $r->getListHash();
is( scalar @{ $h->{LIST} }, 2, 'R: Check returned record list in list hash' );
$colkeys = $r->getColumnKeys();
is( @{ $h->{meta}->{columns} }, @{$colkeys}, 'R: Check returned column name list in list hash' );
is_deeply( $h->{meta}->{pg}, $r->getPagination(), 'R: Check returned pagination data in list hash' );

# T46 ~> getNextRecord method test
$tpl = $rtm->getTemplate('listP0');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
$rec = $r->getNextRecord();
is_deeply( $rec->getData(), { DOMAIN => '0-be-s01-0.com' }, 'R: Check returned next record #1' );
$rec = $r->getNextRecord();
is( $rec, undef, 'R: Check returned next record #2.' );

# T47 ~> getPagination method test
$tpl = $rtm->getTemplate('listP0');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
my $pager = $r->getPagination();
foreach my $key1 (@EXPECTED_COL_KEYS2) {
    my $found = 0;
    foreach my $key2 ( keys %{$pager} ) {
        if ( $key1 eq $key2 ) {
            $found = 1;
        }
    }
    is( $found, 1, "R: Check existance of expected keys in pager hash `${key1}`." );
}

# T48 ~> getPreviousRecord method test
$tpl = $rtm->getTemplate('listP0');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
$r->getNextRecord();
$rec = $r->getPreviousRecord();
is_deeply( $rec->getData(), { COUNT => '2', DOMAIN => '0-60motorcycletimes.com', FIRST => '0', LAST => '1', LIMIT => '2', TOTAL => '2701' }, 'R: Check returned previous record. #1' );
is( $r->getPreviousRecord(), undef, 'R: Check returned previous record. #2' );

# - T50 ~> hasNexPage method test
$tpl = $rtm->getTemplate('OK');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
is( $r->hasNextPage(), 0, 'R: Check result of hasNextPage check. #1' );
$tpl = $rtm->getTemplate('listP0');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
is( $r->hasNextPage(), 1, 'R: Check result of hasNextPage check. #2' );

# - T52 ~> hasPreviousPage method test
$tpl = $rtm->getTemplate('OK');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
is( $r->hasPreviousPage(), 0, 'R: Check result of hasPreviousPage check. #1' );
$tpl = $rtm->getTemplate('listP0');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
is( $r->hasPreviousPage(), 0, 'R: Check result of hasPreviousPage check. #2' );

# - T54 ~> getLastRecordIndex method test
$tpl = $rtm->getTemplate('OK');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
is( $r->getLastRecordIndex(), undef, 'R: Check result for last record index. #1' );
$h = $tpl->getHash();
$h->{PROPERTY} = { DOMAIN => [ 'mydomain1.com', 'mydomain2.com' ] };
$plain         = WebService::Hexonet::Connector::ResponseParser::serialize($h);
$r             = WebService::Hexonet::Connector::Response->new($plain);
is( $r->getLastRecordIndex(), 1, 'R: Check result for last record index. #2' );

# - T56 ~> getNextPageNumber method test
$tpl = $rtm->getTemplate('OK');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
is( $r->getNextPageNumber(), $INDEX_NOT_FOUND, 'R: Check next page number. #1' );
$tpl = $rtm->getTemplate('listP0');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
is( $r->getNextPageNumber(), 2, 'R: Check next page number. #2' );

# T57 ~> getNumberOfPages method test
$tpl = $rtm->getTemplate('OK');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
is( $r->getNumberOfPages(), 0, 'R: Check number of pages.' );

# - T59 ~> getPreviousPageNumber method test
$tpl = $rtm->getTemplate('OK');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
is( $r->getPreviousPageNumber(), $INDEX_NOT_FOUND, 'R: Check returned previous page number. #1' );
$tpl = $rtm->getTemplate('listP0');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
is( $r->getPreviousPageNumber(), $INDEX_NOT_FOUND, 'R: Check returned previous page number. #2' );

# - T63 ~> rewindRecordList method test
$tpl = $rtm->getTemplate('listP0');
$r   = WebService::Hexonet::Connector::Response->new( $tpl->getPlain() );
is( $r->getPreviousRecord(), undef, 'R: Check rewindRecordList method usage. #1' );
isnt( $r->getNextRecord(), undef, 'R: Check rewindRecordList method usage. #2' );
is( $r->getNextRecord(),                         undef, 'R: Check rewindRecordList method usage. #3' );
is( $r->rewindRecordList()->getPreviousRecord(), undef, 'R: Check rewindRecordList method usage. #3' );

# ---- Module "APIClient" ---- #
# - T66 ~> getPOSTData method test
my $cl       = WebService::Hexonet::Connector::APIClient->new();
my $validate = {
    's_entity'  => '54cd',
    's_command' => "AUTH=gwrgwqg%&\\44t3*\nCOMMAND=ModifyDomain"
};
my $enc = $cl->getPOSTData( { COMMAND => 'ModifyDomain', AUTH => 'gwrgwqg%&\\44t3*' } );
is_deeply( $enc, $validate, 'AC: Check getPOSTData result. #1' );
$validate = {
    's_entity'  => '54cd',
    's_command' => q{}
};
$enc = $cl->getPOSTData('gregergege');
is_deeply( $enc, $validate, 'AC: Check getPOSTDate result. #2' );

$validate = {
    's_entity'  => '54cd',
    's_command' => 'COMMAND=ModifyDomain'
};
$enc = $cl->getPOSTData(
    {   COMMAND => 'ModifyDomain',
        AUTH    => undef
    }
);
is_deeply( $enc, $validate, 'AC: Check getPOSTData result. #3' );

# ~> enableDebugMode method test
$cl->enableDebugMode();

# ~> disableDebugMode method test
$cl->disableDebugMode();

# T68 ~> getSession method test
my $session = $cl->getSession();
is( $session, undef, 'AC: Check getSession result. #1' );
my $sessid = 'testSessionID12345678';
$cl->setSession($sessid);
$session = $cl->getSession();
is( $session, $sessid, 'AC: Check getSession result. #2' );
$cl->setSession(q{});

# T69 ~> getURL method test
my $url = $cl->getURL();
is( $url, 'https://coreapi.1api.net/api/call.cgi', 'AC: Check getURL result.' );

# T70 ~> setURL method test
$url = $cl->setURL('http://coreapi.1api.net/api/call.cgi')->getURL();
is( $url, 'http://coreapi.1api.net/api/call.cgi', 'AC: Check if setURL working.' );
$cl->setURL('https://coreapi.1api.net/api/call.cgi');

# - T72 ~> setOTP method test
$cl->setOTP('12345678');
$d = $cl->getPOSTData( { COMMAND => 'StatusAccount' } );
$validate = {
    's_entity'  => '54cd',
    's_otp'     => '12345678',
    's_command' => 'COMMAND=StatusAccount'
};
is_deeply( $d, $validate, 'AC: Check if setOTP method is working. #1' );
$cl->setOTP(q{});
$d = $cl->getPOSTData( { COMMAND => 'StatusAccount' } );
$validate = {
    's_entity'  => '54cd',
    's_command' => 'COMMAND=StatusAccount'
};
is_deeply( $d, $validate, 'AC: Check if setOTP method is working. #2' );

# - T75 ~> setSession method test
$cl->setSession('12345678');
$d = $cl->getPOSTData( { COMMAND => 'StatusAccount' } );
$validate = {
    's_entity'  => '54cd',
    's_session' => '12345678',
    's_command' => 'COMMAND=StatusAccount'
};
is_deeply( $d, $validate, 'AC: Check if setSession method is working. #1' );
$cl->setRoleCredentials( 'myaccountid', 'myrole', 'mypassword' );
$cl->setOTP('12345678');
$cl->setSession('12345678');
$d = $cl->getPOSTData( { COMMAND => 'StatusAccount' } );
is_deeply( $d, $validate, 'AC: Check if setSession method is working. #2' );
$cl->setSession(q{});
$d = $cl->getPOSTData( { COMMAND => 'StatusAccount' } );
$validate = {
    's_entity'  => '54cd',
    's_command' => 'COMMAND=StatusAccount'
};
is_deeply( $d, $validate, 'AC: Check if setSession method is working. #3' );

# T76 ~> saveSession/reuseSession method test
my $sessionobj = {};
$cl->setSession('12345678');
$cl->saveSession($sessionobj);
my $cl2 = WebService::Hexonet::Connector::APIClient->new();
$cl2->reuseSession($sessionobj);
$d = $cl2->getPOSTData( { COMMAND => 'StatusAccount' } );
$validate = {
    's_entity'  => '54cd',
    's_session' => '12345678',
    's_command' => 'COMMAND=StatusAccount'
};
is_deeply( $d, $validate, 'AC: Check if saveSession/reuseSession method is working.' );
$cl->setSession(q{});

# - T78 ~> setRemoteIPAddress method test
$cl->setRemoteIPAddress('10.10.10.10');
$d = $cl->getPOSTData( { COMMAND => 'StatusAccount' } );
$validate = {
    's_entity'     => '54cd',
    's_remoteaddr' => '10.10.10.10',
    's_command'    => 'COMMAND=StatusAccount'
};
is_deeply( $d, $validate, 'AC: Check if setRemoteIPAddress is working. #1' );
$cl->setRemoteIPAddress(q{});
$d = $cl->getPOSTData( { COMMAND => 'StatusAccount' } );
$validate = {
    's_entity'  => '54cd',
    's_command' => 'COMMAND=StatusAccount'
};
is_deeply( $d, $validate, 'AC: Check if setRemoteIPAddress is working. #2' );

# - T80 ~> setCredentials method test
$cl->setCredentials( 'myaccountid', 'mypassword' );
$d = $cl->getPOSTData( { COMMAND => 'StatusAccount' } );
$validate = {
    's_entity'  => '54cd',
    's_login'   => 'myaccountid',
    's_pw'      => 'mypassword',
    's_command' => 'COMMAND=StatusAccount'
};
is_deeply( $d, $validate, 'AC: Check if setCredentials is working. #1' );
$cl->setCredentials( q{}, q{} );
$d = $cl->getPOSTData( { COMMAND => 'StatusAccount' } );
$validate = {
    's_entity'  => '54cd',
    's_command' => 'COMMAND=StatusAccount'
};
is_deeply( $d, $validate, 'AC: Check if setCredentials is working. #2' );

# - T82 ~> setRoleCredentials method test
$cl->setRoleCredentials( 'myaccountid', 'myroleid', 'mypassword' );
$d = $cl->getPOSTData( { COMMAND => 'StatusAccount' } );
$validate = {
    's_entity'  => '54cd',
    's_login'   => 'myaccountid!myroleid',
    's_pw'      => 'mypassword',
    's_command' => 'COMMAND=StatusAccount'
};
is_deeply( $d, $validate, 'AC: Check if setRoleCredentials is working. #1' );
$cl->setRoleCredentials( q{}, q{}, q{} );
$d = $cl->getPOSTData( { COMMAND => 'StatusAccount' } );
$validate = {
    's_entity'  => '54cd',
    's_command' => 'COMMAND=StatusAccount'
};
is_deeply( $d, $validate, 'AC: Check if setRoleCredentials is working. #2' );

# - T95 ~> login method test
$cl->useOTESystem();
$cl->setCredentials( 'test.user', 'test.passw0rd' );
$cl->setRemoteIPAddress('1.2.3.4');
$r   = $cl->login();
$cls = blessed($r);
is( $cls, 'WebService::Hexonet::Connector::Response', 'AC: Check if login method is working. #1' );
is( $r->isSuccess(), 1, 'AC: Check if login method is working. #2' );
$rec = $r->getRecord(0);
isnt( $rec, undef, 'AC: Check if login method is working. #3' );
is( $rec->getDataByKey('SESSION'), $r->getHash()->{PROPERTY}->{SESSION}[ 0 ], 'AC: Check if login method is working. #4' );
$cl->setRoleCredentials( 'test.user', 'testrole', 'test.passw0rd' );
$r   = $cl->login();
$cls = blessed($r);
is( $cls, 'WebService::Hexonet::Connector::Response', 'AC: Check if login method is working. #5' );
is( $r->isSuccess(), 1, 'AC: Check if login method is working. #6' );
$rec = $r->getRecord(0);
isnt( $rec, undef, 'AC: Check if login method is working. #7' );
is_deeply( $rec->getDataByKey('SESSION'), $r->getHash()->{PROPERTY}->{SESSION}[ 0 ], 'AC: Check if login method is working. #8' );
$cl->setCredentials( 'test.user', 'WRONGPASSWORD' );
$r   = $cl->login();
$cls = blessed($r);
is( $cls, 'WebService::Hexonet::Connector::Response', 'AC: Check if login method is working. #9' );
is( $r->isError(), 1,, 'AC: Check if login method is working. #10' );
$url = $cl->getURL();
$cl->setURL('http://noapiaccesshere.1api.net/api/call.cgi');
$r   = $cl->login();
$cls = blessed($r);
is( $cls,                 'WebService::Hexonet::Connector::Response',       'AC: Check if login method is working. #11' );
is( $r->isTmpError(),     1,                                                'AC: Check if login method is working. #12' );
is( $r->getDescription(), 'Command failed due to HTTP communication error', 'AC: Check if login method is working. #13' );
$cl->setURL($url);

# - T98 ~> loginExtended method test
$cl->setCredentials( 'test.user', 'test.passw0rd' );
$r = $cl->loginExtended( { TIMEOUT => 60 } );
$cls = blessed($r);
is( $cls, 'WebService::Hexonet::Connector::Response', 'AC: Check if loginExtended method is working. #1' );
is( $r->isSuccess(), 1, 'AC: Check if loginExtended method is working. #2' );
$rec = $r->getRecord(0);
isnt( $rec, undef, 'AC: Check if loginExtended method is working. #3' );
is( $rec->getDataByKey('SESSION'), $r->getHash()->{PROPERTY}->{SESSION}[ 0 ], 'AC: Check if loginExtended method is working. #4' );

# - T100 ~> logout method test
$r   = $cl->logout();
$cls = blessed($r);
is( $cls, 'WebService::Hexonet::Connector::Response', 'AC: Check if logout method is working. #1' );
is( $r->isSuccess(), 1, 'AC: Check if loginExtended method is working. #2' );
$cl->enableDebugMode();
$cl->setSession('SESSIONWONTEXIST');
$r   = $cl->logout();
$cls = blessed($r);
is( $cls, 'WebService::Hexonet::Connector::Response', 'AC: Check if logout method is working. #3' );
is( $r->isError(), 1, 'AC: Check if loginExtended method is working. #4' );

# ~> requestNextResponsePage method test
$cl->setCredentials( 'test.user', 'test.passw0rd' );
$tpl = $rtm->getTemplate('listP0');
my $cmd = { COMMAND => 'QueryDomainList', limit => 2, FIRST => 0 };
$r = WebService::Hexonet::Connector::Response->new( $tpl->getPlain(), $cmd );
my $nr = $cl->requestNextResponsePage($r);
is( $r->isSuccess(),             1,             'AC: Check if requestNextResponsePage is working. #1' );
is( $nr->isSuccess(),            1,             'AC: Check if requestNextResponsePage is working. #2' );
is( $r->getRecordsLimitation(),  2,             'AC: Check if requestNextResponsePage is working. #3' );
is( $nr->getRecordsLimitation(), 2,             'AC: Check if requestNextResponsePage is working. #4' );
is( $r->getRecordsCount(),       2,             'AC: Check if requestNextResponsePage is working. #5' );
is( $nr->getRecordsCount(),      2,             'AC: Check if requestNextResponsePage is working. #6' );
is( $r->getFirstRecordIndex(),   0,             'AC: Check if requestNextResponsePage is working. #7' );
is( $r->getLastRecordIndex(),    1,             'AC: Check if requestNextResponsePage is working. #8' );
is( $nr->getFirstRecordIndex(),  2,             'AC: Check if requestNextResponsePage is working. #9' );
is( $nr->getLastRecordIndex(),   $LAST_REC_IDX, 'AC: Check if requestNextResponsePage is working. #10' );

#$cmd->{LAST} = 1;
#$r = WebService::Hexonet::Connector::Response->new($tpl->getPlain(), $cmd);
#TODO: no idea how to test croak

$cl->disableDebugMode();
$cmd = { COMMAND => 'QueryDomainList', LIMIT => 2 };
$r = WebService::Hexonet::Connector::Response->new( $tpl->getPlain(), $cmd );
$nr = $cl->requestNextResponsePage($r);
is( $r->isSuccess(),             1,             'AC: Check if requestNextResponsePage is working. #11' );
is( $nr->isSuccess(),            1,             'AC: Check if requestNextResponsePage is working. #12' );
is( $r->getRecordsLimitation(),  2,             'AC: Check if requestNextResponsePage is working. #13' );
is( $nr->getRecordsLimitation(), 2,             'AC: Check if requestNextResponsePage is working. #14' );
is( $r->getRecordsCount(),       2,             'AC: Check if requestNextResponsePage is working. #15' );
is( $nr->getRecordsCount(),      2,             'AC: Check if requestNextResponsePage is working. #16' );
is( $r->getFirstRecordIndex(),   0,             'AC: Check if requestNextResponsePage is working. #17' );
is( $r->getLastRecordIndex(),    1,             'AC: Check if requestNextResponsePage is working. #18' );
is( $nr->getFirstRecordIndex(),  2,             'AC: Check if requestNextResponsePage is working. #19' );
is( $nr->getLastRecordIndex(),   $LAST_REC_IDX, 'AC: Check if requestNextResponsePage is working. #20' );

# ~> requestAllResponsePages method test
$nr = $cl->requestAllResponsePages( { COMMAND => 'QueryDomainList', FIRST => 0, LIMIT => $CMD_LIMIT } );
isnt( scalar @{$nr}, 0, 'AC: Check if requestAllResponsePages is working. #1' );

# ~> setUserView method test
$cl->setUserView('hexotestman.com');
$r = $cl->request( { COMMAND => 'GetUserIndex' } );
$cls = blessed($r);
is( $cls, 'WebService::Hexonet::Connector::Response', 'AC: Check if setUserView method is working. #1' );
is( $r->isSuccess(), 1, 'AC: Check if setUserView method is working. #2' );

# ~> resetUserView method test
$cl->resetUserView();
$r = $cl->request( { COMMAND => 'GetUserIndex' } );
$cls = blessed($r);
is( $cls, 'WebService::Hexonet::Connector::Response', 'AC: Check if resetUserView method is working. #1' );
is( $r->isSuccess(), 1, 'AC: Check if resetUserView method is working. #2' );

# ~> getUserAgent method test
my $arch       = ( uname() )[ 4 ];
my $os         = ( uname() )[ 0 ];
my $rv         = $cl->getVersion();
my $uaexpected = "PERL-SDK ($os; $arch; rv:$rv) perl/$Config{version}";
my $ua         = $cl->getUserAgent();
is( $ua, $uaexpected, "AC: Check if getUserAgent method is working." );

# ~> setUserAgent method test
$uaexpected = "WHMCS ($os; $arch; rv:7.7.0) perl-sdk/$rv perl/$Config{version}";
$cls        = blessed( $cl->setUserAgent( "WHMCS", "7.7.0" ) );
$ua         = $cl->getUserAgent();
is( $cls, 'WebService::Hexonet::Connector::APIClient', 'AC: Check if setUserAgent method is working. #1' );
is( $ua, $uaexpected, "AC: Check if setUserAgent method is working. #2" );

done_testing();

1;
