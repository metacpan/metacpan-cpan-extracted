# -*-Perl-*-
# $Id: Sybperl.pm,v 1.33 2004/06/11 13:04:09 mpeppler Exp $
#
# From
# 	@(#)Sybperl.pm	1.27	03/26/98
#
# Copyright (c) 1994-1995
#   Michael Peppler
#
#   You may copy this under the terms of the GNU General Public License,
#   or the Artistic License, copies of which should have accompanied
#   your Perl kit.

package Sybase::Sybperl;

=head1 NAME

Sybase::Sybperl - sybperl 1.0xx emulation module

=head1 SYNOPSIS

    require 'sybperl.pl';

    $dbproc = dblogin($user, $pwd, $server);
    dbcmd($dbproc, "select * from sysusers");
    dbsqlexec($dbproc);
    dbresults($dbproc);
    while(@data = dbnextrow($dbproc)) {
        print "@data\n";
    }

=head1 DESCRIPTION

The Sybase::Sybperl module is provided to ease porting old perl4/sybperl 1.x
programs to perl5. It is not recommended that this module be used for
any new project. See L<Sybase::DBlib> or L<Sybase::CTlib> for alternatives.

The old sybperl 1.0xx manpage is in the pod/sybperl-1.0xx.man in the
sybperl source distribution.

=head1 AUTHOR

Michael Peppler F<E<lt>mpeppler@peppler.orgE<gt>>.

=cut

package Sybase::Sybperl::Attribs;

sub TIESCALAR {
    my($x);
    $x = $_[1];
    $att{$x} = $_[2];

    bless \$x;
}
sub FETCH {
    my($x) = shift;
    return $att{$$x};
}
sub STORE {
    my($x) = shift;
    my($val) = shift;
    my($key);

    $att{$$x} = $val;

    foreach (keys %Sybase::Sybperl::DBprocs) {
	$key = $Sybase::Sybperl::DBprocs{$_};
	$key->{$$x} = $val;
    }
}    
    

package Sybase::Sybperl;

use Carp;
require Exporter;
use AutoLoader 'AUTOLOAD';
use Sybase::DBlib;

@ISA = qw(Exporter);

$SUCCEED = Sybase::DBlib::SUCCEED;
$FAIL = Sybase::DBlib::FAIL;
$NO_MORE_RESULTS = Sybase::DBlib::NO_MORE_RESULTS;
$NO_MORE_ROWS = Sybase::DBlib::NO_MORE_ROWS;
$MORE_ROWS = Sybase::DBlib::MORE_ROWS;
$REG_ROW = Sybase::DBlib::REG_ROW;
$DBTRUE = Sybase::DBlib::TRUE;
$DBFALSE = Sybase::DBlib::FALSE;
$DB_IN = Sybase::DBlib::DB_IN;
$DB_OUT = Sybase::DBlib::DB_OUT;

$VERSION = $Sybase::DBlib::VERSION;
# Set defaults.
tie $dbNullIsUndef, Sybase::Sybperl::Attribs, 'dbNullIsUndef', 1;
tie $dbKeepNumeric, Sybase::Sybperl::Attribs, 'dbKeepNumeric', 1;
tie $dbBin0x, Sybase::Sybperl::Attribs, 'dbBin0x', 0;

@AttKeys = qw(dbNullIsUndef dbKeepNumeric dbBin0x);

