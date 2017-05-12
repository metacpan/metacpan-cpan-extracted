# -*-Perl-*-
# $Id: DBlib.pm,v 1.49 2004/08/03 14:14:00 mpeppler Exp $
#
# From:
# 	@(#)DBlib.pm	1.35	03/26/99

# Copyright (c) 1991-1999
#   Michael Peppler
#
#   You may copy this under the terms of the GNU General Public License,
#   or the Artistic License, copies of which should have accompanied
#   your Perl kit.

require 5.002;

use strict;

package Sybase::DBlib::_attribs;

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
    carp "Can't delete or clear attributes from a Sybase::DBlib handle.\n";
}

sub DELETE{ &readonly }
sub CLEAR { &readonly }


package Sybase::DBlib::Att;

use Carp;

sub TIEHASH {
    bless {
	UseDateTime => 0,
	UseMoney => 0,
#	   UseNumeric => 0,      # I don't think this can work with DBlib
	MaxRows => 0,
	dbKeepNumeric => 1,
	dbNullIsUndef => 1,
	dbBin0x => 0,
       }
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
    croak("'$_[1]' is not a valid Sybase::DBlib attribute") if(!exists($_[0]->{$_[1]}));
    $_[0]->{$_[1]} = $_[2];
}

sub readonly { croak "\%Sybase::DBlib::Att is read-only\n" }

sub DELETE{ &readonly }
sub CLEAR { &readonly }

package Sybase::DBlib::DateTime;

# Sybase DATETIME handling.

# For converting to Unix time:

require Time::Local;


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

    @data = $self->crack;

    $ret = Time::Local::timelocal($data[7], $data[6], $data[5], $data[2],
				  $data[1], $data[0]-1900);
}

sub timegm {
    my $self = shift;
    my (@data, $ret);

    @data = $self->crack;

    $ret = Time::Local::timegm($data[7], $data[6], $data[5], $data[2],
			       $data[1], $data[0]-1900);
}

package Sybase::DBlib::Money;

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

package Sybase::DBlib;

require Exporter;
use AutoLoader;
require DynaLoader;
use Carp;

#__SYBASE_START

#__SYBASE_END

use subs qw(sql SUCCEED FAIL NO_MORE_RESULTS SYBESMSG INT_CANCEL);

