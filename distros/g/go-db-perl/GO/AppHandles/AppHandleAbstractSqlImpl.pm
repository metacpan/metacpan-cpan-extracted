# $Id: AppHandleAbstractSqlImpl.pm,v 1.5 2009/05/22 23:07:25 sjcarbon Exp $
#
# This GO module is maintained by Chris Mungall <cjm@fruitfly.org>
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself


package GO::AppHandles::AppHandleAbstractSqlImpl;

=head1 NAME

GO::AppHandles::AppHandleAbstractSqlImpl

=head1 SYNOPSIS

you should never use this class directly. Use GO::AppHandle
(All the public methods calls are documented there)

=head1 DESCRIPTION

Common methods for Sql implementations of AppHandle

=head1 FEEDBACK

Email cjm@fruitfly.berkeley.edu

=cut

use strict;
use Carp;
use FileHandle;
use Carp;
use DBI;
use GO::Utils qw(rearrange pset2hash dd);
use GO::SqlWrapper qw(:all);
use Exporter;
use base qw(GO::AppHandle);
use vars qw($AUTOLOAD);

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    my $init_h = shift;
    $self->dbh($self->get_handle($init_h));
    ## COMMENTARY: A dubious thing in a post-!IEA world.
    #$self->filters({evcodes=>["!IEA"]});
    $self->init;
    return $self;
}

sub init {
    my $self = shift;
    my $dbh = $self->dbh;

    $self->refresh;
}


# inherits: disconnect

sub reset_acc2name_h {
    my $self = shift;
    delete $self->{_acc2name_h};
    return;
}

sub apph{
  my $self = shift;
  $self->{apph} = shift if @_;

  my $apph = $self->{apph} || $self;
  return $apph;
}

# private accessor: the DBI handle
sub dbh {
    my $self = shift;
    $self->{_dbh} = shift if @_;
    return $self->{_dbh};
}

# private accessor: DBMS (mysql/ifx/oracle/etc)
sub dbms {
    my $self = shift;
    if (@_) {
	$self->{_dbms} = shift;
	$ENV{DBMS} = $self->{_dbms};
    }
    return $self->{_dbms};
}

sub commit {
    my $self = shift;
    if ($self->is_transactional) {
	$self->dbh->commit;
    }
}

sub disconnect {
    my $self = shift;
    if ($self->dbh) { $self->dbh->disconnect} 
}


# private method: makes the connection to the database
sub get_handle {
    my $self = shift;
    my $init_h = shift || {};

    # precedence level 1: resource config file
    my $rcf = $init_h->{rcfile} || '';
    my $env = $ENV{HOME} || '';
    my $rcfile = $rcf || $env . '/.geneontologyrc';
    if (-f $rcfile) {
        my $fh = FileHandle->new($rcfile);
        if ($fh) {
            while(<$fh>) {
                chomp;
                if (/^\#/) { next}
                if (/^$/) { next}
                if (!(/^(\w+)[\s+](.*)$/)) {die}
                unless (defined($init_h->{$1})) {$init_h->{$1} = $2};
            }
            $fh->close;
        }
    }

    my $database_name = 
	$init_h->{dbname} || "go";
    my $dbms = $ENV{DBMS} || $init_h->{'dbms'} || "mysql"; 
    $self->dbms($dbms);
    $dbms =~ s/pg/Pg/;
    my $dsn = $init_h->{dsn};
    if (!$dsn) {
        $dsn = "dbi:$dbms:$database_name";
        if ($dbms eq 'Pg') {
            $dsn = "dbi:$dbms:dbname=$database_name";
        }
    }
    if ($database_name =~ /\@/) {
	my ($dbn,$host) = split(/\@/, $database_name);
	$dsn = "dbi:$dbms:database=$dbn;host=$host";
        if ($dbms eq 'Pg') {
            $dsn = "dbi:$dbms:dbname=$database_name;host=$host";
        }
    }
    elsif ($init_h->{dbhost}) {
	$dsn = "dbi:$dbms:database=$database_name;host=$init_h->{dbhost}";
        if ($dbms eq 'Pg') {
            $dsn = "dbi:$dbms:dbname=$database_name;host=$init_h->{dbhost}";
        }
    }

    my $dbiproxy = $init_h->{dbiproxy} || $ENV{DBI_PROXY};
    if ($dbiproxy) {
	$dsn = "dbi:Proxy:$dbiproxy;dsn=$dsn";
    }
    # Either port or dbport will work
    if ($init_h->{port}) {
	$dsn .= ";port=$init_h->{port}";
    }
    if ($init_h->{dbport}) {
	$dsn .= ";port=$init_h->{dbport}";
    }
    if ($init_h->{dbsocket}) {
	$dsn .= ";mysql_socket=$init_h->{dbsocket}";
    }
    if ($init_h->{qw(local-infile)}) {
	$dsn .= ";mysql_local_infile=$init_h->{qw(local-infile)}";
    }


    if ($init_h->{dsn}) {
	$dsn = $init_h->{dsn};
    }
    if($ENV{SQL_TRACE}) {print STDERR "DSN=$dsn\n"};
    my @params = ();

    if ($init_h->{dbuser}) {
	push(@params,
	     $init_h->{dbuser});
	push(@params,
	     $init_h->{dbauth});
        if($ENV{SQL_TRACE}) {print STDERR "PARAMS=@params\n"};
    }

    my $dbh;
    if ($init_h->{dbh}) {
	$dbh = $init_h->{dbh};
    }
    else {
	$dbh = DBI->connect($dsn, @params) || confess($DBI::errstr);
    }
##    my $dbh = DBI->connect($dsn);
##    $dbh->{RaiseError} = 1;
    $dbh->{private_database_name} = $database_name;
    $dbh->{private_dbms} = $dbms;

    if ($init_h->{dbi_search_path}) {
        my $cmd = "SET SEARCH_PATH TO $init_h->{dbi_search_path}";
        print STDERR "$cmd\n";
        $dbh->do($cmd);
        print STDERR "Done: $cmd\n";
    }

    if ($dbms eq "mysql") {
    }
    else {
        $self->is_transactional(1);
    }
    $dbh->begin_work if $self->is_transactional;

#    elsif (lc($dbms) eq "pg") {
#        # postgres wont query if there are exceptions
#	$dbh->{AutoCommit} = 1;
#    }
#    else {
#	$dbh->{AutoCommit} = 0;
#    }

    # default behaviour should be to chop trailing blanks;
    # this behaviour is preferable as it makes the semantics free
    # of physical modelling issues
    # e.g. if we have some code that compares a user supplied string
    # with a database varchar, this code will break if the varchar
    # is changed to a char, unless we chop trailing blanks
    $dbh->{ChopBlanks} = 1;
    return $dbh;
}

# private accessor: boolean indicating if DB has transactions
# (Default: no; we assume mysql as default)
sub is_transactional {
    my $self = shift;
    $self->{_is_transactional} = shift if @_;
    return $self->{_is_transactional} || 
      ($self->dbms && (lc($self->dbms) ne "mysql"));
}



1;