@EXPORT = qw(dblogin dbcmd dbsqlexec dbsqlsend dbresults dbnextrow dbstrcpy
	     dbuse dbopen dbclose
	     $SUCCEED $FAIL $NO_MORE_RESULTS $NO_MORE_ROWS
	     $MORE_ROWS $REG_ROW $DBTRUE $DBFALSE $DB_IN $DB_OUT
	     $dbNullIsUndef $dbKeepNumeric $dbBin0x
	     bcp_init bcp_meminit bcp_sendrow bcp_batch bcp_done
	     bcp_control bcp_columns bcp_colfmt bcp_collen bcp_exec
	     bcp_readfmt bcp_writefmt
	     dbcancel dbcanquery dbfreebuf
	     DBCURCMD DBMORECMDS DBCMDROW DBROWS DBCOUNT DBDEAD dbhasretstat
	     dbretstatus dbnumcols dbcoltype dbcollen dbcolname
	     dbretdata dbsafestr
	     dbmsghandle dberrhandle dbexit dbrecftos
	     BCP_SETL bcp_getl
	     dbsetlogintime dbsettime DBGETTIME
	     DBSETLNATLANG DBSETLCHARSET dbversion
	     dbsetifile dbrpwclr dbrpwset
	     DBLIBVS FAIL
	     INT_CANCEL INT_CONTINUE	INT_EXIT INT_TIMEOUT
	     MORE_ROWS NO_MORE_RESULTS NO_MORE_ROWS NULL REG_ROW
	     STDEXIT SUCCEED SYBESMSG 
	     BCPBATCH BCPERRFILE BCPFIRST BCPLAST BCPMAXERRS	BCPNAMELEN
	     DBBOTH DBSINGLE DB_IN DB_OUT TRUE FALSE
	     dbmnymaxpos dbmnymaxneg dbmnyndigit dbmnyscale dbmnyinit
	     dbmnydown dbmnyinc dbmnydec dbmnyzero dbmnycmp dbmnysub
	     dbmnymul dbmnyminus dbmnydivide dbmnyadd dbmny4zero
	     dbmny4cmp dbmny4sub dbmny4mul dbmny4minus dbmny4divide
	     dbmny4add sql
	     dbrpcinit dbrpcparam dbrpcsend
	     dbwritetext dbreadtext dbmoretext dbpreptext);


# Internal routine to check that a parameter passed as $dbproc to one
# of the Sybase::Sybperl routines is indeed a valid reference.
sub isadb
{
    my($db) = @_;
    my($ret) = 1;
    if(ref($db) ne "Sybase::DBlib")
    {
	carp("\$dbproc parameter is not valid - using default") if($^W);
	$ret = 0;
    }
    $ret;
}

sub dblogin
{
    my($x);

    ($x = Sybase::DBlib->dblogin(@_)) or return -1;

    $default_db = $x if(!defined($default_db));

    $DBprocs{$x} = $x;
    foreach (@AttKeys) {
	$x->{$_} = $Sybase::Sybperl::Attribs::att{$_};
    }
	
    $x;
}

sub dbopen
{
    my($x);

    ($x = Sybase::DBlib->dbopen(@_)) or return -1;

    $default_db = $x if(!defined($default_db));
	
    $DBprocs{$x} = $x;
    foreach (@AttKeys) {
	$x->{$_} = $Sybase::Sybperl::Attribs::att{$_};
    }

    $x;
}

sub dbclose
{
    my($dbproc) = @_;
    my($count);

    croak "&dbclose() must be called with an argument!\n"
	if(!defined($dbproc) || !&isadb($dbproc));

    if($default_db == $dbproc) {
	undef($default_db);
    }

    delete($DBprocs{$dbproc});
    $dbproc->force_dbclose;
    undef($dbproc);
}

sub dbuse
{
    my(@params) = @_;
    my($dbproc);

    if(@params == 1)
    {
	if(!defined($default_db))
	{
	    $default_db = &dblogin();
	    $DBprocs{$default_db} = $default_db;
	    foreach (@AttKeys) {
		$default_db->{$_} = $Sybase::Sybperl::Attribs::att{$_};
	    }
	}
	$dbproc = $default_db;
    }
    else
    {
	$dbproc = shift(@params);
    }
    $dbproc->dbuse(@params);
}

sub dbcmd
{
    my(@params) = @_;
    my($dbproc);

    if(@params == 1)
    {
	if(!defined($default_db))
	{
	    $default_db = &dblogin();
	    $DBprocs{$default_db} = $default_db;
	    foreach (@AttKeys) {
		$default_db->{$_} = $Sybase::Sybperl::Attribs::att{$_};
	    }
	}
	$dbproc = $default_db;
    }
    else
    {
	$dbproc = shift(@params);
    }
    $dbproc->dbcmd(@params);
}
    
