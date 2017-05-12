# -*-Perl-*-
# $Id: CTlib.pm,v 1.45 2010/03/28 11:16:26 mpeppler Exp $
# @(#)CTlib.pm	1.27	03/26/99

# Copyright (c) 1995-2004
#   Michael Peppler
#
#   Parts of this file are
#   Copyright (c) 1995 Sybase, Inc.
#
#
#   You may copy this under the terms of the GNU General Public License,
#   or the Artistic License, copies of which should have accompanied
#   your Perl kit.

require 5.002;

use strict;

package Sybase::CTlib::_attribs;

use Carp;

 
sub FIRSTKEY {
    each %{$_[0]};
}

sub NEXTKEY {
    each %{$_[0]};
}

sub EXISTS{ 
     exists($_[0]->{$_[1]});
}


sub readonly {
    carp "Can't delete or clear attributes from a Sybase::CTlib handle.\n";
}

sub DELETE{ &readonly }
sub CLEAR { &readonly }

package Sybase::CTlib::Att;

use Carp;

sub TIEHASH {
    bless {UseDateTime => 0,
	   UseMoney => 0,
	   UseNumeric => 0,
	   UseBin0x => 1,
	   MaxRows => 0}
}
sub FETCH { 
    return $_[0]->{$_[1]} if (exists $_[0]->{$_[1]});
    return undef;
}
 
sub FIRSTKEY {
    each %{$_[0]};
}

sub NEXTKEY {
    each %{$_[0]};
}

sub EXISTS{ 
     exists($_[0]->{$_[1]});
}

sub STORE {
    croak("'$_[1]' is not a valid Sybase::CTlib attribute") if(!exists($_[0]->{$_[1]}));
    $_[0]->{$_[1]} = $_[2];
}

sub readonly { croak "\%Sybase::CTlib::Att is read-only\n" }

sub DELETE{ &readonly }
sub CLEAR { &readonly }

package Sybase::CTlib::DateTime;

# Sybase DATETIME handling.


# Here we set up overloading operators
# for certain operations.

use overload ("\"\"" => \&d_str,		# convert to string
	     "cmp" => \&d_cmp,		# compare two dates
	     "<=>" => \&d_cmp);		# same thing

sub d_str {
    my $self = shift;

    $self->str;
}

sub d_cmp {
    my ($left, $right, $order) = @_;

    $left->cmp($right, $order);
}

sub mktime {
    my $self = shift;
    my (@data, $ret);

    # Wrapped in an eval() in case POSIX is not compiled in this
    # copy of Perl.
    eval {
    require POSIX;		# This isn't very clean, but it speeds
				# up loading for something that is rarely
				# used...
    
    @data = $self->crack;

    $ret = POSIX::mktime($data[7], $data[6], $data[5], $data[2],
			 $data[1], $data[0]-1900);
    };
    $ret;
}

sub timelocal {
    my $self = shift;
    my (@data, $ret);

    # For converting to Unix time:

    require Time::Local;

    @data = $self->crack;

    $ret = Time::Local::timelocal($data[7], $data[6], $data[5], $data[2],
				  $data[1], $data[0]-1900);
}

sub timegm {
    my $self = shift;
    my (@data, $ret);

    @data = $self->crack;

    # For converting to Unix time:

    require Time::Local;
    $ret = Time::Local::timegm($data[7], $data[6], $data[5], $data[2],
			       $data[1], $data[0]-1900);
}


package Sybase::CTlib::Money;

# Sybase MONEY handling. Again, we set up overloading for
# certain operators (in particular the arithmetic ops.)

use overload ("\"\"" => \&m_str,		# Convert to string
	     "0+" => \&m_num,		# Convert to floating point
	     "<=>" => \&m_cmp,		# Compare two money items
	     "+" => \&m_add,		# These you can guess...
	     "-" => \&m_sub,
	     "*" => \&m_mul,
	     "/" => \&m_div);

    
sub m_str {
    my $self = shift;

    $self->str;
}

sub m_num {
    my $self = shift;

    $self->num;
}

sub m_cmp {
    my ($left, $right, $order) = @_;
    my $ret;

    $ret = $left->cmp($right, $order);
}

sub m_add {
    my ($left, $right) = @_;

    $left->calc($right, '+');
}
sub m_sub {
    my ($left, $right, $order) = @_;

    $left->calc($right, '-', $order);
}
sub m_mul {
    my ($left, $right) = @_;

    $left->calc($right, '*');
}
sub m_div {
    my ($left, $right, $order) = @_;

    $left->calc($right, '/', $order);
}

package Sybase::CTlib::Numeric;

# Sybase Numeric/Decimal handling. Again, we set up overloading for
# certain operators (in particular the arithmetic ops.)

use overload ("\"\"" => \&n_str,		# Convert to string
	     "0+" => \&n_num,		# Convert to floating point
	     "<=>" => \&n_cmp,		# Compare
	     "+" => \&n_add,		# These you can guess...
	     "-" => \&n_sub,
	     "*" => \&n_mul,
	     "/" => \&n_div);

    
sub n_str {
    my $self = shift;

    $self->str;
}

sub n_num {
    my $self = shift;

    $self->num;
}

sub n_cmp {
    my ($left, $right, $order) = @_;
    my $ret;

    $ret = $left->cmp($right, $order);
}

sub n_add {
    my ($left, $right) = @_;

    $left->calc($right, '+');
}
sub n_sub {
    my ($left, $right, $order) = @_;

    $left->calc($right, '-', $order);
}
sub n_mul {
    my ($left, $right) = @_;

    $left->calc($right, '*');
}
sub n_div {
    my ($left, $right, $order) = @_;

    $left->calc($right, '/', $order);
}


package Sybase::CTlib;

require Exporter;
use AutoLoader;
require DynaLoader;

use Carp;

#__SYBASE_START

#__SYBASE_END

use subs qw(CS_SUCCEED CS_FAIL CS_CMD_DONE CS_ROW_COUNT
  CS_ROW_RESULT CS_PARAM_RESULT CS_STATUS_RESULT CS_CURSOR_RESULT
  CS_COMPUTE_RESULT CS_CANCEL_CURRENT);

use vars qw(%Att @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD 
	    $res_type);
use vars qw($DB_ERROR $nsql_strip_whitespace $nsql_deadlock_retrycount
	   $nsql_deadlock_retrysleep $nsql_deadlock_verbose);