use vars qw(%Att @ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use vars qw($DB_ERROR $nsql_strip_whitespace $nsql_deadlock_retrycount
	   $nsql_deadlock_retrysleep $nsql_deadlock_verbose);

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw( dbmsghandle dberrhandle dbrecftos dbexit
	     BCP_SETL bcp_getl
	     dbsetlogintime dbsettime DBGETTIME
	     DBSETLNATLANG DBSETLCHARSET dbversion
	     DBSETLHOST DBSETLENCRYPT
	     dbsetifile dbrpwclr dbrpwset
	     DBLIBVS  FAIL 
	     INT_CANCEL INT_CONTINUE INT_EXIT INT_TIMEOUT
	     MORE_ROWS NO_MORE_RESULTS NO_MORE_ROWS NULL REG_ROW
	     STDEXIT SUCCEED SYBESMSG 
	     BCPBATCH BCPERRFILE BCPFIRST BCPLAST BCPMAXERRS	BCPNAMELEN
	     DBBOTH DBSINGLE DB_IN DB_OUT
	     TRUE FALSE
	     DBARITHABORT DBARITHIGNORE DBBUFFER DBBUFSIZE DBDATEFORMAT
	     DBNATLANG DBNOAUTOFREE DBNOCOUNT DBNOEXEC DBNUMOPTIONS
	     DBOFFSET DBROWCOUNT DBSHOWPLAN DBSTAT DBSTORPROCID
	     DBTEXTLIMIT DBTEXTSIZE DBTXPLEN DBTXTSLEN
	     NOSUCHOPTION
	     SYBBINARY SYBBIT SYBCHAR SYBDATETIME SYBDATETIME4
	     SYBFLT8 SYBIMAGE SYBINT1 SYBINT2 SYBINT4 SYBMONEY
	     SYBMONEY4 SYBREAL SYBTEXT SYBVARBINARY SYBVARCHAR
	     DBRPCRETURN DBRPCNORETURN DBRPCRECOMPILE
	      DBRESULT DBNOTIFICATION DBINTERRUPT DBTIMEOUT
	      $DB_ERROR
	     );

@EXPORT_OK = qw(ERREXIT EXCEPTION EXCLIPBOARD EXCOMM EXCONSISTENCY EXCONVERSION
	EXDBLIB EXECDONE EXFATAL EXFORMS EXINFO EXLOOKUP EXNONFATAL EXPROGRAM
	EXRESOURCE EXSCREENIO EXSERVER EXSIGNAL	EXTIME EXUSER
	SYBEAAMT SYBEABMT SYBEABNC SYBEABNP SYBEABNV SYBEACNV SYBEADST SYBEAICF
	SYBEALTT SYBEAOLF SYBEAPCT SYBEAPUT SYBEARDI SYBEARDL SYBEASEC SYBEASNL
	SYBEASTF SYBEASTL SYBEASUL SYBEAUTN SYBEBADPK SYBEBBCI SYBEBCBC
	SYBEBCFO SYBEBCIS SYBEBCIT SYBEBCNL SYBEBCNN SYBEBCNT SYBEBCOR SYBEBCPB
	SYBEBCPI SYBEBCPN SYBEBCRE SYBEBCRO SYBEBCSA SYBEBCSI SYBEBCUC SYBEBCUO
	SYBEBCVH SYBEBCWE SYBEBDIO SYBEBEOF SYBEBIHC SYBEBIVI SYBEBNCR SYBEBPKS
	SYBEBRFF SYBEBTMT SYBEBTOK SYBEBTYP SYBEBUCE SYBEBUCF SYBEBUDF SYBEBUFF
	SYBEBUFL SYBEBUOE SYBEBUOF SYBEBWEF SYBEBWFF SYBECDNS SYBECLOS
	SYBECLOSEIN SYBECLPR SYBECNOR SYBECNOV SYBECOFL SYBECONN SYBECRNC
	SYBECSYN SYBECUFL SYBECWLL SYBEDBPS SYBEDDNE SYBEDIVZ SYBEDNTI SYBEDPOR
	SYBEDVOR SYBEECAN SYBEECRT SYBEEINI SYBEEQVA SYBEESSL SYBEETD SYBEEUNR
	SYBEEVOP SYBEEVST SYBEFCON SYBEFGTL SYBEFMODE SYBEFSHD SYBEGENOS
	SYBEICN SYBEIDCL SYBEIFCL SYBEIFNB SYBEIICL SYBEIMCL SYBEINLN SYBEINTF
	SYBEIPV SYBEISOI SYBEITIM SYBEKBCI SYBEKBCO SYBEMEM SYBEMOV SYBEMPLL
	SYBEMVOR SYBENBUF SYBENBVP SYBENDC SYBENDTP SYBENEHA SYBENHAN SYBENLNL
	SYBENMOB SYBENOEV SYBENOTI SYBENPRM SYBENSIP SYBENTLL SYBENTST SYBENTTN
	SYBENULL SYBENULP SYBENUM SYBENXID SYBEOOB SYBEOPIN SYBEOPNA SYBEOPTNO
	SYBEOREN SYBEORPF SYBEOSSL SYBEPAGE SYBEPOLL SYBEPRTF SYBEPWD SYBERDCN
	SYBERDNR SYBEREAD SYBERFILE SYBERPCS SYBERPIL SYBERPNA SYBERPND
	SYBERPUL SYBERTCC SYBERTSC SYBERTYPE SYBERXID SYBESEFA SYBESEOF
	SYBESFOV SYBESLCT SYBESOCK SYBESPID SYBESYNC SYBETEXS
	SYBETIME SYBETMCF SYBETMTD SYBETPAR SYBETPTN SYBETRAC SYBETRAN
	SYBETRAS SYBETRSN SYBETSIT SYBETTS SYBETYPE SYBEUACS SYBEUAVE SYBEUCPT
	SYBEUCRR SYBEUDTY SYBEUFDS SYBEUFDT SYBEUHST SYBEUNAM SYBEUNOP SYBEUNT
	SYBEURCI SYBEUREI SYBEUREM SYBEURES SYBEURMI SYBEUSCT SYBEUTDS SYBEUVBF
	SYBEUVDT SYBEVDPT SYBEVMS SYBEVOIDRET SYBEWAID SYBEWRIT SYBEXOCI
	SYBEXTDN SYBEXTN SYBEXTSN SYBEZTXT
		TRACE_NONE TRACE_ALL TRACE_CREATE TRACE_DESTROY TRACE_SQL
    TRACE_RESULTS TRACE_FETCH TRACE_CURSOR TRACE_PARAMS	TRACE_OVERLOAD
		TRACE_CONVERT
);

tie %Att, 'Sybase::DBlib::Att';

sub AUTOLOAD {
    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Sybase::DBlib macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Sybase::DBlib;

# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.




sub dbsucceed
{
    my($self) = shift;
    my($abort) = shift;
    my($ret);
    
    if(($ret = $self->dbsqlexec) == &SUCCEED)
    {
	$ret = $self->dbresults;
    }

    croak "dbsucceed failed\n" if($abort && $ret == &FAIL);

    $ret;
}

sub dbclose
{
    undef($_[0]);
}


sub sql				# Submitted by Gisle Aas
{
    my($db, $cmd, $sub, $flag) = @_;
    my @res;
    my $data;

    if($db->{'MaxRows'}) {
	$db->dbsetopt(&DBROWCOUNT, "$db->{'MaxRows'}");
    }

    $db->dbcmd($cmd);
    $db->dbsqlexec || return undef; # The SQL command failed

    $flag = 0 unless $flag;
    
    while(my $ret = $db->dbresults != &NO_MORE_RESULTS) {
	if($ret == FAIL) {
	    $db->dbcancel();
	    return undef;
	}
        while ($data = $db->dbnextrow($flag, 1)) {
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
	$db->dbsetopt(&DBROWCOUNT, "0");
    }
    
    wantarray ? @res : \@res;  # return the result array
}

sub r_sql {
    my($db, $cmd, $sub) = @_;

    $db->dbcmd($cmd);
    $db->dbsqlexec || return undef; # The SQL command failed

    my @res;
    my @data;
    while($db->dbresults != &NO_MORE_RESULTS) {
        while (@data = $db->dbnextrow) {
            if (defined $sub) {
                &$sub(@data);
            } else {
                push(@res, [@data]);
            }
        }
    }
    @res;  # return the result array
}


#
# Enhanced sql routine.
# 

sub DB_ERROR { return $DB_ERROR; }
 

sub nsql {

    my ($db,$sql,$type,$callback) = @_;
    my (@res,@data,%data);
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
	
	return unless $db->dbcmd($sql);
	
	unless ( $db->dbsqlexec ) {
	    if ( $nsql_deadlock_retrycount && $DB_ERROR =~ /Message: 1205\b/m ) {
		if ( $retrycount < 0 || $retrycount-- ) {
		    carp "SQL deadlock encountered.  Retrying...\n" if $retryverbose;
		    undef $DB_ERROR;
		    sleep($retrysleep);
		    redo DEADLOCK;
		}
		else {
		    carp "SQL deadlock retry failed $nsql_deadlock_retrycount times.  Aborting.\n"
		      if $retryverbose;
		    last DEADLOCK;
		}
	    }
	    
	    last DEADLOCK;
	    
	}
	
	while ( $db->dbresults != $db->NO_MORE_RESULTS ) {
	    
	    if ( $nsql_deadlock_retrycount && $DB_ERROR =~ /Message: 1205\b/m ) {
		if ( $retrycount < 0 || $retrycount-- ) {
		    carp "SQL deadlock encountered.  Retrying...\n" if $retryverbose;
		    undef $DB_ERROR;
		    @res = ();
		    sleep($retrysleep);
		    redo DEADLOCK;
		}
		else {
		    carp "SQL deadlock retry failed $nsql_deadlock_retrycount times.  Aborting.\n"
		      if $retryverbose;
		    last DEADLOCK;
		}
	    }
	    
	    if ( $type eq "HASH" ) {
		while ( %data = $db->dbnextrow(1) ) {
		    grep($data{$_} =~ s/\s+$//g,keys %data) if $nsql_strip_whitespace;
		    if ( ref $callback eq "CODE" ) {
			unless ( $callback->(%data) ) {
			    $db->dbcancel();
			    $DB_ERROR = "User-defined callback subroutine failed\n";
			    return;
			} 
		    }
		    else {
			push(@res,{%data});
		    }
		}
	    }
	    elsif ( $type eq "ARRAY" ) {
		while ( @data = $db->dbnextrow ) {
		    grep(s/\s+$//g,@data) if $nsql_strip_whitespace;
		    if ( ref $callback eq "CODE" ) {
			unless ( $callback->(@data) ) {
			    $db->dbcancel();
			    $DB_ERROR = "User-defined callback subroutine failed\n";
			    return;
			} 
		    }
		    else {
			push(@res,( $#data == 0 ? @data : [@data] ));
		    }
		}
	    }
	    else {
		# If you ask for nothing, you get nothing.  But suck out
		# the data just in case.
		while ( @data = $db->dbnextrow ) { 1; }
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

sub nsql_error_handler {
    my ($db, $severity, $error, $os_error, $error_msg, $os_error_msg) = @_;
    # Check the error code to see if we should report this.

    if ( $error != SYBESMSG ) {
      $DB_ERROR = "Sybase error: $error_msg\n";
      $DB_ERROR .= "OS Error: $os_error_msg\n" if defined $os_error_msg;
    }

    INT_CANCEL;
}

sub nsql_message_handler {
    my ($db, $message, $state, $severity, $text, $server, $procedure, $line) = @_;

    if ( $severity > 0 ) {
      $DB_ERROR = "Message: $message\n";
      $DB_ERROR .= "Severity: $severity\n";
      $DB_ERROR .= "State: $state\n";
      $DB_ERROR .= "Server: $server\n" if defined $server;
      $DB_ERROR .= "Procedure: $procedure\n" if defined $procedure;
      $DB_ERROR .= "Line: $line\n" if defined $line;
      $DB_ERROR .= "Text: $text\n";

      return unless ref $db;
      
      my ($lineno) = 1;
      my $row;
      foreach $row ( split(/\n/,$db->dbstrcpy) ) {
          $DB_ERROR .= sprintf ("%5d", $lineno ++) . "> $row\n";
      }
    }
    
    0;
}


1;

__END__


=head1 NAME

Sybase::DBlib - Sybase DB-Library API

=head1 SYNOPSIS

    use Sybase::DBlib;

    $dbh = Sybase::DBlib->new('user', 'pwd', 'server');
    $dbh->dbcmd("select * from master..sysprocesses");
    $dbh->dbsqlexec;
    while($dbh->dbresults != NO_MORE_RESULTS) {
	while(@data = $dbh->dbnextrow) {
	    print "@data\n";
	}
    }

=head1 DESCRIPTION

Sybase::DBlib implements a subset of the Sybase DB-Library API. In
general the perl version of the DB-Library calls use the same syntax as 
the C language version. However, in some cases the syntax (and sometimes,
meaning) of some calls has been modified in order to make life easier
for the perl programmer. It is a good idea to have the Sybase
documentation for DB-Library handy when writing Sybase::DBlib programs.
The documentation is available at http://sybooks.sybase.com.

B<List of API calls>

B<Standard Routines:>

=over 4

=item $dbh = new Sybase::DBlib [$user [, $pwd [, $server [, $appname [, {additional attributes}]]]]]

=item $dbh = Sybase::DBlib->dblogin([$user [, $pwd [, $server [, $appname, [{additional attributes}] ]]]])

Initiates a connection to a Sybase dataserver, using the supplied
user, password, server and application name information. Uses the
default values (see DBSETLUSER(), DBSETLPWD(), etc. in the Sybase
DB-Library documentation) if the parameters are omitted.

The two forms of the call behave identically.

This call can be used multiple times if connecting to multiple servers
with different username/password combinations is required, for
example.

The B<additional attributes> parameter allows you to define
application specific attributes that you wish to associate with the $dbh.

B<NOTE:> the connection to the database server that is associated with
the $dbh that is created is automatically closed when the $dbh goes
out of scope.

=item $dbh = Sybase::DBlib->dbopen([$server [, $appname, [{attributes}] ]])

Open an additional connection, using the current LOGINREC information.

=item $status = $dbh->dbuse($database)

Executes "use database $database" for the connection $dbh.

=item $status = $dbh->dbcmd($sql_cmd)

Appends the string $sql_cmd to the current command buffer of this connection.

=item $status = $dbh->dbsqlexec

Sends the content of the current command buffer to the dataserver for
execution. See the DB-Library documentation for a discussion of return
values.

=item $status = $dbh->dbresults

Retrieves result information from the dataserver after having executed
dbsqlexec().

=item $status = $dbh->dbsqlsend

Send the command batch to the server, but do not wait for the server to return
any results. Should be followed by calls to dbpoll() and dbsqlok(). See the 
Sybase docs for further details.

=item $status = $dbh->dbsqlok

Wait for results from the server and verify the correctness of the 
instructions the server is responding to. Mainly for use with dbmoretext() 
in Sybase::DBlib. See also the Sybase documentation for details.

=item ($dbproc, $reason) = Sybase::DBlib->dbpoll($millisecs)

=item ($dbproc, $reason) = $dbh->dbpoll($millisecs)

B<Note>: The dbpoll() syntax has been changed since sybperl 2.09_05.

Poll the server to see if any connection has results pending. Used in 
conjunction with dbsqlsend() and dbsqlok() to perform asynchronous queries.
dbpoll() will wait up to $millisecs milliseconds and poll any open DBPROCESS
for results (if called as Sybase::DBlib->dbpoll()) or poll the specified 
DBPROCESS (if called as $dbh->dbpoll()). If it finds a DBPROCESS that is
ready it returns it, along with the reason why it's ready. If dbpoll()
times out, or if an interrupt occurs, $dbproc will be undefined, and $reason 
will be either DBTIMEOUT or DBINTERRUPT. If $millisecs is 0 then dbpoll()
returns immediately. If $millisecs is -1 then it will not return until
either results are pending or a system interrupt has occurred. Please see
the Sybase documentation for further details.

Here is an example of using dbsqlsend(), dbpoll() and dbsqlok():

  $dbh->dbcmd("exec big_hairy_query_proc");
  $dbh->dbsqlsend;
  # here you can go do something else...
  # now - find out if some results are waiting
  ($dbh2, $reason) = $dbh->dbpoll(100);
  if($dbh2 && $reason == DBRESULT) {   # yes! - there's data on the pipe
     $dbh2->dbsqlok;
     while($dbh2->dbresults != NO_MORE_RESULTS) {
        while(@dat = $dbh2->dbnextrow) {
           ....
        }
     }
  }


=item $status = $dbh->dbcancel

Cancels the current command batch.

=item $status = $dbh->dbcanquery

Cancels the current query within the currently executing command batch.

=item $dbh->dbfreebuf

Free the command buffer (required only in special cases - if you don't
know what this is you probably don't need it :-)

=item $dbh->dbclose

Force the closing of a connection. Note that connections are
automatically closed when the $dbh goes out of scope.

=item $dbh->DBDEAD

Returns TRUE if the B<DBPROCESS> has been marked I<DEAD> by I<DB-Library>.

=item $status = $dbh->DBCURCMD

Returns the number of the currently executing command in the command
batch. The first command is number 1.

=item $status = $dbh->DBMORECMDS

Returns TRUE if there are additional commands to be executed in the
current command batch.

=item $status = $dbh->DBCMDROW

Returns SUCCEED if the current command can return rows.

=item $status = $dbh->DBROWS

Returns SUCCEED if the current command did return rows.

=item $status = $dbh->DBCOUNT

Returns the number of rows that the current command affected.

=item $row_num = $dbh->DBCURROW

Returns the number (counting from 1) of the currently retrieved row in
the current result set.

=item $spid = $dbh->dbspid

Returns the SPID (server process ID) of the current connection to the Sybase
server.

=item $status = $dbh->dbhasretstat

Did the last executed stored procedure return a status value?
dbhasretstats must only be called after dbresults returns
NO_MORE_RESULTS, i.e. after all the select, insert, update operations of
the stored procedure have been processed.

=item $status = $dbh->dbretstatus

Retrieve the return status of a stored procedure. As with
dbhasretstat, call this function after all the result sets of the
stored procedure have been processed.

=item $status = $dbh->dbnumcols

How many columns are in the current result set.

=item $status = $dbh->dbcoltype($colid)

What is the column type of column $colid in the current result
set. 

=item $type = $dbh->dbprtype($colid)

Returns the column type as a printable string.

=item $status = $dbh->dbcollen($colid)

What is the length (in bytes) of column $colid in the current result set.

=item $string = $dbh->dbcolname($colid)

What is the name of column $colid in the current result set.

=item @dat = $dbh->dbnextrow([$doAssoc [, $wantRef]])

Retrieve one row. dbnextrow() returns a list of scalars, one for each
column value. If $doAssoc is non-0, then dbnextrow() returns a hash (aka
associative array) with column name/value pairs. This relieves the
programmer from having to call dbbind() or dbdata(). 

If $wantRef is non-0, then dbnextrow() returns a B<reference> to
a hash or an array. This reference I<points> to a static array (or hash)
so if you wish to store the returned rows in an array, you must
B<copy> the array/hash:

  while($d = $dbh->dbnextrow(0, 1)) {
     push(@rows, [@$d]);
  }

The return value of the C version of dbnextrow() can be accessed via the 
Perl DBPROCESS attribute field, as in:

   @arr = $dbh->dbnextrow;		# read results
   if($dbh->{DBstatus} != REG_ROW) {
     take some appropriate action...
   }

When the results row is a COMPUTE row, the B<ComputeID> field of the
DBPROCESS is set:

   @arr = $dbh->dbnextrow;		# read results
   if($dbh->{ComputeID} != 0) {	# it's a 'compute by' row
     take some appropriate action...
   }

dbnextrow() can also return a hash keyed on the column name:

   $dbh->dbcmd("select Name=name, Id = id from test_table");
   $dbh->dbsqlexec; $dbh->dbresults;

   while(%arr = $dbh->dbnextrow(1)) {
      print "$arr{Name} : $arr{Id}\n";
   }


=item @dat = $dbh->dbretdata([$doAssoc])

Retrieve the value of the parameters marked as 'OUTPUT' in a stored
procedure. If $doAssoc is non-0, then retrieve the data as an
associative array with parameter name/value pairs.

=item $bylist = $dbh->dbbylist($computeID)

Returns the I<by list> for a I<compute by> clause. $bylist is a reference 
to an array of I<colids>. You can use $dbh->dbcolname() to get the column 
names.

    $dbh->dbcmd("select * from sysusers order by uid compute count(uid) by uid");
    $dbh->dbsqlexec;
    $dbh->dbresults;
    my @dat;
    while(@dat = $dbh->dbnextrow) {
        if($dbh->{ComputeID} != 0) {
            my $bylist = $dbh->dbbylist($dbh->{ComputeID});
            print "bylist = @$bylist\n";
        }
        print "@dat\n";
    }


=item %hash = $dbh->dbcomputeinfo($computeID, $column)

Returns a hash with the B<colid>, B<op>, B<len>, B<type> and B<utype>
of the I<compute by> column. You can call this subroutine to get the 
information returned by DB-Library's I<dbalt*()> calls. The $column is the 
column number in the current I<compute by> row (starting at 1) and
the $computeID is best retrieved from I<$dbh->{ComputeID}>. Please
see the documentation of the I<dbalt*()> calls in Sybase's DB-Library
manual.

=item $string = $dbh->dbstrcpy

Retrieve the contents of the command buffer.

=item $ret = $dbh->dbsetopt($opt [, $c_val [, $i_val]])

Sets option $opt with optional character parameter $c_val and optional
integer parameter $i_val. $opt is one of the option values defined in
the Sybase DB-Library manual (f.eg. DBSHOWPLAN, DBTEXTSIZE). For
example, to set SHOWPLAN on, you would use

    $dbh->dbsetopt(DBSHOWPLAN);

See also dbclropt() and dbisopt() below.

=item $ret = $dbh->dbclropt($opt [, $c_val])

Clears the option $opt, previously set using dbsetopt().

=item $ret = $dbh->dbisopt($opt [, $c_val])

Returns TRUE if the option $opt is set.

=item $string = $dbh->dbsafestr($string [,$quote_char])

Convert $string to a 'safer' version by inserting single or double
quotes where appropriate, so that it can be passed to the dataserver
without syntax errors. 

The second argument to dbsafestr() (normally B<DBSINGLE>, B<DBDOUBLE> or
B<DBBOTH>) has been replaced with a literal ' or " (meaning B<DBSINGLE> or
B<DBDOUBLE>, respectively). Omitting this argument means B<DBBOTH>.

=item $packet_size = $dbh->dbgetpacket

Returns the TDS packet size currently in use for this $dbh.

=back

=head2 TEXT/IMAGE Routines

=over 4

=item $status = $dbh->dbwritetext($colname, $dbh_2, $colnum, $text [, $log])

Insert or update data in a TEXT or IMAGE column. The usage is a bit
different from that of the C version:

The calling sequence is a little different from the C version, and
logging is B<off> by default:

B<$dbh_2> and B<$colnum> are the B<DBPROCESS> and column number of a
currently active query. Example:

   $dbh_2->dbcmd('select the_text, t_index from text_table where t_index = 5');
   $dbh_2->dbsqlexec; $dbh_2->dbresults;
   @data = $dbh_2->dbnextrow;

   $d->dbwritetext ("text_table.the_text", $dbh_2, 1,
	"This is text which was added with Sybperl", TRUE);

=item $status = $dbh->dbpreptext($colname, $dbh_2, $colnum, $size [, $log])

Prepare to insert or update text with dbmoretext().

The calling sequence is a little different from the C version, and
logging is B<off> by default:

B<$dbh_2> and B<$colnum> are the B<DBPROCESS> and column number of a
currently active query. Example:

   $dbh_2->dbcmd('select the_text, t_index from text_table where t_index = 5');
   $dbh_2->dbsqlexec; $dbh_2->dbresults;
   @data = $dbh_2->dbnextrow;

   $size = length($data1) + length($data2);
   $d->dbpreptext ("text_table.the_text", $dbh_2, 1, $size, TRUE);
   $dbh->dbsqlok;
   $dbh->dbresults;
   $dbh->dbmoretext(length($data1), $data1);
   $dbh->dbmoretext(length($data2), $data2);

   $dbh->dbsqlok;
   $dbh->dbresults;

=item $status = $dbh->dbmoretext($size, $data)

Sends a chunk of TEXT/IMAGE data to the server. See the example above.

=item $status = $dbh->dbreadtext($buf, $size)

Read a TEXT/IMAGE data item in $size chunks.

Example:

    $dbh->dbcmd("select data from text_test where id=1");
    $dbh->dbsqlexec;
    while($dbh->dbresults != NO_MORE_RESULTS) {
        my $bytes;
        my $buf = '';
        while(($bytes = $dbh->dbreadtext($buf, 512)) != NO_MORE_ROWS) {
	    if($bytes == -1) {
	        die "Error!";
            } elsif ($bytes == 0) {
                print "End of row\n";
            } else {
                print "$buf";
            }
        }
    }

=back

=head2 BCP Routines

See also the B<Sybase::BCP> module.

=over 4

=item BCP_SETL($state)

This is an exported routine (i.e., it can be called without a $dbh
handle) which sets the BCP IN flag to TRUE/FALSE.

It is necessary to call BCP_SETL(TRUE) before opening the
connection with which one wants to run a BCP IN operation.

=item $state = bcp_getl

Retrieve the current BCP flag status.

=item $status = $dbh->bcp_init($table, $hfile, $errfile, $direction)

Initialize BCP library. $direction can be B<DB_OUT> or B<DB_IN>

=item $status = $dbh->bcp_meminit($numcols)

This is a utility function that does not exist in the normal BCP
API. Its use is to initialize some internal variables before starting
a BCP operation from program variables into a table. This call avoids
setting up translation 
information for each of the columns of the table being updated,
obviating the use of the bcp_colfmt call.

See EXAMPLES, below.

=item $status = $dbh->bcp_sendrow(LIST)

=item $status = $dbh->bcp_sendrow(ARRAY_REF)

Sends the data in LIST to the server. The LIST is assumed to contain
one element for each column being updated. To send a NULL value set
the appropriate element to the Perl B<undef> value.

In the second form you pass an array reference instead of passing the
LIST, which makes processing a little bit faster on wide tables.

=item $rows = $dbh->bcp_batch

Commit rows to the database. You usually use it like this:

       while(<IN>) {
           chop;
	   @data = split(/\|/);
	   $d->bcp_sendrow(\@data);    # Pass the array reference

	   # Commit data every 100 rows.
	   if((++$count % 100) == 0) {
		   $d->bcp_batch;
	   }
	}


=item $status = $dbh->bcp_done

=item $status = $dbh->bcp_control($field, $value)

=item $status = $dbh->bcp_columns($colcount)

=item $status = $dbh->bcp_colfmt($host_col, $host_type, $host_prefixlen, $host_collen, $host_term, $host_termlen, $table_col [, $precision, $scale])

If you have DB-Library for System 10 or higher, then you can pass the
additional $precision and $scale parameters, and have sybperl call
bcp_colfmt_ps() instead of bcp_colfmt().

=item $status = $dbh->bcp_collen($varlen, $table_column)

=item $status = $dbh->bcp_exec

=item $status = $dbh->bcp_readfmt($filename)

=item $status = $dbh->bcp_writefmt($filename)

Please see the DB-Library documentation for these calls.

=back

=head2 DBMONEY Routines

B<NOTE:> In this version it is possible to avoid calling the routines
below and still get B<DBMONEY> calculations done with the correct
precision. See the B<Sybase::DBlib::Money> discussion below.

=over 4

=item ($status, $sum) = $dbh->dbmny4add($m1, $m2)

=item  $status = $dbh->dbmny4cmp($m1, $m2)

=item ($status, $quotient) = $dbh->dbmny4divide($m1, $m2)

=item ($status, $dest) = $dbh->dbmny4minus($source)

=item ($status, $product) = $dbh->dbmny4mul($m1, $m2)

=item ($status, $difference) = $dbh->dbmny4sub($m1, $m2)

=item ($status, $ret) = $dbh->dbmny4zero

=item ($status, $sum) = $dbh->dbmnyadd($m1, $m2)

=item $status = $dbh->dbmnycmp($m1, $m2)

=item ($status, $ret) = $dbh->dbmnydec($m1)

=item ($status, $quotient) = $dbh->dbmnydivide($m1, $m2)

=item ($status, $ret, $remainder) = $dbh->dbmnydown($m1, $divisor)

=item ($status, $ret) = $dbh->dbmnyinc($m1)

=item ($status, $ret, $remain) = $dbh->dbmnyinit($m1, $trim)

=item ($status, $ret) = $dbh->dbmnymaxneg

=item ($status, $ret) = $dbh->dbmnymaxpos

=item ($status, $dest) = $dbh->dbmnyminus($source)

=item ($status, $product) = $dbh->dbmnymul($m1, $m2)

=item ($status, $m1, $digits, $remain) = $dbh->dbmnyndigit($m1)

=item ($status, $ret) = $dbh->dbmnyscale($m1, $multiplier, $addend)

=item ($status, $difference) = $dbh->dbmnysub($m1, $m2)

=item ($status, $ret) = $dbh->dbmnyzero

All of these routines correspond to their DB-Library counterpart, with
the following exception:

The routines which in the C version take pointers to arguments
(in order to return values) return these values in a list instead:

   status = dbmnyadd(dbproc, m1, m2, &result) becomes
   ($status, $result) = $dbproc->dbmnyadd($m1, $m2)

=back

=head2 RPC Routines

B<NOTE:> Check out eg/rpc-example.pl for an example on how to use
these calls.

=over 4

=item $dbh->dbrpcinit($rpcname, $option)

Initialize an RPC call to the remote procedure $rpcname. See the
DB-Library manual for valid values for $option.

=item $dbh->dbrpcparam($parname, $status, $type, $maxlen, $datalen, $value)

Add a parameter to an RPC call initiated with dbrpcinit(). Please see
the DB-Library manual page for details & values for the parameters.

B<NOTE:> All floating point types (MONEY, FLOAT, REAL, DECIMAL, etc.)
are converted to FLOAT before being sent to the RPC.

=item $dbh->dbrpcsend([$no_ok])

Execute an RPC initiated with dbrpcinit().

By default this routine calls the C library dbrpcsend() and dbsqlok(), so 
that you can directly call $dbh->dbresults directly after a call to 
$dbh->dbrpcsend. If you need more control you can pass a non-0 value for 
the $no_ok parameter, and it will then be your responsibility to call
$dbh->dbsqlok(). Please read the Sybase OpenClient DB-Library manual
pages on dbrpcsend() and dbsqlok() for further details.

=item dbrpwset($srvname, $pwd)

Set the password for connecting to a remote server.

=item dbrpwclr

Clear all remote server passwords.

=back

=head2 Registered procedure execution

=over 4

=item $status = $dbh->dbreginit($proc_name)

=item $status = $dbh->dbreglist

=item $status = $dbh->dbreglist($parname, $type, $datalen, $value)

=item $status = $dbh->dbregexec($opt)

These routines are used to execute an OpenServer registered procedure.
Please see the Sybase DB-Library manual for a description of what these
routines do, and how to call them.

=back

=head2 Two Phase Commit Routines

=over 4

=item $dbh = Sybase::DBlib->open_commit($user, $pwd, $server, $appname)

=item $id = $dbh->start_xact($app_name, $xact_name, $site_count)

=item $status = $dbh->stat_xact($id)

=item $status = $dbh->scan_xact($id)

=item $status = $dbh->commit_xact($id)

=item $status = $dbh->abort_xact($id)

=item $dbh->close_commit

=item $string = Sybase::DBlib::build_xact_string($xact_name, $service_name, $id)

=item $status = $dbh->remove_xact($id, $site_count)

Please see the Sybase documentation for this.

B<NOTE:> These routines have not been thoroughly tested!

=back

=head2 Exported Routines

=over 4

=item $old_handler = dberrhandle($err_handle)

=item $old_handler = dbmsghandle($msg_handle)

Register an error (or message) handler for DB-Library to use. Handler
examples can be found in B<sybutil.pl> in the Sybperl
distribution. Returns a reference to the previously defined handler
(or undef if none were defined). Passing undef as the argument clears
the handler.

=item dbsetifile($filename)

Set the name of the 'interfaces' file. This file is normally found by
DB-Library in the directory pointed to by the $SYBASE environment variable.

=item dbrecftos($filename)

Start recording all SQL sent to the server in file $filename.

=item dbversion

Returns a string identifying the version of DB-Library that this copy
of Sybperl was built with.

=item DBSETLCHARSET($charset)

=item DBSETLNATLANG($language)

=item DBSETLPACKET($packet_size)

=item DBSETLENCRYPT($flag)

=item $time = DBGETTIME

=item $time = dbsettime($seconds)

=item $time = dbsetlogintime($seconds)

These utility routines are probably very seldom used. See the
DB-Library manual for an explanation of their use.

=item dbexit

Tell DB-Library that we're done. Once this call has been made, no
further activity requiring DB-Library can be performed in the current
program.

=back

=head2 High Level Wrapper Functions (sql() and nsql())

These routines are not part of the DB-Library API, but have been added
because they can make our life as programmers easier, and exploit
certain strengths of Perl.

=over 4

=item $ret|@ret = $dbh->sql($cmd [, \&rowcallback [, $flag]])

Runs the sql command and returns the result as a reference to an array
of the rows. In a LIST context, return the array itself (instead of a
reference to the array).  Each row is a reference to a list of scalars.

If you provide a second parameter it is taken as a procedure to call
for each row.  The callback is called with the values of the row as
parameters.

If you provide a third parameter, this is used in the call to
dbnextrow() to retrieve associative arrays rather than 'normal' arrays
for each row, and store them in the returned array. To pass the third
parameter without passing the &rowcallback value you should pass the
special value I<undef> as second parameter:

	@rows = $dbh->sql("select * from sysusers", undef, TRUE);
	foreach $row_ref (@rows) {
	    if($$row_ref{'uid'} == 10) {
	        ....
	    }
	}

See also eg/sql.pl for an example.

Contributed by Gisle Aas.

B<NOTE:> This routine loads all the data into memory. It should not be
run with a query that returns a large number of rows. To avoid the
risk of overflowing memory, you can limit the number of rows that the
query returns by setting the 'MaxRows' field of the $dbh attribute
field:

	$dbh->{'MaxRows'} = 100;

This value is B<not> set by default.

=item @ret = $dbh->nsql($sql [, "ARRAY" | "HASH" ] [, \&subroutine ] );

An enhanced version of the B<sql> routine, B<nsql>, is also available.
nsql() provides better error checking (using its companion error and
message handlers), optional deadlock retry logic, and several options
for the format of the return values.  In addition, the data can either
be returned to the caller in bulk, or processes line by line via a
callback subroutine passed as an argument (this functionality is
similar to the r_sql() method).

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
pair of Sybase message/error handler routines are also provided which
will use $DB_ERROR for the Sybase messages and errors as well.
However, these must be installed by the client application:

    dbmsghandle("Sybase::DBlib::nsql_message_handler");
    dberrhandle("Sybase::DBlib::nsql_error_handler");

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

    $Sybase::DBlib::nsql_strip_whitespace

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
the query is canceled via dbcancel(), and nsql() will abort further
processing.

WARNING: Using the following deadlock retry logic together with a
callback routine is dangerous.  If a deadlock is encountered after
some rows have already been processed by the callback, then the data
will be processed a second time (or more, if the deadlock is retried
multiple times).

The nsql() method also supports automated retries of deadlock errors
(1205).  This is disabled by default, and enabled only if the
variable

    $Sybase::DBlib::nsql_deadlock_retrycount

is non-zero.  This variable is the number of times to resubmit a given
SQL query, and the variable

    $Sybase::DBlib::nsql_deadlock_retrysleep

is the delay, in seconds, between retries (default is 60).  Normally,
the retries happen silently, but if you want nsql() to carp() about
it, then set

    $Sybase::DBlib::nsql_deadlock_verbose

to a true value, and nsql() will whine about the failure.  If all of
the retries fail, then nsql() will return an error, as it normally
does.  If you want the code to try forever, then set the retry count
to -1.

=back

=head2 Constants

Most of the #defines from sybdb.h can be accessed as
B<Sybase::DBlib::NAME> (e.g., B<Sybase::DBlib::STDEXIT>). Additional constants are:

=over 4

=item $Sybase::DBlib::Version

The Sybperl version. Can be interpreted as a string or as a number.

=item DBLIBVS

The version of I<DB-Library> that sybperl was built against.

=back

=head2 Attributes

The behavior of certain aspects of the Sybase::DBlib module can be
controlled via global or connection specific attributes. The global
attributes are stored in the %Sybase::DBlib::Att variable, and the
connection specific attributes are stored in the $dbh. To set a global
attribute, you would code

     $Sybase::DBlib::Att{'AttributeName'} = value;

and to set a connection specific attribute you would code

     $dbh->{"AttributeName'} = value;

B<NOTE!!!> Global attribute setting changes do not affect existing
connections, and changing an attribute inside a ct_fetch() does B<not>
change the behavior of the data retrieval during that ct_fetch()
loop.

The following attributes are currently defined:

=over 4

=item dbNullIsUndef

If set, NULL results are returned as the Perl 'undef' value, otherwise
as the string "NULL". B<Default:> set.

=item dbKeepNumeric

If set, numeric results are not converted to strings before returning
the data to Perl. B<Default:> set.

=item dbBin0x

If set, BINARY results are preceded by '0x' in the result. B<Default:> unset.

=item useDateTime

Turn the special handling of B<DATETIME> values on. B<Default:>
unset. See the section on special datatype handling below.

=item useMoney

Turn the special handling of B<MONEY> values on. B<Default:>
unset. See the section on special datatype handling below.

=back

=head2 Status Variables

These status variables are set by I<Sybase::DBlib> internal routines,
and can be accessed using the $dbh->{'variable'} syntax.

=over 4

=item DBstatus

The return status of the last call to I<dbnextrow>.

=item ComputeID

The compute id of the current returned row. Is 0 if no I<compute by>
clause is currently being processed.

=back

=head2 Examples

=over 4

=item BCP from program variables

See also B<Sybase::BCP> for a simplified bulk copy API.


   &BCP_SETL(TRUE);
   $dbh = new Sybase::DBlib $User, $Password;
   $dbh->bcp_init("test.dbo.t2", '', '', DB_IN);
   $dbh->bcp_meminit(3);   # we wish to copy three columns into
			   # the 't2' table
   while(<>)
   {
	chop;
	@dat = split(' ', $_);
	$dbh->bcp_sendrow(@dat);
   }
   $ret = $dbh->bcp_done;

=item Using the sql() routine

   $dbh = new Sybase::DBlib;
   $ret = $dbh->sql("select * from sysprocesses");
   foreach (@$ret)   # Loop through each row
   {
       @row = @$_;
       # do something with the data row...
   }

   $ret = $dbh->sql("select * from sysusers", sub { print "@_"; });
   # This will select all the info from sysusers, and print it

=item Getting SHOWPLAN and STATISTICS information within a script

You can get B<SHOWPLAN> and B<STATISTICS> information when you run a
B<sybperl> script. To do so, you must first turn on the respective
options, using dbsetopt(), and then you need a special message handler
that will filter the B<SHOWPLAN> and/or B<STATISTICS> messages sent
from the server.

The following message handler differentiates the B<SHOWPLAN> or
B<STATICSTICS> messages from other messages:

    # Message number 3612-3615 are statistics time / statistics io
    # message. Showplan messages are numbered 6201-6225.
    # (I hope I haven't forgotten any...)
    @sh_msgs = (3612 .. 3615, 6201 .. 6225);
    @showplan_msg{@sh_msgs} = (1) x scalar(@sh_msgs);

    sub showplan_handler {
	my ($db, $message, $state, $severity, $text,
	    $server, $procedure, $line)	= @_;
    
        # Don't display 'informational' messages:
	if ($severity > 10) {
	    print STDERR ("Sybase message ", $message, ",
	       Severity ", $severity, ", state ", $state);
	    print STDERR ("\nServer `", $server, "'") if defined ($server);
	    print STDERR ("\nProcedure `", $procedure, "'")
		  if defined ($procedure);
	    print STDERR ("\nLine ", $line) if defined ($line);
	    print STDERR ("\n    ", $text, "\n\n");
        }
        elsif($showplan_msg{$message}) {
	# This is a HOWPLAN or STATISTICS message, so print it out:
	    print STDERR ($text, "\n");
        }
        elsif ($message == 0) {
	    print STDERR ($text, "\n");
        }
    
        0;
    }

This could then be used like this:

    use Sybase::DBlib;
    dbmsghandle(\&showplan_handler);

    $dbh = new Sybase::DBlib  'mpeppler', $password, 'TROLL';

    $dbh->dbsetopt(DBSHOWPLAN);
    $dbh->dbsetopt(DBSTAT, "IO");
    $dbh->dbsetopt(DBSTAT, "TIME");

    $dbh->dbcmd("select * from xrate where date = '951001'");
    $dbh->dbsqlexec;
    while($dbh->dbresults != NO_MORE_RESULTS) {
	while(@dat = $dbh->dbnextrow) {
	    print "@dat\n";
        }
    }

Et voilà!

=back

=head1 Utility routines
        
=item Sybase::DBlib::debug($bitmask)

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

=item * TRACE_OVERLOAD

Trace all overloaded operations involving DateTime, Money or Numeric
datatypes.

=back

Two special trace flags are B<TRACE_NONE>, which turns off debug
tracing, and B<TRACE_ALL> which (you guessed it!) turns everything on.

The traces are pretty obscure, but they can be useful when trying to
find out what is I<really> going on inside the program.

For the B<TRACE_*> flags to be available in your scripts, you must
load the Sybase::DBlib module with the following syntax:

     use Sybase::DBlib qw(:DEFAULT /TRACE/);

This tells the autoloading mechanism to import all the I<default>
symbols, plus all the I<trace> symbols.


=head1 Special handling of DATETIME, MONEY & NUMERIC/DECIMAL values

B<NOTE:> This feature is turned off by default for performance
reasons.  You can turn it on per datatype and B<dbh>, or via the
module attribute hash (%Sybase::DBlib::Att and %Sybase::CTlib::Att).

The Sybase::CTlib and Sybase::DBlib modules include special features
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

=over 4

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

=over 4

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

The Sybase::DBlib 2PC calls have not been well tested.

There is a (approximately) 300 byte memory leak in the newdbh() function
in Sybase/DBlib.xs. This function is called when a 
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

Jeffrey Wong for the Sybase::DBlib DBMONEY routines.

W. Phillip Moore E<lt>F<Phil.Moore@msdw.com>E<gt> for the nsql() method.

Numerous folks have contributed ideas and bug fixes for which they
have my undying thanks :-) 

The sybperl mailing list E<lt>F<sybperl-l@peppler.org>E<gt> is the
best place to ask questions.

=cut

    