sub dbsqlsend
{
    my($dbproc) = @_;
    my($ret);

    if(!defined($dbproc) || !$dbproc || !&isadb($dbproc))
    {
	croak("It doesn't make sense to call dbsqlsend with an undefined \$dbproc") if(!defined($default_db));
	$dbproc = $default_db;
    }
    $ret = $dbproc->dbsqlsend;
    $ret;
}

sub dbsqlexec
{
    my($dbproc) = @_;
    my($ret);

    if(!defined($dbproc) || !$dbproc || !&isadb($dbproc))
    {
	croak("It doesn't make sense to call dbsqlexec with an undefined \$dbproc") if(!defined($default_db));
	$dbproc = $default_db;
    }
    $ret = $dbproc->dbsqlexec;
    $ret;
}

sub dbsqlok
{
    my($dbproc) = @_;
    my($ret);

    if(!defined($dbproc) || !$dbproc || !&isadb($dbproc))
    {
	croak("It doesn't make sense to call dbsqlok with an undefined \$dbproc") if(!defined($default_db));
	$dbproc = $default_db;
    }
    $ret = $dbproc->dbsqlok;
    $ret;
}

sub dbresults
{
    my($dbproc) = @_;
    my($ret);

    if(!defined($dbproc) || !$dbproc || !&isadb($dbproc))
    {
	croak("It doesn't make sense to call dbresults with an undefined \$dbproc") if(!defined($default_db));
	$dbproc = $default_db;
    }
    $ret = $dbproc->dbresults;
    $ret;
}

sub dbnextrow
{
    my(@params) = @_;
    my($dbproc);
    my(@row);

    $dbproc = shift(@params);
    if(!$dbproc)
    {
	croak("dbproc is undefined.") if (!defined($default_db));
	$dbproc = $default_db;
    }
    
    @row = $dbproc->dbnextrow(@params);
    
    $main::ComputeId = $dbproc->{'ComputeID'};
    $main::DBstatus = $dbproc->{'DBstatus'};

    @row;
}

sub dbstrcpy
{
    my($dbproc) = @_;
    my($ret);

    if(!defined($dbproc) || !$dbproc || !&isadb($dbproc))
    {
	croak("It doesn't make sense to call dbstrcpy with an undefined \$dbproc") if(!defined($default_db));
	$dbproc = $default_db;
    }
    $ret = $dbproc->dbstrcpy;
    $ret;
}


# These two should really be auto-loaded, but the generated filenames
# aren't unique in the first 8 letters.'
sub dbmnymaxneg
{
    my($dbproc) = @_;
    my(@ret);

    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));

    @ret = $dbproc->dbmnymaxneg(@params);

    @ret;
}
sub dbmnymaxpos
{
    my($dbproc) = @_;
    my(@ret);

    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));

    @ret = $dbproc->dbmnymaxpos(@params);

    @ret;
}

__END__

sub dbcancel
{
    my($dbproc) = @_;
    my($ret);
    
    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));

    $ret = $dbproc->dbcancel;

    $ret;
}

sub dbcanquery
{
    my($dbproc) = @_;
    my($ret);
    
    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));

    $ret = $dbproc->dbcanquery;

    $ret;
}

sub dbfreebuf
{
    my($dbproc) = @_;
    
    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));

    $dbproc->dbfreebuf;
}

sub dbsetopt
{
    my($dbproc, @param) = @_;

    $dbproc->dbsetopt(@param);
}

sub dbclropt
{
    my($dbproc, @param) = @_;

    $dbproc->dbclropt(@param);
}

sub dbisopt
{
    my($dbproc, @param) = @_;

    $dbproc->dbisopt(@param);
}


