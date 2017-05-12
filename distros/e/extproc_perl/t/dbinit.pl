# $Id: dbinit.pl,v 1.5 2006/08/03 16:04:28 jeff Exp $

# connect to database and initialize test environment

my $dbname = $ENV{'ORACLE_SID'};
my $dbuser = $ENV{'ORACLE_USERID'};

sub init_test
{
    my $dbh = shift;
    my $rc;
    foreach (1..2) {
        $rc = $dbh->do('BEGIN TestPerl.test; END;');
        last unless (defined($dbh->errstr) && $dbh->errstr =~ /ORA-28576/);
    }
    return $rc;
}

sub dbinit
{
    my $dbh = DBI->connect("dbi:Oracle:$dbname", $dbuser);
    unless ($dbh) {
        print "Bail out! DBI->connect failed: $DBI::errstr\n";
        exit 1;
    }

    # FOR DEVELOPMENT: enable debugging & tracing
    # $dbh->do('BEGIN TestPerl.debug(1); END;');
    # $dbh->do('alter session set sql_trace true');

    return $dbh;
}

sub create_extproc
{
    my ($dbh, $spec) = @_;
    my $rc = $dbh->do("BEGIN TestPerl.create_extproc('$spec', 'TEST_PERL_LIB'); END;");
    return $rc;
}

sub run_ddl
{
    my ($dbh, $sub) = @_;
    if (open(DDL, "t/$sub.sql")) {
        local $/;
        my $ddl = <DDL>;
        close(DDL);
        # strip off trailing slash
        $ddl =~ s/\///;
        my $rc = $dbh->do($ddl);
        return $rc;
    }
    else {
        return 0;
    }
}