%EXPORT_TAGS = (minimal => [qw(CS_SUCCEED CS_FAIL ct_callback CS_CMD_FAIL)]);

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)
@EXPORT = qw( ct_callback ct_config cs_dt_info
	CS_12HOUR
	CS_ABSOLUTE
	CS_ACK
	CS_ADD
	CS_ALLMSG_TYPE
	CS_ALLOC
	CS_ALL_CAPS
	CS_ANSI_BINDS
	CS_APPNAME
	CS_ASYNC_IO
	CS_ASYNC_NOTIFS
	CS_BINARY_TYPE
	CS_BIT_TYPE
	CS_BLK_ALL
        CS_BLK_BATCH
	CS_BLK_HAS_TEXT
	CS_BOUNDARY_TYPE
	CS_BROWSE_INFO
	CS_BULK_CONT
	CS_BULK_DATA
	CS_BULK_INIT
	CS_BULK_LOGIN
	CS_BUSY
	CS_BYLIST_LEN
	CS_CANBENULL
	CS_CANCELED
	CS_CANCEL_ALL
	CS_CANCEL_ATTN
	CS_CANCEL_CURRENT
	CS_CAP_ARRAYLEN
	CS_CAP_REQUEST
	CS_CAP_RESPONSE
	CS_CHALLENGE_CB
	CS_CHARSETCNV
	CS_CHAR_TYPE
	CS_CLEAR
	CS_CLEAR_FLAG
	CS_CLIENTMSG_CB
	CS_CLIENTMSG_TYPE
	CS_CMD_DONE
	CS_CMD_FAIL
	CS_CMD_NUMBER
	CS_CMD_SUCCEED
	CS_COLUMN_DATA
	CS_COMMBLOCK
	CS_COMPARE
	CS_COMPLETION_CB
	CS_COMPUTEFMT_RESULT
	CS_COMPUTE_RESULT
	CS_COMP_BYLIST
	CS_COMP_COLID
	CS_COMP_ID
	CS_COMP_OP
	CS_CONNECTNAME
	CS_CONSTAT_CONNECTED
	CS_CONSTAT_DEAD
	CS_CONTINUE
	CS_CONV_ERR
	CS_CON_INBAND
	CS_CON_LOGICAL
	CS_CON_NOINBAND
	CS_CON_NOOOB
	CS_CON_OOB
	CS_CON_STATUS
	CS_CSR_ABS
	CS_CSR_FIRST
	CS_CSR_LAST
	CS_CSR_MULTI
	CS_CSR_PREV
	CS_CSR_REL
	CS_CURRENT_CONNECTION
	CS_CURSORNAME
	CS_CURSOR_CLOSE
	CS_CURSOR_DEALLOC
	CS_CURSOR_DECLARE
	CS_CURSOR_DELETE
	CS_CURSOR_FETCH
	CS_CURSOR_INFO
	CS_CURSOR_OPEN
	CS_CURSOR_OPTION
	CS_CURSOR_RESULT
	CS_CURSOR_ROWS
	CS_CURSOR_UPDATE
	CS_CURSTAT_CLOSED
	CS_CURSTAT_DEALLOC
	CS_CURSTAT_DECLARED
	CS_CURSTAT_NONE
	CS_CURSTAT_OPEN
	CS_CURSTAT_RDONLY
	CS_CURSTAT_ROWCOUNT
	CS_CURSTAT_UPDATABLE
	CS_CUR_ID
	CS_CUR_NAME
	CS_CUR_ROWCOUNT
	CS_CUR_STATUS
	CS_DATA_BIN
	CS_DATA_BIT
	CS_DATA_BITN
	CS_DATA_BOUNDARY
	CS_DATA_CHAR
	CS_DATA_DATE4
	CS_DATA_DATE8
	CS_DATA_DATETIMEN
	CS_DATA_DEC
	CS_DATA_FLT4
	CS_DATA_FLT8
	CS_DATA_FLTN
	CS_DATA_IMAGE
	CS_DATA_INT1
	CS_DATA_INT2
	CS_DATA_INT4
	CS_DATA_INT8
	CS_DATA_INTN
	CS_DATA_LBIN
	CS_DATA_LCHAR
	CS_DATA_MNY4
	CS_DATA_MNY8
	CS_DATA_MONEYN
	CS_DATA_NOBIN
	CS_DATA_NOBIT
	CS_DATA_NOBOUNDARY
	CS_DATA_NOCHAR
	CS_DATA_NODATE4
	CS_DATA_NODATE8
	CS_DATA_NODATETIMEN
	CS_DATA_NODEC
	CS_DATA_NOFLT4
	CS_DATA_NOFLT8
	CS_DATA_NOIMAGE
	CS_DATA_NOINT1
	CS_DATA_NOINT2
	CS_DATA_NOINT4
	CS_DATA_NOINT8
	CS_DATA_NOINTN
	CS_DATA_NOLBIN
	CS_DATA_NOLCHAR
	CS_DATA_NOMNY4
	CS_DATA_NOMNY8
	CS_DATA_NOMONEYN
	CS_DATA_NONUM
	CS_DATA_NOSENSITIVITY
	CS_DATA_NOTEXT
	CS_DATA_NOVBIN
	CS_DATA_NOVCHAR
	CS_DATA_NUM
	CS_DATA_SENSITIVITY
	CS_DATA_TEXT
	CS_DATA_VBIN
	CS_DATA_VCHAR
	CS_DATEORDER
CS_DATES_SHORT
CS_DATES_MDY1
CS_DATES_YMD1
CS_DATES_DMY1
CS_DATES_DMY2
CS_DATES_DMY3
CS_DATES_DMY4
CS_DATES_MDY2
CS_DATES_HMS
CS_DATES_LONG
CS_DATES_MDY3
CS_DATES_YMD2
CS_DATES_YMD3
CS_DATES_YDM1
CS_DATES_MYD1
CS_DATES_DYM1
CS_DATES_MDYHMS
CS_DATES_HMA
CS_DATES_HM
CS_DATES_HMSZA
CS_DATES_HMSZ
CS_DATES_YMDHMS
CS_DATES_YMDHMA
CS_DATES_YMDTHMS
CS_DATES_HMSUSA
CS_DATES_HMSUS
CS_DATES_LONGUSA
CS_DATES_LONGUS
CS_DATES_YMDHMSUS
CS_DATES_SHORT_ALT
CS_DATES_MDY1_YYYY
CS_DATES_YMD1_YYYY
CS_DATES_DMY1_YYYY
CS_DATES_DMY2_YYYY
CS_DATES_DMY3_YYYY
CS_DATES_DMY4_YYYY
CS_DATES_MDY2_YYYY
CS_DATES_HMS_ALT
CS_DATES_LONG_ALT
CS_DATES_MDY3_YYYY
CS_DATES_YMD2_YYYY
CS_DATES_YMD3_YYYY
CS_DATES_YDM1_YYYY
CS_DATES_MYD1_YYYY
CS_DATES_DYM1_YYYY
CS_DATES_MDYHMS_ALT
CS_DATES_YMDHMS_YYYY
CS_DATES_YMDHMA_YYYY
CS_DATES_HMSUSA_YYYY
CS_DATES_HMSUS_YYYY
CS_DATES_LONGUSA_YYYY
CS_DATES_LONGUS_YYYY
CS_DATES_YMDHMSUS_YYYY
	CS_DATETIME4_TYPE
	CS_DATETIME_TYPE
	CS_DAYNAME
	CS_DBG_ALL
	CS_DBG_API_LOGCALL
	CS_DBG_API_STATES
	CS_DBG_ASYNC
	CS_DBG_DIAG
	CS_DBG_ERROR
	CS_DBG_MEM
	CS_DBG_NETWORK
	CS_DBG_PROTOCOL
	CS_DBG_PROTOCOL_STATES
	CS_DEALLOC
	CS_DECIMAL_TYPE
	CS_DEFER_IO
	CS_DEF_PREC
	CS_DEF_SCALE
	CS_DESCIN
	CS_DESCOUT
	CS_DESCRIBE_INPUT
	CS_DESCRIBE_OUTPUT
	CS_DESCRIBE_RESULT
	CS_DIAG_TIMEOUT
	CS_DISABLE_POLL
	CS_DIV
	CS_DT_CONVFMT
	CS_DYNAMIC
	CS_DYN_CURSOR_DECLARE
	CS_EBADLEN
	CS_EBADPARAM
	CS_EBADXLT
	CS_EDIVZERO
	CS_EDOMAIN
	CS_EED_CMD
	CS_EFORMAT
	CS_ENCRYPT_CB
	CS_ENDPOINT
	CS_END_DATA
	CS_END_ITEM
	CS_END_RESULTS
	CS_ENOBIND
	CS_ENOCNVRT
	CS_ENOXLT
	CS_ENULLNOIND
	CS_EOVERFLOW
	CS_EPRECISION
	CS_ERESOURCE
	CS_ESCALE
	CS_ESTYLE
	CS_ESYNTAX
	CS_ETRUNCNOIND
	CS_EUNDERFLOW
	CS_EXECUTE
	CS_EXEC_IMMEDIATE
	CS_EXPOSE_FMTS
	CS_EXPRESSION
	CS_EXTERNAL_ERR
	CS_EXTRA_INF
	CS_FAIL
	CS_FALSE
	CS_FIRST
	CS_FIRST_CHUNK
	CS_FLOAT_TYPE
	CS_FMT_JUSTIFY_RT
	CS_FMT_NULLTERM
	CS_FMT_PADBLANK
	CS_FMT_PADNULL
	CS_FMT_UNUSED
	CS_FORCE_CLOSE
	CS_FORCE_EXIT
	CS_FOR_UPDATE
	CS_GET
	CS_GETATTR
	CS_GETCNT
	CS_GOODDATA
	CS_HAFAILOVER
	CS_HASEED
	CS_HIDDEN
	CS_HIDDEN_KEYS
	CS_HOSTNAME
	CS_IDENTITY
	CS_IFILE
	CS_ILLEGAL_TYPE
	CS_IMAGE_TYPE
	CS_INIT
	CS_INPUTVALUE
	CS_INTERNAL_ERR
	CS_INTERRUPT
	CS_INT_TYPE
	CS_IODATA
	CS_ISBROWSE
	CS_KEY
	CS_LANG_CMD
	CS_LAST
	CS_LAST_CHUNK
	CS_LC_ALL
	CS_LC_COLLATE
	CS_LC_CTYPE
	CS_LC_MESSAGE
	CS_LC_MONETARY
	CS_LC_NUMERIC
	CS_LC_TIME
	CS_LOC_PROP
	CS_LOGIN_STATUS
	CS_LOGIN_TIMEOUT
	CS_LONGBINARY_TYPE
	CS_LONGCHAR_TYPE
	CS_LONG_TYPE
	CS_MAXSYB_TYPE
	CS_MAX_CAPVALUE
	CS_MAX_CHAR
	CS_MAX_CONNECT
	CS_MAX_LOCALE
	CS_MAX_MSG
	CS_MAX_NAME
	CS_MAX_NUMLEN
	CS_MAX_OPTION
	CS_MAX_PREC
	CS_MAX_REQ_CAP
	CS_MAX_RES_CAP
	CS_MAX_SCALE
	CS_MAX_SYBTYPE
	CS_MEM_ERROR
	CS_MEM_POOL
	CS_MESSAGE_CB
	CS_MIN_CAPVALUE
	CS_MIN_OPTION
	CS_MIN_PREC
	CS_MIN_REQ_CAP
	CS_MIN_RES_CAP
	CS_MIN_SCALE
	CS_MIN_SYBTYPE
	CS_MIN_USERDATA
	CS_MONEY4_TYPE
	CS_MONEY_TYPE
	CS_MONTH
	CS_MSGLIMIT
	CS_MSGTYPE
	CS_MSG_CMD
	CS_MSG_GETLABELS
	CS_MSG_LABELS
	CS_MSG_RESULT
	CS_MSG_TABLENAME
	CS_MULT
	CS_NETIO
	CS_NEXT
	CS_NOAPI_CHK
	CS_NODATA
	CS_NODEFAULT
	CS_NOINTERRUPT
	CS_NOMSG
	CS_NOTIFY_ALWAYS
	CS_NOTIFY_NOWAIT
	CS_NOTIFY_ONCE
	CS_NOTIFY_WAIT
	CS_NOTIF_CB
	CS_NOTIF_CMD
	CS_NO_COUNT
	CS_NO_LIMIT
	CS_NO_RECOMPILE
	CS_NO_TRUNCATE
	CS_NULLDATA
	CS_NULLTERM
	CS_NUMDATA
	CS_NUMERIC_TYPE
	CS_NUMORDERCOLS
	CS_NUM_COMPUTES
	CS_OBJ_NAME
	CS_OPTION_GET
	CS_OPT_ANSINULL
	CS_OPT_ANSIPERM
	CS_OPT_ARITHABORT
	CS_OPT_ARITHIGNORE
	CS_OPT_AUTHOFF
	CS_OPT_AUTHON
	CS_OPT_CHAINXACTS
	CS_OPT_CHARSET
	CS_OPT_CURCLOSEONXACT
	CS_OPT_CURREAD
	CS_OPT_CURWRITE
	CS_OPT_DATEFIRST
	CS_OPT_DATEFORMAT
	CS_OPT_FIPSFLAG
	CS_OPT_FMTDMY
	CS_OPT_FMTDYM
	CS_OPT_FMTMDY
	CS_OPT_FMTMYD
	CS_OPT_FMTYDM
	CS_OPT_FMTYMD
	CS_OPT_FORCEPLAN
	CS_OPT_FORMATONLY
	CS_OPT_FRIDAY
	CS_OPT_GETDATA
	CS_OPT_IDENTITYOFF
	CS_OPT_IDENTITYON
	CS_OPT_ISOLATION
	CS_OPT_LEVEL1
	CS_OPT_LEVEL3
	CS_OPT_MONDAY
	CS_OPT_NATLANG
	CS_OPT_NOCOUNT
	CS_OPT_NOEXEC
	CS_OPT_PARSEONLY
	CS_OPT_QUOTED_IDENT
	CS_OPT_RESTREES
	CS_OPT_ROWCOUNT
	CS_OPT_SATURDAY
	CS_OPT_SHOWPLAN
	CS_OPT_STATS_IO
	CS_OPT_STATS_TIME
	CS_OPT_STR_RTRUNC
	CS_OPT_SUNDAY
	CS_OPT_TEXTSIZE
	CS_OPT_THURSDAY
	CS_OPT_TRUNCIGNORE
	CS_OPT_TUESDAY
	CS_OPT_WEDNESDAY
	CS_OP_AVG
	CS_OP_COUNT
	CS_OP_MAX
	CS_OP_MIN
	CS_OP_SUM
	CS_ORDERBY_COLS
	CS_PACKAGE_CMD
	CS_PACKETSIZE
	CS_PARAM_RESULT
	CS_PARENT_HANDLE
	CS_PARSE_TREE
	CS_PASSTHRU_EOM
	CS_PASSTHRU_MORE
	CS_PASSWORD
	CS_PENDING
	CS_PREPARE
	CS_PREV
	CS_PROCNAME
	CS_PROTO_BULK
	CS_PROTO_DYNAMIC
	CS_PROTO_DYNPROC
	CS_PROTO_NOBULK
	CS_PROTO_NOTEXT
	CS_PROTO_TEXT
	CS_QUIET
	CS_READ_ONLY
	CS_REAL_TYPE
	CS_RECOMPILE
	CS_RELATIVE
	CS_RENAMED
	CS_REQ_BCP
	CS_REQ_CURSOR
	CS_REQ_DYN
	CS_REQ_LANG
	CS_REQ_MSG
	CS_REQ_MSTMT
	CS_REQ_NOTIF
	CS_REQ_PARAM
	CS_REQ_RPC
	CS_REQ_URGNOTIF
	CS_RES_NOEED
	CS_RES_NOMSG
	CS_RES_NOPARAM
	CS_RES_NOSTRIPBLANKS
	CS_RES_NOTDSDEBUG
	CS_RETURN
        CS_RET_HAFAILOVER
	CS_ROWFMT_RESULT
	CS_ROW_COUNT
	CS_ROW_FAIL
	CS_ROW_RESULT
	CS_RPC_CMD
	CS_SEC_APPDEFINED
	CS_SEC_CHALLENGE
	CS_SEC_ENCRYPTION
	CS_SEC_NEGOTIATE
	CS_SEND
	CS_SEND_BULK_CMD
	CS_SEND_DATA_CMD
	CS_SENSITIVITY_TYPE
	CS_SERVERMSG_CB
	CS_SERVERMSG_TYPE
	CS_SERVERNAME
	CS_SET
	CS_SETATTR
	CS_SETCNT
	CS_SET_DBG_FILE
	CS_SET_FLAG
	CS_SET_PROTOCOL_FILE
	CS_SHORTMONTH
	CS_SIGNAL_CB
	CS_SIZEOF
	CS_SMALLINT_TYPE
	CS_SORT
	CS_SQLSTATE_SIZE
	CS_SRC_VALUE
	CS_STATEMENTNAME
	CS_STATUS
	CS_STATUS_RESULT
	CS_SUB
	CS_SUCCEED
	CS_SV_API_FAIL
	CS_SV_COMM_FAIL
	CS_SV_CONFIG_FAIL
	CS_SV_FATAL
	CS_SV_INFORM
	CS_SV_INTERNAL_FAIL
	CS_SV_RESOURCE_FAIL
	CS_SV_RETRY_FAIL
	CS_SYB_CHARSET
	CS_SYB_LANG
	CS_SYB_LANG_CHARSET
	CS_SYB_SORTORDER
	CS_SYNC_IO
	CS_TABNAME
	CS_TABNUM
	CS_TDS_40
	CS_TDS_42
	CS_TDS_46
	CS_TDS_495
	CS_TDS_50
	CS_TDS_VERSION
	CS_TEXTLIMIT
	CS_TEXT_TYPE
	CS_THREAD_RESOURCE
	CS_TIMED_OUT
	CS_TIMEOUT
	CS_TIMESTAMP
	CS_TINYINT_TYPE
	CS_TP_SIZE
	CS_TRANSACTION_NAME
	CS_TRANS_STATE
	CS_TRAN_COMPLETED
	CS_TRAN_FAIL
	CS_TRAN_IN_PROGRESS
	CS_TRAN_STMT_FAIL
	CS_TRAN_UNDEFINED
	CS_TRUE
	CS_TRUNCATED
	CS_TRYING
	CS_TS_SIZE
	CS_UNUSED
	CS_UPDATABLE
	CS_UPDATECOL
	CS_USERDATA
	CS_USERNAME
	CS_USER_ALLOC
	CS_USER_FREE
	CS_USER_MAX_MSGID
	CS_USER_MSGID
	CS_USER_TYPE
	CS_USE_DESC
	CS_VARBINARY_TYPE
	CS_VARCHAR_TYPE
	CS_VERSION
	CS_VERSION_100
	CS_VERSION_KEY
	CS_VER_STRING
	CS_WILDCARD
	CS_ZERO
	      $DB_ERROR
);
# Other items we are prepared to export if requested
@EXPORT_OK = qw(TRACE_NONE TRACE_ALL TRACE_CREATE TRACE_DESTROY TRACE_SQL
    TRACE_RESULTS TRACE_FETCH TRACE_CURSOR TRACE_PARAMS	TRACE_OVERLOAD
		TRACE_CONVERT
    SQLCA_TYPE SQLCODE_TYPE SQLSTATE_TYPE
    CT_BIND CT_BR_COLUMN CT_BR_TABLE CT_CALLBACK CT_CANCEL CT_CAPABILITY
    CT_CLOSE CT_CMD_ALLOC CT_CMD_DROP CT_CMD_PROPS CT_COMMAND CT_COMPUTE_INFO
    CT_CONFIG CT_CONNECT CT_CON_ALLOC CT_CON_DROP CT_CON_PROPS CT_CON_XFER
    CT_CURSOR CT_DATA_INFO CT_DEBUG CT_DESCRIBE CT_DIAG CT_DYNAMIC
    CT_DYNDESC CT_EXIT CT_FETCH CT_GETFORMAT CT_GETLOGINFO CT_GET_DATA
    CT_INIT CT_KEYDATA CT_LABELS CT_NOTIFICATION CT_OPTIONS CT_PARAM
    CT_POLL CT_RECVPASSTHRU CT_REMOTE_PWD CT_RESULTS CT_RES_INFO CT_SEND
    CT_SENDPASSTHRU CT_SEND_DATA CT_SETLOGINFO CT_USER_FUNC CT_WAKEUP
);