sub DBCURCMD
{
    my($dbproc) = @_;
    my($ret);

    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));
    $ret = $dbproc->DBCURCMD;
}
sub DBMORECMDS
{
    my($dbproc) = @_;
    my($ret);

    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));
    $ret = $dbproc->DBMORECMDS;
}
sub DBCMDROW
{
    my($dbproc) = @_;
    my($ret);

    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));
    $ret = $dbproc->DBCMDROW;
}
sub DBROWS
{
    my($dbproc) = @_;
    my($ret);

    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));
    $ret = $dbproc->DBROWS;
}
sub DBCOUNT
{
    my($dbproc) = @_;
    my($ret);

    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));
    $ret = $dbproc->DBCOUNT;
}

sub DBDEAD
{
    my($dbproc) = @_;
    my($ret);

    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));
    $ret = $dbproc->DBDEAD;
}

sub dbhasretstat
{
    my($dbproc) = @_;
    my($ret);

    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));
    $ret = $dbproc->dbhasretstat;
}

sub dbretstatus
{
    my($dbproc) = @_;
    my($ret);

    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));
    $ret = $dbproc->dbretstatus;
}

sub dbnumcols
{
    my($dbproc) = @_;
    my($ret);

    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));
    $ret = $dbproc->dbnumcols;
}

sub dbprtype
{
    my(@params) = @_;
    my($dbproc);
    my($ret);

    if(@params == 1)
    {
	croak("dbproc is undefined.") if (!defined($default_db));
    }
    else
    {
	$dbproc = shift(@params);
    }

    $ret = $dbproc->dbprtype(@params);
}

sub dbcoltype
{
    my(@params) = @_;
    my($dbproc, $ret);
    
    if(@params == 1)
    {
	croak("dbproc is undefined.") if(!defined($default_db));
	$dbproc = $default_db;
    }
    else
    {
	$dbproc = shift(@params);
    }
    $ret = $dbproc->dbcoltype(@params);
}

sub dbcollen
{
    my(@params) = @_;
    my($dbproc, $ret);
    
    if(@params == 1)
    {
	croak("dbproc is undefined.") if(!defined($default_db));
	$dbproc = $default_db;
    }
    else
    {
	$dbproc = shift(@params);
    }
    $ret = $dbproc->dbcollen(@params);
}

sub dbcolname
{
    my(@params) = @_;
    my($dbproc, $ret);
    
    if(@params == 1)
    {
	croak("dbproc is undefined.") if(!defined($default_db));
	$dbproc = $default_db;
    }
    else
    {
	$dbproc = shift(@params);
    }
    $ret = $dbproc->dbcolname(@params);
}

sub dbretdata
{
    my(@params) = @_;
    my($dbproc, @ret);
    
    if(@params >= 1)
    {
	$dbproc = shift(@params);
    }
    else
    {
	croak("dbproc is undefined.") if(!defined($default_db));
	$dbproc = $default_db;
    }
    @ret = $dbproc->dbretdata(@params);
}

sub dbsafestr
{
    my(@params) = @_;
    my($dbproc, $ret);
    
    $dbproc = shift(@params);
    $ret = $dbproc->dbsafestr(@params);
}



#####
# bcp routines
####

sub bcp_init
{
    my(@params) = @_;
    my($dbproc, $ret);
    
    if(@params == 4)
    {
	croak("dbproc is undefined.") if(!defined($default_db));
	$dbproc = $default_db;
    }
    else
    {
	$dbproc = shift(@params);
    }
    $ret = $dbproc->bcp_init(@params);
}

sub bcp_meminit
{
    my(@params) = @_;
    my($dbproc, $ret);
    
    if(@params == 1)
    {
	croak("dbproc is undefined.") if(!defined($default_db));
	$dbproc = $default_db;
    }
    else
    {
	$dbproc = shift(@params);
    }
    $ret = $dbproc->bcp_meminit(@params);
}

sub bcp_sendrow
{
    my(@params) = @_;
    my($dbproc, $ret);
    
    $dbproc = shift(@params);

    $ret = $dbproc->bcp_sendrow(@params);
}

sub bcp_batch
{
    my($dbproc) = @_;
    my($ret);
    
    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));
    $ret = $dbproc->bcp_batch;
}

sub bcp_done
{
    my($dbproc) = @_;
    my($ret);
    
    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));
    $ret = $dbproc->bcp_done;
}

sub bcp_control
{
    my(@params) = @_;
    my($dbproc, $ret);
    
    if(@params == 2)
    {
	croak("dbproc is undefined.") if(!defined($default_db));
	$dbproc = $default_db;
    }
    else
    {
	$dbproc = shift(@params);
    }
    $ret = $dbproc->bcp_control(@params);
}

sub bcp_columns
{
    my(@params) = @_;
    my($dbproc, $ret);
    
    if(@params == 1)
    {
	croak("dbproc is undefined.") if(!defined($default_db));
	$dbproc = $default_db;
    }
    else
    {
	$dbproc = shift(@params);
    }
    $ret = $dbproc->bcp_columns(@params);
}

sub bcp_colfmt
{
    my(@params) = @_;
    my($dbproc, $ret);
    
    if(@params == 7)
    {
	croak("dbproc is undefined.") if(!defined($default_db));
	$dbproc = $default_db;
    }
    else
    {
	$dbproc = shift(@params);
    }
    $ret = $dbproc->bcp_collen(@params);
}

sub bcp_collen
{
    my(@params) = @_;
    my($ret);
    
    if(@params == 2)
    {
	croak("dbproc is undefined.") if(!defined($default_db));
	unshift(@params, $default_db);
    }
    $params[0] = $default_db if(!$params[0]);
    $ret = $params[0]->bcp_collen($params[1], $params[2]);
}

sub bcp_exec
{
    my($dbproc) = @_;
    my(@ret);
    
    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));
    @ret = $dbproc->bcp_exec;
}


sub bcp_readfmt
{
    my(@params) = @_;
    my($ret);
    
    if(@params == 1)
    {
	if(!defined($default_db))
	{
	    $default_db = &dblogin();
	    $DBprocs{$default_db} = $default_db;
	    foreach (@AttKeys) {
		$default_db->{$_} = $Sybase::Sybperl::Attribs::att{$_};
	    }
	}
	unshift(@params, $default_db);
    }
    $params[0] = $default_db if(!$params[0]);
    $ret = $params[0]->bcp_readfmt($params[1]);
}

sub bcp_writefmt
{
    my(@params) = @_;
    my($ret);
    
    if(@params == 1)
    {
	if(!defined($default_db))
	{
	    $default_db = &dblogin();
	    $DBprocs{$default_db} = $default_db;
	    foreach (@AttKeys) {
		$default_db->{$_} = $Sybase::Sybperl::Attribs::att{$_};
	    }
	}
	unshift(@params, $default_db);
    }
    $params[0] = $default_db if(!$params[0]);
    $ret = $params[0]->bcp_writefmt($params[1]);
}

###
# dbmny routines:
###

sub dbmny4add
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 3)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmny4add(@params);

    @ret;
}

sub dbmny4divide
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 3)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmny4divide(@params);
}

sub dbmny4minus
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 3)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmny4minus(@params);
}

sub dbmny4mul
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 3)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmny4mul(@params);
}

sub dbmny4sub
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 3)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmny4sub(@params);
}

sub dbmny4cmp
{
    my(@params) = @_;
    my($dbproc);
    my($ret);

    if(@params == 3)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    $ret = $dbproc->dbmny4cmp(@params);
}

sub dbmny4zero
{
    my($dbproc) = @_;
    my(@ret);

    $dbproc = $default_db if(!defined($dbproc));

    @ret = $dbproc->dbmny4zero(@params);
}


sub dbmnyadd
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 3)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmnyadd(@params);
}

sub dbmnydivide
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 3)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmnydivide(@params);
}

sub dbmnyminus
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 3)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmnyminus(@params);
}

sub dbmnymul
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 3)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmnymul(@params);
}