tie %Att, 'Sybase::CTlib::Att';

sub AUTOLOAD {
    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    
    # The second argument to constant() is never used...
    my $val = constant($constname, 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Sybase::CTlib macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Sybase::CTlib;

# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.


# Use a hash table for fast lookups:

my %fetchable;

@fetchable{
  &CS_ROW_RESULT,
  &CS_PARAM_RESULT,
  &CS_STATUS_RESULT,
  &CS_CURSOR_RESULT,
  &CS_COMPUTE_RESULT} = (1) x 5;

sub ct_fetchable
{
    $fetchable{$_[1]};
}





sub ct_sql
{
    my($db, $cmd, $sub, $flag) = @_;
    my(@res, $data, $rc);
    local($res_type);  # it's local so that it can be examined by &$sub
    my $fail = 0;

    if($db->{'MaxRows'}) {
	$db->ct_options(&CS_SET, &CS_OPT_ROWCOUNT, $db->{MaxRows},
			&CS_INT_TYPE);
    }
    ($db->ct_execute($cmd) == &CS_SUCCEED) || return undef;

    $res_type = 0;		# avoid 'unitialized variable' warnings...
    $flag = 0 unless $flag;


    while(($rc = $db->ct_results($res_type)) == &CS_SUCCEED) {
        $db->{'ROW_COUNT'} = $db->ct_res_info(&CS_ROW_COUNT)
            if $res_type == &CS_CMD_DONE;
	$fail = 1 if ($res_type == &CS_CMD_FAIL);
	next unless $fetchable{$res_type};

	if($Sybase::CTlib::ct_sql_nostatus && $res_type == &CS_STATUS_RESULT) {
	    while ($data = $db->ct_fetch(0, 1)) {
		;   #skip return codes from procs...
	    }
	}

        while ($data = $db->ct_fetch($flag, 1)) {
            if (defined $sub) {
		if($flag) {
		    &$sub(%$data);
		} else {
		    &$sub(@$data);
		}
            } else {
		if($flag) {
		    push(@res, {%$data});
		} else {
		    push(@res, [@$data]);
		}
            }
        }
    }
    if($db->{'MaxRows'}) {
	$db->ct_options(&CS_SET, &CS_OPT_ROWCOUNT, 0, &CS_INT_TYPE);
    }
    $db->{RC} = $fail ? CS_FAIL : $rc;
    wantarray ? @res : \@res;  # return the result array
}

######
## nsql()
######

#
# Enhanced sql routine.
# 

sub DB_ERROR { return $DB_ERROR; }
 

sub nsql {
    my ($db,$sql,$type,$callback) = @_;
    my (@res,$data,$restype);
    my $retrycount = $nsql_deadlock_retrycount;
    my $retrysleep = $nsql_deadlock_retrysleep || 60;
    my $retryverbose = $nsql_deadlock_verbose;

    if ( ref $type ) {
	$type = ref $type;
    }
    elsif ( not defined $type ) {
	$type = "";
    }

    undef $DB_ERROR;
 
  DEADLOCK:
    {	
	local $^W = 0;		# shut up warnings.
	
	return unless $db->ct_execute($sql);

	while($db->ct_results($restype) == &CS_SUCCEED) {
	    if($restype == &CS_FAIL) {
		if ( $nsql_deadlock_retrycount && 
		     $DB_ERROR =~ /Message: 1205\b/m ) {
		    if ( $retrycount < 0 || $retrycount-- ) {
			carp "SQL deadlock encountered.  Retrying...\n" if $retryverbose;
			undef $DB_ERROR;
			@res = ();
			sleep($retrysleep);
			redo DEADLOCK;
		    } else {
			carp "SQL deadlock retry failed $nsql_deadlock_retrycount times.  Aborting.\n" if $retryverbose;
			last DEADLOCK;
		    }
		}
		
	    }
	    next unless $db->ct_fetchable($restype);

	    if($Sybase::CTlib::ct_sql_nostatus && $restype == &CS_STATUS_RESULT) {
		while ($data = $db->ct_fetch(0, 1)) {
		    ;   #skip return codes from procs...
		}

		next;
	    }

	    
	    if ( $type eq "HASH" ) {
		while ( $data = $db->ct_fetch(1, 1) ) {
		    grep($data->{$_} =~ s/\s+$//g,keys %$data) if $nsql_strip_whitespace;
		    if ( ref $callback eq "CODE" ) {
			unless ( $callback->(%$data) ) {
			    $db->ct_cancel(&CS_CANCEL_ALL);   # XXX
			    $DB_ERROR = "User-defined callback subroutine failed\n";
			    return;
			} 
		    }
		    else {
			push(@res,{%$data});
		    }
		}
	    }
	    elsif ( $type eq "ARRAY" ) {
		while ( $data = $db->ct_fetch(0, 1) ) {
		    grep(s/\s+$//g,@$data) if $nsql_strip_whitespace;
		    if ( ref $callback eq "CODE" ) {
			unless ( $callback->(@$data) ) {
			    $db->ct_cancel(&CS_CANCEL_ALL);
			    $DB_ERROR = "User-defined callback subroutine failed\n";
			    return;
			} 
		    }
		    else {
			push(@res,( @$data == 1 ? $data->[0] : [@$data] ));
		    }
		}
	    }
	    else {
		# If you ask for nothing, you get nothing.  But suck out
		# the data just in case.
		while ( $data = $db->ct_fetch(0, 1) ) { 1; }
		$res[0]++;	# Return non-null (true)
	    }
	    
	}
	
	last DEADLOCK;
	
    }

    #
    # If we picked any sort of error, then don't feed the data back.
    #
    if ( $DB_ERROR ) {
	return;
    }
    elsif ( ref $callback eq "CODE" ) {
	return 1;
    }
    else {
	return @res;
    }
}

sub nsql_srv_cb {
    my($dbh, $number, $severity, $state, $line, $server, $proc, $msg)
	= @_;

    # Don't print informational or status messages
    if($severity > 0) {
	$DB_ERROR  = "Message: $number\n";
	$DB_ERROR .= "Severity: $severity\n";
	$DB_ERROR .= "State: $state\n";
	$DB_ERROR .= "Server: $server\n" if defined $server;
	$DB_ERROR .= "Procedure: $proc\n" if defined $proc;
	$DB_ERROR .= "Line: $line\n" if defined $line;
	$DB_ERROR .= "Text: $msg\n";
    }
    CS_SUCCEED;
}



1;
__END__

=head1 NAME

Sybase::CTlib - Sybase Client Library API.

=head1 SYNOPSIS

    use Sybase::CTlib;
    
    $dbh = Sybase::CTlib->new('user', 'pwd', 'server');
    $dbh->ct_execute("select * from master..sysprocesses");
    while($dbh->ct_results($restype) == CS_SUCCEED) {
        if($restype == CS_CMD_FAIL) {
            warn "Command failed!";
            next;
        }
	next unless $dbh->ct_fetchable($restype);
	while(@data = $dbh->ct_fetch) {
	    print "@data\n";
	}
    }

=head1 DESCRIPTION

Sybase::CTlib implements a subset of the Sybase Open Client Client Library
API. For the most part the syntax is the same or very similar to the C 
language version, though in some cases the syntax varies a little to
make the life of the perl programmer a  little easier.

It is a good idea to have the Sybase Client Library reference manual 
available when writing Sybase::CTlib programs. The Sybase manuals are
available on-line at http://sybooks.sybase.com/. This manual is not
a replacement for the Sybase manuals of Client Library - it is mostly 
aimed at illustrating the differences between the Perl and C versions
of the API and to give a basic understanding of the APIs.

=head2 General Information

The basic philosphy of Client Library (CTlib) is to send a command to the
server, and then process any results and fetch data as needed. Commands can 
be sent as plain SQL with one or more statements, or they can be sent
as Remote Procedure Calls (RPCs). 

CTlib can connect and interact with 
any type of server that understands Sybase's Tabular Data Stream (TDS)
protocol. This means that you can use CTlib to connect to a Sybase
database server, a replication server, or any other type of server that
was built with the Open Server API.

A typical database request starts with a call to ct_execute() with
the SQL command to be executed. This sends the request to the server. You
the call ct_results($restype) in a loop until it stops returning CS_SUCCEED.
ct_results() sets the $restype (the result I<type>) for each result set.
Some of the result types do not include any fetchable rows, hence the
ct_fetchable() routine that returns TRUE if a $restype value is one that
includes fetchable data:

    $dbh->ct_execute("select * from master..sysprocesses");
    while($dbh->ct_results($restype) == CS_SUCCEED) {
        if($restype == CS_CMD_FAIL) {
            warn "Command failed!";
            next;
        }
	next unless $dbh->ct_fetchable($restype);
	while(@data = $dbh->ct_fetch) {
	    print "@data\n";
	}
    }

ct_execute() will return CS_FAIL if there is an error on the client side.
Errors that occur on the server will be reported via the server message
callback handler (see ct_callback()), and will in most cases result
in a $restype value of CS_CMD_FAIL.

In the case of an error occuring inside a stored procedure or trigger
the error is I<NOT> reported via a CS_CMD_FAIL $restype. Instead 
the return status of the stored procedure ($restype of CS_STATUS_RESULT) 
is set to -4.

It is a good idea to check for error conditions in-line (i.e. check the
return value of all API calls), to check the value of $restype returned 
from ct_results() for a possible CS_CMD_FAIL status, to check any 
stored procedure status value (CS_STATUS_RESULT result set) for a negative
value (which generally indicates that an error occured in the stored 
procedure), I<and> install server and client error handlers via ct_callback()
to flag any errors (server or client messages where the $severity value is 
greater than 10).

=head2 Routines:

=over 4

=item $dbh = new Sybase::CTlib $user [, $passwd [, $server [, $appname[, {attributes}]]]]

=item $dbh = Sybase::CTlib->ct_connect($user [, $passwd [, $server [,$appname, [{attributes}]]]])

Establishes a connection to the database engine. Initializes and
allocates resources for the connection, and registers the user name,
password, target server, and application name.

The B<attributes> hash reference can be used to add private attributes
to the connection handle that you can later use, and can also be used to 
set certain connection properties.

To set the connection properties you pass a special hash in the
B<attributes> parameter:

	$dbh = new Sybase::CTlib 'user', 'pwd', 'SYBASE', undef, 
	           { CON_PROPS => { CS_HOSTNAME => 'kiruna',
                                    CS_PACKETSIZE => 1024,
				    CS_SEC_CHALLENGE => CS_TRUE }
                   };

The following connection properties are currently recognized:

=over 4

=item CS_HOSTNAME

=item CS_ANSI_BINDS

=item CS_PACKETSIZE

=item CS_SEC_APPDEFINED

=item CS_SEC_CHALLENGE

=item CS_SEC_ENCRYPTION

=item CS_SEC_NEGOTIATE

=item CS_HAFAILOVER

=back

See the Sybase documentation on how and when to use these connection
properties.

Please see the Sybase manuals for B<CS_HAFAILOVER> usage.

In addition, you can set the B<CS_SYB_LANG> and B<CS_SYB_CHARSET> properties
in the same manner. However - you should be aware that these settings affect
all open connections, not just the one that you are opening with this call
to ct_connect(). This behavior will likely change in the future.


=item $status = $dbh->ct_execute($sql)

Send the SQL commands $sql to the server. Multiple commands are
allowed. However, you must call ct_results() until it returns
CS_END_RESULTS or CS_FAIL, or call ct_cancel() before submitting a new
set of SQL commands to the server.

Return values: CS_SUCCEED, CS_FAIL or CS_CANCELED (the operation was
canceled).

B<NOTE:> ct_execute() is equivalent to calling ct_command() followed by
ct_send(). 

=item $status = $dbh->ct_command(type, buffer, len, option)

Append a command to the current SQL command buffer. Please check the
OpenClient documentation for exact usage.

B<NOTE:> You should only need to call ct_command()/ct_send() directly
if you want to do RPCs or cursor operations. For straight queries you
should use ct_execute() or ct_sql() instead.

=item $status = $dbh->ct_send

Send the current command buffer to the server for execution.

B<NOTE:> You only need to call ct_send() directly if you've used
ct_command() to set up your SQL query.

=item $status = $dbh->ct_results($res_type [, $textBind])

This routine returns a results type to indicate the status of returned
data. "Command Done:" result type is returned if one result set has
been processed. "Row result" token is returned if regular rows are
returned. This output is stored in $res_type.

If the optional $textBind parameter is B<FALSE> then I<TEXT> or
I<IMAGE> columns are B<not> bound, and will not be subsequently
returned by ct_fetch(). Using this feature is a little tricky - please
see the discussion on raw B<TEXT> and B<IMAGE> handling elsewhere in this
document.

The commonly used values for $res_type are CS_ROW_RESULT, CS_CMD_DONE,
CS_CMD_SUCCEED, CS_COMPUTE_RESULT, CS_CMD_FAIL. The full list of
values is on page 3-203 of the OpenClient reference manual.

See also the description of ct_fetchable() below.

The $status value takes the following values: CS_SUCCEED,
CS_END_RESULTS, CS_FAIL, CS_CANCELED.

=item @names = $dbh->ct_col_names

Retrieve the column names of the current query. If the current query
is not a select statement, then an empty array is returned.

=item @types = $dbh->ct_col_types([$doAssoc])

Retrieve the column types of the currently executing query. If
$doAssoc is non-0, then a hash (aka associative array) is returned
with column names/column type pairs.

=item @data = $dbh->ct_describe([$doAssoc])

Retrieves the description of each of the output columns of the current
result set. Each element of the returned array is a reference to a
hash that describes the column. The following fields are set: B<NAME>,
B<TYPE>, B<SYBTYPE>, B<MAXLENGTH>, B<SCALE>, B<PRECISION>, B<STATUS>.

You could use it like this:

    $dbh->ct_execute("select name, uid from sysusers");
    while(($rc = $dbh->ct_results($restype)) == CS_SUCCEED) {
        next unless $dbh->ct_fetchable($restype);

	@desc = $dbh->ct_describe;
	print "$desc[0]->{NAME}\n";         # prints 'name'
	print "$desc[0]->{MAXLENGTH}\n";    # prints 30

	....
    }

The B<STATUS> field is a bitmask which can be tested for the following
values: CS_CANBENULL, CS_HIDDEN, CS_IDENTITY, CS_KEY, CS_VERSION_KEY,
CS_TIMESTAMP and CS_UPDATEABLE. See table 3-46 of the Open Client
Client Library Reference Manual for a description of each of these values.

The B<TYPE> field is the data type that Sybase::CTlib converts the column 
I<to> when retrieving the data, so a DATETIME column will be returned as a 
CS_CHAR_TYPE column, unless the B<UseDateTime> attribute described elsewhere 
in this document is turned on.

The B<SYBTYPE> field is the real Sybase data type for this column.


=item @data = $dbh->ct_fetch([$doAssoc [, $wantRef]])

Retrieve one row of data. If $doAssoc is non-0, a hash is returned
with column name/value pairs.

If $wantRef is non-0, then a B<reference> to an array (or hash)
is returned. This reference I<points> to a static array (or hash), so
to store the returned rows in an array you must copy the array (or hash):

   while($d = $dbh->ct_fetch(1, 1)) {
      push(@rows, {%$d});
   }

An empty array is returned if there is no data to fetch.

=item $dbh->ct_cancel($type)

Issue an attention signal to the server about the current
transaction. If $type == CS_CANCEL_ALL, then cancels the current
command immediately. If $type == CS_CANCEL_ATTN, then discard all
results when next time the application reads from the server.

=item $status = $dbh->DBDEAD

Calls ct_con_props(CS_CON_STATUS) on the connection and returns TRUE if 
the connection status CS_CONSTAT_DEAD bit is set. If this call returns
TRUE (i.e. non-0) the connection has been marked DEAD and you need to 
reconnect to the server.

=item $old_cb = ct_callback($type, $cb_func)

Install a callback routine. Valid callback types are CS_CLIENTMSG_CB
and CS_SERVERMSG_CB. Returns a reference to the previously installed
callback of the specified type, or I<undef> if no callback of that type
exists. Passing undef as $cb_func unsets the callback for that type.

=item $res_info = $dbh->ct_res_info($info_type)

Retrieves information on the current result set. The type of
information returned depends on $info_type. Currently supported values
are: CS_NUM_COMPUTES, CS_NUMDATA, CS_NUMORDERCOLS, CS_ROW_COUNT.

=item ($status, $param) = $dbh->ct_options($action, $option, $param, $type)

This routine will set, retrieve, or clear the values of server
query-processing options.

Values for $action: CS_SET, CS_GET, CS_CLEAR

Values for $option: see p. 3-170 of the OpenClient reference manual

Values for $param: When setting an option, $param can be a integer or
a string. When retrieving an option, $param is set and returned. When
clearing an option, $param is ignored.

Value for $type: CS_INT_TYPE if $param is of integer type,
CS_CHAR_TYPE if $param is a string

=item $ret = $dbh->ct_cursor($type, $name, $text, $option)

Initiate a cursor command. Usage is similar to the CT-Library
ct_cursor() call, except that when in C you would pass NULL as the
value for $name or $text you pass the special Perl value I<undef>
instead.

See eg/ct_cursor.pl for an example.

=item $ret = $dbh->ct_param(\%datafmt)

Define a command parameter. The %datafmt hash is used to pass the
appropriate parameters to the call. The following fields are defined:
name (parameter name), datatype, status, indicator, and value. These
fields correspond to the equivalent fields in the CS_DATAFMT structure
which is used in the CT-Library ct_param call, and includes the two
additional parameters 'value' and 'indicator'.

The hash should be used like this:

  %param = (name => '@acc', datatype => CS_CHAR_TYPE,
            status => CS_INPUTVALUE, value => 'CIS 98941',
	    indicator => CS_UNUSED);

  $dbh->ct_param(\%param);

Note that ct_param() converts all parameter types to either
CS_CHAR_TYPE, CS_FLOAT_TYPE, CS_DATETIME_TYPE, CS_MONEY_TYPE or
CS_INT_TYPE.

See eg/ct_param.pl for an example.

=item $dbh2 = $dbh->ct_cmd_alloc

Allocate a new I<CS_COMMAND> structure. The new $dbh2 shares the
I<CS_CONNECTION> with the original $dbh, so this is really only
useful for interleaving cursor operations (see ct_cursor() above, and
the section on cursors in Chapter 2 of the
I<Open Client Client-Library/C Reference Manual>).

The two handles also share attributes, so setting $dbh->{UseDataTime}
(for example) will also set $dbh2->{UseDateTime}.

=item $rc = $dbh->ct_cmd_realloc

Drops the current I<CS_COMMAND> structure, and reallocs a new
one. Returns CS_SUCCEED on successful completion.

=item $ret = ct_config($action, $property, $value, $type)

Calls ct_config() to change some basic parameter, like the
B<interfaces> file location.

$action can be B<CS_SET> or B<CS_GET>.

$property is one of the properties that is settable via ct_config()
(see your OpenClient man page on ct_config() for a complete list).

$value is the input value if $action is B<CS_SET>, and the output
value if $action is B<CS_GET>.

$type is the data type of the property that is being set or
retrieved. It defaults to B<CS_CHAR_TYPE>, but should be set to
B<CS_INT_TYPE> if an integer value (such as B<CS_NETIO>) is being set or
retrieved.

$ret is the return status of the ct_config() call.

Example:

	$ret = ct_config(CS_SET, CS_IFILE, "/home/mpeppler/foo", CS_CHAR_TYPE);
	print "$ret\n";

	$ret = ct_config(CS_GET, CS_IFILE, $out, CS_CHAR_TYPE);
	print "$ret - $out\n";  #prints 1 - /home/mpeppler/foo

=item $ret = $dbh->ct_dyn_prepare($sql)

Prepare a I<Dynamic SQL> statement. A Dynamic SQL statement is a normal
insert/update/delete SQL statement that includes '?' placeholders.
The placeholders are replaced by the values passed to ct_dyn_execute().
The prepared statement can be called multiple times with different variables,
making it quite efficient.

Sybase creates a temporary stored procedure for the dynamic SQL statement,
and then executes this procedure each time ct_dyn_execute() is called. Only
one active prepared statement can exist per connection.

Returns CS_SUCCEED on success, CS_FAIL in case of errors.

Example:

   $ret = $dbh->ct_dyn_prepare("update my_table set string=? where key=?");
   $dbh->ct_dyn_execute(["testing", 123]);
   while($dbh->ct_results($restype) == CS_SUCCEED) {
       next unless $dbh->ct_fetchable($restype);
       # shoudn't have any fetchable results in this example!
   }
   $dbh->ct_dyn_execute(["another test", 456]);
   while($dbh->ct_results($restype) == CS_SUCCEED) {
       next unless $dbh->ct_fetchable($restype);
       # shoudn't have any fetchable results in this example!
   }
   $dbh->ct_dyn_dealloc();    # free the temporary proc.

=item $ret = $dbh->ct_dyn_execute($arrayref);

Execute a prepared statement with the specified parameters. $arrayref is
a reference to an array with one value for each '?' that appears in the 
SQL statement passed to ct_dyn_prepare().

=item $ret = $dbh->ct_dyn_dealloc();

Free the resources associated with the prepared statement created by
ct_dyn_prepare(). This must be called before you can prepare a new 
statement. 

=item $ret = cs_dt_info($action, $type, $item, $buf)

cs_dt_info() allows you to set the default conversion modes for
I<DATETIME> values, and lets you query the locale database for
names for dateparts.

To set the default conversion you call cs_dt_info() with
a $type parameter of CS_DT_CONVFMT, and pass the conversion style
you want as the last parameter:

	cs_dt_info(CS_SET, CS_DT_CONVFMT, CS_UNUSED, CS_DATES_LONG);

See Table 2-26 in the Open Client and Open Server Common Libraries 
Reference Manual for details of other formats that are available.

You can query a datepart name by doing something like:

	cs_dt_info(CS_GET, CS_MONTH, 3, $buf);
	print "$buf\n";    # Prints 'April' in the default locale

Again see the entry for cs_dt_info() in Chapter 2 of the Open Client and
Open Server Common Libraries Reference Manual for details.

=item ($ret, $data) = $dbh->ct_get_data($colnum [, $maxsize])

Retrieve the raw TEXT or IMAGE data from column $colnum in the
current result set. The optional $maxsize parameter can be used
to limit the size of the retrieved buffer. If $maxsize is used then
ct_get_data() should be called in a loop until $ret == CS_END_DATA
(all the data for this column has been retrieved, and this is the
last column in the row) or $ret == CS_END_ITEM (all the data for this
column has been retrieved, but there are more columns to be processed).

The TEXT columns B<must> appear I<after> all the normal data columns
in the select list for this to work, and ct_results() must be called 
with $textBind set to 0.

See the discussion on raw TEXT/IMAGE processing elsewhere in this 
document.

=item $ret = $dbh->ct_send_data($data, $size)

Send $size bytes of data in $data to the server, based on information 
previously determined via a call to ct_data_info().

If the data item is large it can be stored in chunks by calling
ct_send_data() multiple times.

Please see the discussion on raw TEXT/IMAGE handling elsewhere in this
document for details.


=item $ret = $dbh->ct_data_info($action, $colnum [, \%attr [, $dbh_2]])

When $action is CS_GET ct_data_info() retrieves a CS_IODESC
struct for column $colnum. The CS_IODESC struct is stored internally
in the $dbh, and stores the text pointer, the total length and whether
logging should be turned on for updates.

The %attr hash can be used to set the B<total_txtlen> and
B<log_on_update> fields of the CS_IODESC by setting the 
corresponding fields in the %attr param:

	%attr = ( total_txtlen => 1024, log_on_update => 1 );
        $dbh->ct_data_info(CS_SET, $colnum, \%attr);

If $dbh_2 is passed and $action is CS_SET then the CS_IODESC struct
from $dbh_2 is copied to $dbh. This is useful if you need to update
TEXT columns in multiple rows by selecting the rows in one
connection and doing the update in a different connection.

The CS_IODESC struct is referenced when calling ct_send_data() to
tell OpenClient where to store the data that is being sent to the server,
as well as what the total size of the column is supposed to be.

The CS_IODESC is typically set during a select query to retrieve a valid
text pointer to the column that you wish to update. Sybase::CTlib is
limited to a single CS_IODESC struct per connection, so you can only
update a single TEXT or IMAGE column at a time.

For details on CS_IODESC please see the Sybase OpenClient 
Client Library Reference Manual.

For examples on the usage of ct_data_info() please see the discussion on 
raw TEXT processing elsewhere in this document.


=item $ret|@ret = $dbh->ct_sql($cmd [, \&rowcallback [, $doAssoc]])

Runs the sql command and returns the result as a reference to an array
of the rows.  Each row is a reference to an array of scalars. In a
LIST context, ct_sql returns an array of references to each row.

If the $doAssoc parameter is B<CS_TRUE>, then each row is a reference
to an associative array (keyed on the column names) rather than a
normal array (see ct_fetch(), above).

If you provide a second parameter it is taken as a procedure to call
for each row.  The callback is called with the values of the row as
parameters.

This routine is very useful to send SQL commands to the server that
do not return rows, such as:

    $dbh->ct_sql("use BugTrack");

Examples can be found in eg/ct_sql.pl.

B<NOTE:> This routine loads all the data into memory. Memory
consumption can therefore become quite important for a query that
returns a large number of rows, unless the B<MaxRows> attribute has
been set.

Two additional attributes are set after calling ct_sql(): B<ROW_COUNT>
holds the number of rows affected by the command, and B<RC> holds the
return code of the last call to ct_execute().

=item @ret = $dbh->nsql($sql [, "ARRAY" | "HASH" ] [, \&subroutine ] );

An enhanced version of the B<ct_sql> routine, B<nsql>, is also available.
nsql() provides better error checking (using its companion server error 
callback), optional deadlock retry logic, and several options
for the format of the return values.  In addition, the data can either
be returned to the caller in bulk, or processes line by line via a
callback subroutine passed as an argument.

The arguments are an SQL command to be executed, the B<$type> of the
data to be returned, and the callback subroutine.

if a callback subroutine is not given, then the data from the query is
returned as an array.  The array returned by nsql is one of the
following:

    Array of Hash References (if type eq HASH)
    Array of Array References (if type eq ARRAY)
    Simple Array (if type eq ARRAY, and a single column is queried)
    Boolean True/False value (if type ne ARRAY or HASH)

Optionally, instead of the words "HASH" or "ARRAY" a reference of the
same type can be passed as well.  That is, both of the following are
equivalent:

    $dbh->nsql("select col1,col2 from table","HASH");
    $dbh->nsql("select col1,col2 from table",{});

For example, the following code will return an array of hash
references:

    @ret = $dbh->nsql("select col1,col2 from table","HASH");
    foreach $ret ( @ret ) {
      print "col1 = ", $ret->{'col1'}, ", col2 = ", $ret->{'col2'}, "\n";
    }

The following code will return an array of array references:

    @ret = $dbh->nsql("select col1,col2 from table","ARRAY");
    foreach $ret ( @ret ) {
      print "col1 = ", $ret->[0], ", col2 = ", $ret->[1], "\n";
    }

The following code will return a simple array, since the select
statement queries for only one column in the table:

    @ret = $dbh->nsql("select col1 from table","ARRAY");
    foreach $ret ( @ret ) {
      print "col1 = $ret\n";
    }

Success or failure of an nsql() call cannot necessarily be judged
from the value of the return code, as an empty array may be a
perfectly valid result for certain sql code.
  
The nsql() routine will maintain the success or failure state in a
variable $DB_ERROR, accessed by the method of the same name, and a
Sybase server errror handler routine is also provided which
will use $DB_ERROR for the Sybase messages and errors as well.
However, these must be installed by the client application:

    ct_callback(CS_SERVERMSV_CB, \&Sybase::CTlib::nsql_srv_cb);

Success of failure of an nsql() call cannot necessarily be judged
from the value of the return code, as an empty array may be a
perfectly valid result for certain sql code.

The following code is the proper method for handling errors with use
of nsql.

    @ret = $dbh->nsql("select stuff from table where stuff = 'nothing'","ARRAY");
    if ( $DB_ERROR ) {
      # error handling code goes here, perhaps:
      die "Unable to get stuff from table: $DB_ERROR\n";
    }
  
The behavior of nsql() can be customized in several ways.  If the
variable:

    $Sybase::CTlib::nsql_strip_whitespace

is true, then nsql() will strip the trailing white spaces from all of
the scalar values in the results.

When using a callback subroutine, the subroutine is passed to nsql()
as a CODE reference.  For example:

    sub parse_hash {
      my %data = @_;
      # Do something with %data 
    }

    $dbh->nsql("select * from really_huge_table","HASH",\&parse_hash);
    if ( $DB_ERROR ) {
      # error handling code goes here, perhaps:
      die "Unable to get stuff from really_huge_table: $DB_ERROR\n";
    }

In this case, the data is passed to the callback (&parse_hash) as a
HASH, since that was the format specified as the second argument.  If
the second argument specifies an ARRAY, then the data is passed as an
array.  For example:

    sub parse_array {
      my @data = @_;
      # Do something with @data 
    }

    $dbh->nsql("select * from really_huge_table","HASH",\&parse_array);
    if ( $DB_ERROR ) {
      # error handling code goes here, perhaps:
      die "Unable to get stuff from really_huge_table: $DB_ERROR\n";
    }

The primary advantage of using the callback is that the rows are
processed one at a time, rather than returned in a huge
array.  For very large tables, this can result in very significant
memory consumption, and on resource-constrained machines, some large
queries may simply fail.  Processing rows individually will use much
less memory.

IMPORTANT NOTE: The callback subroutine must return a true value if it
has successfully handled the data.  If a false value is returned, then
the query is canceled via ct_cancel(), and nsql() will abort further
processing.

WARNING: Using the following deadlock retry logic together with a
callback routine is dangerous.  If a deadlock is encountered after
some rows have already been processed by the callback, then the data
will be processed a second time (or more, if the deadlock is retried
multiple times).

The nsql() method also supports automated retries of deadlock errors
(1205).  This is disabled by default, and enabled only if the
variable

    $Sybase::CTlib::nsql_deadlock_retrycount

is non-zero.  This variable is the number of times to resubmit a given
SQL query, and the variable

    $Sybase::CTlib::nsql_deadlock_retrysleep

is the delay, in seconds, between retries (default is 60).  Normally,
the retries happen silently, but if you want nsql() to carp() about
it, then set

    $Sybase::CTlib::nsql_deadlock_verbose

to a true value, and nsql() will whine about the failure.  If all of
the retries fail, then nsql() will return an error, as it normally
does.  If you want the code to try forever, then set the retry count
to -1.

=item $ret = $dbh->ct_fetchable($restype)

Returns TRUE if the current result set has fetchable rows.
Use like this:

    $dbh->ct_execute("select * from sysprocesses");
    while($dbh->ct_results($restype) == CS_SUCCEED) {
        next unless $dbh->ct_fetchable($restype);

	while(@dat = $dbh->ct_fetch) {
	    print "@dat\n";
	}
    }

=back

=head2 Bulk-Copy Routines (BLK API)

The following routines allow you to use a subset of the blk_*()
routines to bulk-copy data from Perl variables to Sybase tables.
The blk_*() routines are faster than normal inserts as they run with 
minimal logging.

You enable BLK operations on a Sybase::CTlib handle by passing the 
CS_BULK_LOGIN property to the new() or ct_connect() call:

   my $dbh = new Sybase::CTlib $user, $pwd, $server, $appname, 
                  {CON_PROPS => {CS_BULK_LOGIN => CS_TRUE }};

You then initialise the bulk-copy operation by calling blk_init(), send 
rows with blk_rowxfer(), commit rows with blk_done(), and end with a 
call to blk_drop() to clean up resources held during the bulk-copy operation.


Routines:

=over 4

=item $ret = $dbh->blk_init($table, $num_cols, $has_identity, $id_column)

This initializes a bulk-copy operation for the table $table. $num_cols
should be set to the number of columns of the target table. $has_identity
should be set if the target table has an identity column B<and> you provide
the identity values as part of your blk operation (i.e. if $has_identity is 
set, then the I<identity insert> option is set on the table). If you 
want to let the server set the identity values during the insert then leave
$has_identity I<off>, set $id_column to the column number of the identity 
column (remember that the first column is column 1, the second is 2, etc), 
and pass I<undef> as the values for that column.

See the t/2_ct_xblk.t test script for an example of both letting the
server set the identity values and specifying them directly.

Returns CS_SUCCEED or CS_FAIL.

=item $ret = $dbh->blk_rowxfer($data)

Send one row to the server. $data is an array reference, where each element
is the data for a column in the row.

By default, Sybase::CTlib attempts to convert incoming data to the target
format. These conversions can in some cases generate warnings, in particular
for NUMERIC data where the precision of the source data exceeds the
target column (for example trying to stored 123.456 to a numeric(6,2) 
column).

If such a conversion fails it generates a warning which is sent to the
client callback (see ct_callback()). You can convert the warning to an 
error by returning CS_FAIL from the callback.

Returns CS_SUCCEED or CS_FAIL.

=item $ret = $dbh->blk_done($type, $rows)

Commit a batch of rows, or all rows sent with blk_rowxfer(). $type should 
be one of CS_BLK_ALL, CS_BLK_BATCH or CS_BLK_CANCEL. As a side effect sets
$rows to the number of rows affected.

Returns CS_SUCCEED or CS_FAIL.

=item $dbh->blk_drop()

Free internal resources after a Bulk-copy operation has been performed.

=back

=head2 Handling data conversion errors with the BLK routines

The BLK API is much more picky about the data that it accepts
and so it is more likely to get data conversion errors when the
row is sent to the server via C<blk_rowxfer()>.

By default B<ALL> data conversion errors (other than string truncation for
char/varchar data) are flagged as failures, and the row will not get
uploaded, with an error message written to STDERR.

This behavior can be modified by registering a CS_MESSAGE_CB callback,
which will be called in the event of a data conversion error.

A typical CS_MESSAGE_CB subroutine might look like this:

  sub msg_cb {
    my ($layer, $origin, $severity, $number, $msg, $osmsg, $usermsg) = @_;

    print "$layer $origin $severity $number: $msg ($usermsg)\n";

    if($number == 36) {
      return CS_SUCCEED;
    }

    return CS_FAIL;
  }

and you would install it with a call to ct_callback():

  ct_callback(CS_MESSAGE_CB, \&msg_cb);

If the CS_MESSAGE_CB handler returns CS_SUCCEED then the conversion error
is ignored by the Sybase::CTlib code, and the row is sent to the BLK API
for processing. If the handler returns CS_FAIL then the row is skipped
and blk_rowxfer() will return CS_FAIL as well. Obviously you can't force
the BLK API to accept really bad data (such as "Feb 30 2000" for a date),
so even if your CS_MESSAGE_CB handler returns CS_SUCCEED the row can still
fail.

In my example above I decided to accept error number 36, which flags
truncation/scale errors (e.g. trying to load a value of 123.456 to a 
numeric(6,2) column, which results in 123.45 being loaded.), and to fail
all other conversion errors. 

It should be noted that when numeric values are truncated due to overflow
the values are B<truncated>, not rounded (so 123.456 is stored as 123.45.)

=head2 EXPERIMENTAL Asynchronous Routines

The following routines allow you to make asynchronous calls to the
server. The implementation is experimental, and might change in the
future, so please use with care.

Before attempting to use this feature you should read the "Asynchronous
Programming" chapter in the Sybase OpenClient - Client Library manuals 
to understand the concepts. Sybase::CTlib only provides a thin layer
over the Sybase API.

The Sybase API knows about I<synchronous> (the default), I<deferred IO> and 
I<async IO> modes. In the synchronous mode database requests block until
a response is available. In deferred IO mode database requests return 
immediately (with a return code of CS_PENDING), and you check for
completion with the ct_poll() call. In async IO mode the API uses
a I<completion callback> to notify the application of pending data
for async operations.

A connection can be set to async or deferred IO modes when it is idle,
via the ct_con_props() call:

	$dbh->ct_con_props(CS_SET, CS_NETIO, CS_DEFER_IO, CS_INT_TYPE);

Operations will now run in deferred mode, and the perl code will need
to be adapted somewhat to handle the async behaviour. Specifically, 
ct_results() won't set $restype correctly - this value will only get set
when ct_results() completes, which means that it has to be retrieved with
an alternative method. The same is true for ct_fetch(), which can't be used
in async or deferred modes.

Here is a simple (well, as simple as I can make it!) example of using the 
deferred IO mode:

   my $ret = $dbh->ct_con_props(CS_SET, CS_NETIO, CS_DEFER_IO, CS_INT_TYPE);

   $ret = $dbh->ct_execute("select * from large_table where val = 100");
   my $compid;
   my $compstatus;
   my $foo;

   $ret = $dbh->ct_poll(CS_NO_LIMIT, $foo, $compid, $compstatus);
   my $restype;
   while(($ret = $dbh->ct_results($restype)) == CS_SUCCEED || $ret == CS_PENDING) {
      if($ret == CS_PENDING) {
	 $ret = $dbh->ct_poll(CS_NO_LIMIT, $foo, $compid, $compstatus);
	 last if $compstatus == CS_END_RESULTS;
	 $restype = $dbh->{LastRestype};
      }
      next unless $dbh->ct_fetchable($restype);
      $ret = $dbh->as_describe($restype);
      while(($ret = $dbh->as_fetch) == CS_SUCCEED || $ret == CS_PENDING) {
	if($ret == CS_PENDING) {
	    $ret = $dbh->ct_poll(CS_NO_LIMIT, $foo, $compid, $compstatus);
	}
	my $d = $dbh->as_fetchrow;
	print "data: @$d\n";

	last if $compstatus == CS_END_DATA;
      }
   }

As you can see this snippet is quite a bit more complicated than the
corresponding synchronous code would be. In this case we've used the 
CS_NO_LIMIT parameter to ct_poll(), meaning that ct_poll() will block 
until data is available (which of course defeats the purpose of running
an async query, but serves to illustrate the API).

Note the use of $dbh->{LastRestype} to fetch the $restype value set
by ct_results() after that call completes.

Also, note the use of $dbh->as_describe($restype). This is a call that is 
normally done internally in ct_results(), but which needs to be called
separately in this case, and which allocates appropriate data structures
internally for the columns being returned.

The ct_fetch() call is replaced by as_fetch(), moving the actual data 
fetch to as_fetchrow().

If you define a completion callback then this will also be called - with 
the $dbh, $func (set to a symbolic value for the operation that completed, 
and $status (the return code for the operation).

For example, when ct_results() completes $func will be set to CT_RESULTS
and $status will be set to CS_SUCCEED, or CS_END_RESULTS if there are no more
results to be processed.

Most Sybase::CTlib calls can be called from within the completion callback,
if necessary.

To enable fully async mode, you need to have a completion callback 
registered, and you need to also enable async notifications, as well as
setting up a timeout for requests, via ct_config(CS_TIMEOUT).

There are two very simple scripts in the eg/ directory (ctpoll.pl and
ctasync.pl) which should illustrate the API somewhat.

=over 4

=item Completion Callbacks

A I<completion callback> is a perl subroutine that takes three arguments
(a database handle, and two integers ($func, $status). The callback
is enabled via the ct_callback() call:

    ct_callback(CS_COMPLETION_CB, \&my_completion_cb);

It is either invoked when ct_poll() is notified of a request completion,
or by the OpenClient API directly in full async mode.

It should return CS_SUCCEED, or CS_PENDING if you've initiated a new
async request from within the callback

=item $ret = $dbh->ct_con_props($action, $property, $value, $type)

You can set or retrieve connection properties with this call. In
particular you set async mode like this:

	$dbh->ct_con_props(CS_SET, CS_NETIO, CS_ASYNC_IO, CS_INT_TYPE);


=item $ret = $dbh->ct_poll($milliseconds, $conn, $compid, $compstatus)

Check for completion of an operation. $milliseconds determines how long
ct_poll should wait before timing out, where 0 means return immediately, 
and CS_NO_LIMIT means don't return until a pending operation has completed.

If the call is invoked as Sybase::CTlib->ct_poll() it will return the
first connection that has a completed operation in the $conn variable. 
The $compid value is a symbolic value identifying the type of operation 
that has completed, and $compstatus is the return value of that operation.

=item $ret = $dbh->as_describe($restype)

This needs to be called before fetching rows on an async or deferred IO
connection. This allocates the appropriate internal buffers for the
data columns returned in the query.

=item $ret = $dbh->as_fetch

Performs an async fetch - does not actually return any row data.

=item $ret = $dbh->as_fetchrow([$doAssoc])

Returns a row of data after as_fetch() is marked as completed. This call
returns a static array (or a static hash, if $doAssoc is set). So each call
to this routine B<overwrites> the data that you just fetched. If you need
to save the data you must make a copy of the array.

=back

=head2 EXAMPLES

    #!/usr/local/bin/perl

    use Sybase::CTlib;

    ct_callback(CS_CLIENTMSG_CB, \&msg_cb);
    ct_callback(CS_SERVERMSG_CB, "srv_cb");
    $uid = 'mpeppler'; $pwd = 'my-secret-password'; $srv = 'TROLL';

    $X = Sybase::CTlib->ct_connect($uid, $pwd, $srv);

    $X->ct_execute("select * from sysusers");

    while(($rc = $X->ct_results($restype)) == CS_SUCCEED) {
	next if($restype == CS_CMD_DONE || $restype == CS_CMD_FAIL ||
	        $restype == CS_CMD_SUCCEED);
	if(@names = $X->ct_col_names()) {
	     print "@names\n";
	}
	if(@types = $X->ct_col_types()) {
	     print "@types\n";
	}
	while(@dat = $X->ct_fetch) {
	     print "@dat\n";
	}
    }

    print "End of Result Set\n" if($rc == CS_END_RESULTS);
    print "Error!\n" if($rc == CS_FAIL);

    sub msg_cb {
        my($layer, $origin, $severity, $number, $msg, $osmsg, $dbh) = @_;

	printf STDERR "\nOpen Client Message: (In msg_cb)\n";
	printf STDERR "Message number: LAYER = (%ld) ORIGIN = (%ld) ",
    	       $layer, $origin;
	printf STDERR "SEVERITY = (%ld) NUMBER = (%ld)\n",
	       $severity, $number;
	printf STDERR "Message String: %s\n", $msg;
	if (defined($osmsg)) {
	    printf STDERR "Operating System Error: %s\n", $osmsg;
	}
	CS_SUCCEED;
    }

    sub srv_cb {
        my($dbh, $number, $severity, $state, $line, $server,
	   $proc, $msg) = @_;

    # If $dbh is defined, then you can set or check attributes
    # in the callback, which can be tested in the main body
    # of the code.

	printf STDERR "\nServer message: (In srv_cb)\n";
	printf STDERR "Message number: %ld, Severity %ld, ",
	       $number, $severity;
    	printf STDERR "State %ld, Line %ld\n", $state, $line;

	if (defined($server)) {
	    printf STDERR "Server '%s'\n", $server;
	}

	if (defined($proc)) {
	    printf STDERR " Procedure '%s'\n", $proc;
	}

	printf STDERR "Message String: %s\n", $msg;  CS_SUCCEED;
    }

=head2 ATTRIBUTES

The behavior of certain aspects of the Sybase::CTlib module can be
controlled via global or connection specific attributes. The global
attributes are stored in the %Sybase::CTlib::Att variable, and the
connection specific attributes are stored in the $dbh. To set a global
attribute, you would code

     $Sybase::CTlib::Att{'AttributeName'} = value;

and to set a connection specific attribute you would code

     $dbh->{"AttributeName'} = value;

B<NOTE:> Global attribute setting changes do not affect existing
connections, and changing an attribute inside a ct_fetch() does B<not>
change the behavior of the data retrieval during that ct_fetch()
loop.

The following attributes are currently defined:

=over 8

=item UseDateTime

If TRUE, then keep B<DATETIME> data retrieved via ct_fetch() in native
format instead of converting the data to a character string. Default:
FALSE.

=item UseMoney

If TRUE, keep B<MONEY> data retrieved via ct_fetch() in native format
instead of converting the data to character string. Default: FALSE.

=item UseNumeric

If TRUE, keep B<NUMERIC> or B<DECIMAL> data retrieved via ct_fetch()
in native format, instead of converting to a character string. Default: FALSE.

=item UseChar

This is a no-op. As of sybperl 2.16 B<NUMERIC>, B<DECIMAL> and B<MONEY> 
data retrieved via ct_fetch() is stored as character strings by default
to ensure no loss of precision.

=item UseBinary

If set then BINARY and IMAGE data items are returned in native form.
The default is to have BINARY and IMAGE data returned as hex strings.

=item UseBin0x

If set, and if UseBinary is FALSE, then BINARY data fetched from the
server will be converted to a hex string and prepended with 0x.

=item MaxRows

If non-0, limit the number of data rows that can be retrieve via
ct_sql(). Default: 0.

=item SkipEED

If set, then I<Extended Error Data> will I<not> be fetched in error
handlers. The default is to fetch extended error data, which includes
things like the index name that caused a duplicate insert error, for 
example.

=back

=head1 Using ct_get_data() and ct_send_data() to do raw TEXT processing

As of release 2.09_06 of B<sybperl> Sybase::CTlib includes the ability
to process B<TEXT> and B<IMAGE> datatypes using perl versions of 
ct_get_data() and ct_send_data(). Using these functions is a little
tricky, however.

B<NOTE:> This discussion applies equally to B<TEXT> and B<IMAGE> datatypes,
even if only one or the other is mentioned in the text.

=head2 Retrieving TEXT columns using ct_get_data()

First let's see how ct_get_data() is implemented to retrieve B<TEXT>
or B<IMAGE> data types in raw format, and (possibly) in retrieve large 
data items in smaller, more manageable pieces.

First, it is essential that the B<TEXT> columns appear
I<last> in the select statement (there can be several TEXT columns
in the statement, but they must appear I<after> any regular columns).

For example:

	select userID, userName, msgText
	from   messageTable

(where I<msgText> is a TEXT column) would work fine.

You issue the query in the normal way:

	$dbh->ct_execute("select userID, userName, msgText
			from messageTable where userID = 5");

You call ct_results() in the normal way, with the exception that you
pass the $textBind param as B<FALSE> to prevent ct_fetch() from 
returning the TEXT column.

If there are fetchable results, you call ct_fetch() to retrieve the 
normal data columns, and for each row you then call ct_get_data()
to retrieve the TEXT column(s).

For example:

	$dbh->ct_execute("select userID, userName, msgText
			from messageTable where userID = 5");
	while($dbh->ct_results($restype, 0) == CS_SUCCEED) {
	    next unless $dbh->ct_fetchable($restype);
	    while(@row = $dbh->ct_fetch) {
		($ret, $msg) = $dbh->ct_get_data(3);
	    }

=head2 Updating TEXT columns using ct_send_data()

This operation is a little more complicated. Essentially, you must
first select the column that you wish to update to obtain a valid 
I<text pointer> (via a call to ct_data_info(CS_GET)), then you 
initiate a CS_SEND_DATA_CMD command using ct_command(), you
set the new total length of the column via ct_data_info(CS_SET), 
send the data to the server via ct_send_data(), commit the operation
with ct_send(), and then process the results in the normal way
with ct_results() and ct_fetch().

For example, assuming the following table:

	create table blobtext(id numeric(5,0) identity,
			      data image)

We would update the I<data> column of a particular row like this:

	$dbh->ct_execute("select id, data from testdb..blobtest where id = 5");
	my $restype;
	while($dbh->ct_results($restype) == CS_SUCCEED) {
	    next unless($dbh->ct_fetchable($restype));
	    my @dat;
	    while(@dat = $dbh->ct_fetch) {
		$dbh->ct_data_info(CS_GET, 2);
	    }
	}

	my $data = "This is the new content that we want to place in
	            the 'data' column for the row";
	my @dat;
	$dbh->ct_command(CS_SEND_DATA_CMD, '', CS_UNUSED, CS_COLUMN_DATA);
	$dbh->ct_data_info(CS_SET, 2, {total_txtlen => length($data)});
	$dbh->ct_send_data($data, length($data));
	$dbh->ct_send;
	while($dbh->ct_results($restype) == CS_SUCCEED) {
	    next unless $dbh->ct_fetchable($restype);

	    while(@dat = $dbh->ct_fetch) {
		print "@dat\n";
	    }
	}

The last ct_fetch() will return one column - the new text pointer. At the
moment there is no way to make use of this text pointer directly.

You can also update TEXT fields on a set of rows by using a second
connection and performing the ct_send_data() in a nested loop:

	$dbh->ct_execute("select id, data from testdb..blobtest");
	my $restype;
	while($dbh->ct_results($restype) == CS_SUCCEED) {
	    next unless($dbh->ct_fetchable($restype));
	    my @dat;
	    while(@dat = $dbh->ct_fetch) {
		$dbh->ct_data_info(CS_GET, 2);

		# get the data to be updated, based on the 'id' column
		# presumably the get_data() function knows what to do :-)
		my $data = get_data($dat[0]);
		$dbh2->ct_command(CS_SEND_DATA_CMD, '', CS_UNUSED, CS_COLUMN_DATA);
		# copy the CS_IODESC struct from $dbh to $dbh2, and
		# set 'total_txtlen' to the correct value.
		$dbh2->ct_data_info(CS_SET, 2, {total_txtlen => length($data)}, $dbh);
		$dbh2->ct_send_data($data, length($data));
		$dbh2->ct_send;
		while($dbh2->ct_results($restype) == CS_SUCCEED) {
		    next unless $dbh2->ct_fetchable($restype);

		    while(@dat = $dbh2->ct_fetch) {
			print "@dat\n";
		    }
		}		
	    }
	}


=head1 Utility routines
        
=item Sybase::CTlib::debug($bitmask)

Turns the debugging trace on or off. The value of $bitmask determines
which features are going to be traced. The following trace bits are
currently recognized:

=over 4

=item * TRACE_CREATE

Trace all CTlib and/or DBlib object creations.

=item * TRACE_DESTROY

Trace all calls to DESTROY.

=item * TRACE_SQL

Traces all SQL language commands - (i.e. calls to dbcmd(), ct_execute() or
ct_command()). 

=item * TRACE_RESULTS

Traces calls to dbresults()/ct_results().

=item * TRACE_FETCH

Traces calls to dbnextrow()/ct_fetch(), and traces the values that are
pushed on the stack.

=item * TRACE_CUSROR

Trace calls to ct_cursor() (not available in Sybase::DBlib).

=item * TRACE_PARAMS

Trace calls to ct_param() (not implemented in Sybase::DBlib).

=item * TRACE_OVERLOAD

Trace all overloaded operations involving DateTime, Money or Numeric
datatypes.

=item * TRACE_CONVERT

Verbose tracing of calls to cs_convert().

=back

Two special trace flags are B<TRACE_NONE>, which turns off debug
tracing, and B<TRACE_ALL> which (you guessed it!) turns everything on.

The traces are pretty obscure, but they can be useful when trying to
find out what is I<really> going on inside the program.

For the B<TRACE_*> flags to be available in your scripts, you must
load the Sybase::??lib module with the following syntax:

     use Sybase::CTlib qw(:DEFAULT /TRACE/);

This tells the autoloading mechanism to import all the I<default>
symbols, plus all the I<trace> symbols.


=head1 Special handling of DATETIME, MONEY & NUMERIC/DECIMAL values

B<NOTE:> This feature is turned off by default for performance
reasons.  You can turn it on per datatype and B<dbh>, or via the
module attribute hash (%Sybase::CTlib::Att).

The Sybase::CTlib module includes special features
to handle B<DATETIME>, B<MONEY>, and B<NUMERIC/DECIMAL> (I<CTlib>
only) values in their native formats correctly. What this means is
that when you retrieve a date using ct_fetch() or dbnextrow() it is
not converted to a string, but kept in the internal format used by the
Sybase libraries. You can then manipulate this date as you see fit,
and in particular 'crack' the date into its components.

The same is true for B<MONEY> (and for I<CTlib> B<NUMERIC> values),
which otherwise are converted to floating point values, and hence are 
subject to loss of precision in certain situations. Here they are
stored as B<MONEY> values, and by using operator overloading we can
give you intuitive access to the cs_calc()/dbmnyxxx() routines.

This feature has been implemented by creating new classes in both
Sybase::DBlib and Sybase::CTlib:
B<Sybase::DBlib::DateTime>, B<Sybase::DBlib::Money>,
B<Sybase::CTlib::DateTime>, B<Sybase::CTlib::Money> and
B<Sybase::CTlib::Numeric> (hereafter referred to as B<DateTime>,
B<Money> and B<Numeric>). All the examples below use the I<CTlib>
module. The syntax is identical for the I<DBlib> module, except that
the B<Numeric> class does not exist.
 
To create data items of these types you call:

   $dbh = new Sybase::CTlib user, password;
   ...  # code deleted
   # Create a new DateTime object, and initialize to Jan 1, 1995:
   $date = $dbh->newdate('Jan 1 1995');

   # Create a new Money object
   $mny = $dbh->newmoney;	# Default value is 0

   # Create a new Numeric object
   $num = $dbh->newnumeric(11.111);

The B<DateTime> class defines the following methods:

=over 8

=item $date->str

Convert to string (calls cs_convert()/dbconvert()).

=item @arr = $date->crack

'Crack' the date into its components.

=item $date->cmp($date2)

Compare $date with $date2.

=item $date2 = $date->calc($days, $msecs)

Add or substract $days and $msecs from $date, and returns the new
date.

B<NOTE:> The minimal interval that Sybase understands is 1/300th of second,
so amounts of less than 3 $msecs will NOT be visible.

=item ($days, $msecs) = $date->diff($date2)

Compute the difference, in $days and $msecs between $date and $date2.

=item $val = $date->info($datepart)

Calls cs_dt_info to return the string representation for a
datepart. Valid dateparts are CS_MONTH, CS_SHORTMONTH and CS_DAYNAME.

B<NOTE:> Not implemented in I<DBlib>.

=item $time = $date->mktime

=item $time = $date->timelocal

=item $time = $date->timegm

Converts a Sybase B<DATETIME> value to a Unix B<time_t> value. The
B<mktime> and B<timelocal> methods assumes the date is stored in local
time, B<timegm> assumes GMT. The B<mktime> method uses the POSIX
module (note that unavailability of the POSIX module is not a fatal error).

=back
    
Both the B<str> and the B<cmp> methods will be called transparently
when they are needed, so that

    print "$date"

will print the date string correctly, and

    $date1 cmp $date2

will do a comparison of the two dates, not the two strings.

B<crack> executes cs_dt_crack()/dbdatecrack() on the date value, and
returns the following list:

    ($year, $month, $month_day, $year_day, $week_day, $hour,
	$minute, $second, $millisecond, $time_zone) = $date->crack;

Compare this with the value returned by the standard Perl function
localtime():

    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                   localtime(time);

In addition, the values returned for the week_day can change depending
on the locale that has been set.

Please see the discussion on cs_dt_crack() or dbdatecrack() in the
I<Open Client / Open Server Common Libraries Reference Manual>, chap. 2.

The B<Money> and B<Numeric> classes define these methods:

=over 8

=item $mny->str

Convert to string (calls cs_convert()/dbconvert()).

=item $mny->num

Convert to a floating point number (calls cs_convert()/dbconvert()).

=item $mny->cmp($mny2)

Compare two Money or Numeric values.

=item $mny->set($number)

Set the value of $mny to $number.

=item $mny->calc($mny2, $op)

Perform the calculation specified by $op on $mny and $mny2. $op is one
of '+', '-', '*' or '/'.

=back

As with the B<DateTime> class, the B<str> and B<cmp> methods will be
called automatically for you when required. In addition, you can
perform normal arithmetic on B<Money> or B<Numeric> datatypes without
calling the B<calc> method explicitly.

B<CAVEAT!> You must call the B<set> method to assign a value to a
B<Money/Numeric> data item. If you use

      $mny = 4.05

then $mny will lose its special B<Money> or B<Numeric> behavior and
become a normal Perl data item.

When a new B<Numeric> data item is created, the I<SCALE> and
I<PRECISION> values are determined by the initialization. If the data
item is created as part of a I<SELECT> statement, then the I<SCALE>
and I<PRECISION> values will be those of the retrieved item. If the
item is created via the B<newnumeric> method (either explicitly or
implicitly) the I<SCALE> and I<PRECISION> are deduced from the
initializing value. For example, $num = $dbh->newnumeric(11.111) will
produce an item with a I<SCALE> of 3 and a I<PRECISION> of 5. This is
totally transparent to the user.

=head1 BUGS

There is a (approximately) 300 byte memory leak in the newdbh() function
in Sybase/CTlib.xs. This function is called when a 
new connection is created.
I have not been able to locate the real cause of the leak so far. Patches
that appear to solve the problem are welcome!

I have a simple bug tracking system at http://www.peppler.org/cgi-bin/bug.cgi .
You can use it to check for known bugs, or to submit
new ones.

You can also look for new versions/patches for sybperl in 
http://www.peppler.org/downloads.

=head1 ACKNOWLEDGMENTS

Larry Wall - for Perl :-)

Tim Bunce & Andreas Koenig - for all the work on MakeMaker

=head1 AUTHORS

Michael Peppler E<lt>F<mpeppler@peppler.org>E<gt>

Dave Bowen & Amy Lin for help with Sybase::CTlib.

W. Phillip Moore E<lt>F<Phil.Moore@msdw.com>E<gt> for the nsql() method.

Numerous folks have contributed ideas and bug fixes for which they
have my undying thanks :-) 

The sybperl mailing list E<lt>F<sybperl-l@peppler.org>E<gt> is the
best place to ask questions.

=cut