sub dbmnysub
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 3)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmnysub(@params);
}

sub dbmnycmp
{
    my(@params) = @_;
    my($dbproc);
    my($ret);

    if(@params == 3)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    $ret = $dbproc->dbmnycmp(@params);
}

sub dbmnyzero
{
    my($dbproc) = @_;
    my(@ret);

    $dbproc = $default_db if(!defined($dbproc));

    @ret = $dbproc->dbmnyzero(@params);
}

sub dbmnydec
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 2)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmnydec(@params);
}

sub dbmnyinc
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 2)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmnyinc(@params);
}

sub dbmnydown
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 3)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmnydown(@params);
}

sub dbmnyinit
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 3)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmnyinit(@params);
}

sub dbmnyscale
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 4)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmnyscale(@params);
}

sub dbmnyndigit
{
    my(@params) = @_;
    my($dbproc);
    my(@ret);

    if(@params == 2)
    {
	$dbproc = shift(@params);
    }
    else
    {
	$dbproc = $default_db;
    }

    @ret = $dbproc->dbmnyndigit(@params);
}

sub sql
{
    my($db,$sql,$sep)=@_;			# local copy parameters
    my(@res, @data);

    $sep = '~' unless $sep;			# provide default for sep

    @res = ();					# clear result array

    $db->dbcmd($sql);				# pass sql to server
    $db->dbsqlexec;				# execute sql

    while($db->dbresults != NO_MORE_RESULTS) {	# copy all results
	while (@data = $db->dbnextrow) {
	    push(@res,join($sep,@data));
	}
    }

    @res;					# return the result array
}

sub dbrpcsend
{
    my($dbproc) = @_;

    $dbproc = $default_db if(!defined($dbproc) || !&isadb($dbproc));

    $dbproc->dbrpcsend;
}

sub dbrpcparam
{
    my(@param) = @_;
    my($dbproc);

    if(@param == 7)
    {
	$dbproc = shift(@param);
    }
    else
    {
	$dbproc = $default_db;
    }
    $dbproc->dbrpcparam(@param);
}

sub dbrpcinit
{
    my(@param) = @_;
    my($dbproc);

    if(@param == 3)
    {
	$dbproc = shift(@param);
    }
    else
    {
	$dbproc = $default_db;
    }

    $dbproc->dbrpcinit(@param);
}

sub dbreginit
{
    my(@param) = @_;
    my($dbproc);

    if(@param == 2)
    {
	$dbproc = shift(@param);
    }
    else
    {
	$dbproc = $default_db;
    }

    $dbproc->dbreginit(@param);
}

sub dbreglist
{
    my(@param) = @_;
    my($dbproc);

    if(@param == 1)
    {
	$dbproc = shift(@param);
    }
    else
    {
	$dbproc = $default_db;
    }

    $dbproc->dbreglist(@param);
}

sub dbregparam
{
    my(@param) = @_;
    my($dbproc);

    if(@param == 5)
    {
	$dbproc = shift(@param);
    }
    else
    {
	$dbproc = $default_db;
    }

    $dbproc->dbregparam(@param);
}

sub dbregexec
{
    my(@param) = @_;
    my($dbproc);

    if(@param == 2)
    {
	$dbproc = shift(@param);
    }
    else
    {
	$dbproc = $default_db;
    }

    $dbproc->dbregexec(@param);
}

sub dbwritetext
{
    my(@params) = @_;
    my($dbproc);

    $dbproc = shift(@params);

    $dbproc->dbwritetext(@params);
}

sub dbreadtext
{
    my(@params) = @_;
    my($dbproc);

    $dbproc = shift(@params);

    $dbproc->dbreadtext(@params);
}

sub dbmoretext
{
    my(@params) = @_;
    my($dbproc);

    $dbproc = shift(@params);

    $dbproc->dbmoretext(@params);
}

sub dbpreptext
{
    my(@params) = @_;
    my($dbproc);

    $dbproc = shift(@params);

    $dbproc->dbpreptext(@params);
}


1;


