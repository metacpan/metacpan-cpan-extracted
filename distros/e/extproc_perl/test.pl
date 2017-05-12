# $Id: test.pl,v 1.15 2006/04/07 19:56:13 jeff Exp $

use DBI;
use Cwd;
use Config;
use Test::Harness qw(runtests);

# check environment setup
unless (defined($ENV{'ORACLE_SID'})) {
    print "Please set ORACLE_SID before running 'make test'.\n";
    exit(1);
}
unless (defined($ENV{'ORACLE_USERID'})) {
    print "Please set ORACLE_USERID to username/password before running 'make test'.\n";
    exit(1);
}

# database setup
$| = 1;
print "\nPreparing test database:\n";

# this assumes we run tests from makefile in build directory
my $build_dir = getcwd();

# make sure we can write to the test directory
chmod(0777, "$build_dir/t");

my $dlext = $Config{'dlext'};

my $dbname = $ENV{'ORACLE_SID'};
my $dbuser = $ENV{'ORACLE_USERID'};

# connect to database
print "  Connecting to $dbname...";
my $dbh = DBI->connect("dbi:Oracle:$dbname", $dbuser, undef,
    { RaiseError => 1 }
);
print "done.\n";

my ($r, $sth);

# create TestPerl library
print "  Creating TestPerl library...";
$r = $dbh->do(qq{
    -- create PERL_LIB library
    CREATE OR REPLACE LIBRARY TEST_PERL_LIB IS
       '$build_dir/extproc_perl_test.${dlext}'
} );
print "done.\n";

# create TestPerl package spec
print "  Creating TestPerl package...";
$r = $dbh->do(qq{
-- TestPerl PL/SQL Package specification
    CREATE OR REPLACE PACKAGE TestPerl
    AS
        FUNCTION func (sub IN VARCHAR2, arg1 in VARCHAR2 default NULL,
            arg2 in VARCHAR2 default NULL, arg3 in VARCHAR2 default NULL,
            arg4 in VARCHAR2 default NULL, arg5 in VARCHAR2 default NULL,
            arg6 in VARCHAR2 default NULL, arg7 in VARCHAR2 default NULL,
            arg8 in VARCHAR2 default NULL, dummy in VARCHAR2 default NULL)
            RETURN STRING;

        PROCEDURE proc (sub IN VARCHAR2, arg1 in VARCHAR2 default NULL,
            arg2 in VARCHAR2 default NULL, arg3 in VARCHAR2 default NULL,
            arg4 in VARCHAR2 default NULL, arg5 in VARCHAR2 default NULL,
            arg6 in VARCHAR2 default NULL, arg7 in VARCHAR2 default NULL,
            arg8 in VARCHAR2 default NULL, dummy in VARCHAR2 default NULL);

        FUNCTION version RETURN STRING;
        PROCEDURE flush;
        PROCEDURE debug(enable in PLS_INTEGER);
        FUNCTION debug_file RETURN STRING;
        FUNCTION debug_status RETURN STRING;
        FUNCTION config(param in VARCHAR2) RETURN STRING;
        FUNCTION package RETURN STRING;
        FUNCTION errno RETURN STRING;
        FUNCTION errsv RETURN STRING;
        PROCEDURE eval(code in VARCHAR2);
        PROCEDURE import_perl(name in VARCHAR2, fname in VARCHAR2 default NULL, spec in VARCHAR2 default NULL);
        PROCEDURE drop_perl(name in VARCHAR2);
        PROCEDURE create_extproc(spec in VARCHAR2, lib in VARCHAR2 default NULL);
        PROCEDURE test;
    END TestPerl;
} );

# create TestPerl package body
$r = $dbh->do(qq{
    -- TestPerl PL/SQL Package body
    CREATE OR REPLACE PACKAGE BODY TestPerl
    AS
        FUNCTION func (sub IN VARCHAR2, arg1 in VARCHAR2 default NULL,
            arg2 in VARCHAR2 default NULL, arg3 in VARCHAR2 default NULL,
            arg4 in VARCHAR2 default NULL, arg5 in VARCHAR2 default NULL,
            arg6 in VARCHAR2 default NULL, arg7 in VARCHAR2 default NULL,
            arg8 in VARCHAR2 default NULL, dummy in VARCHAR2 default NULL)
            RETURN STRING AS
            EXTERNAL NAME "ora_perl_func"
            LIBRARY "TEST_PERL_LIB"
            WITH CONTEXT
            PARAMETERS (
                CONTEXT,
                RETURN INDICATOR BY REFERENCE,
                sub string,
                arg1 string,
                arg1 INDICATOR short,
                arg2 string,
                arg2 INDICATOR short,
                arg3 string,
                arg3 INDICATOR short,
                arg4 string,
                arg4 INDICATOR short,
                arg5 string,
                arg5 INDICATOR short,
                arg6 string,
                arg6 INDICATOR short,
                arg7 string,
                arg7 INDICATOR short,
                arg8 string,
                arg8 INDICATOR short,
                dummy string,
                dummy INDICATOR short
            );

        PROCEDURE proc (sub IN VARCHAR2, arg1 in VARCHAR2 default NULL,
            arg2 in VARCHAR2 default NULL, arg3 in VARCHAR2 default NULL,
            arg4 in VARCHAR2 default NULL, arg5 in VARCHAR2 default NULL,
            arg6 in VARCHAR2 default NULL, arg7 in VARCHAR2 default NULL,
            arg8 in VARCHAR2 default NULL, dummy in VARCHAR2 default NULL)
            AS
            EXTERNAL NAME "ora_perl_proc"
            LIBRARY "TEST_PERL_LIB"
            WITH CONTEXT
            PARAMETERS (
                CONTEXT,
                sub string,
                arg1 string,
                arg1 INDICATOR short,
                arg2 string,
                arg2 INDICATOR short,
                arg3 string,
                arg3 INDICATOR short,
                arg4 string,
                arg4 INDICATOR short,
                arg5 string,
                arg5 INDICATOR short,
                arg6 string,
                arg6 INDICATOR short,
                arg7 string,
                arg7 INDICATOR short,
                arg8 string,
                arg8 INDICATOR short,
                dummy string,
                dummy INDICATOR short
            );

        -- return version of extproc_perl
        FUNCTION version
            RETURN STRING AS
            EXTERNAL NAME "ora_perl_version"
            LIBRARY "TEST_PERL_LIB"
            WITH CONTEXT
            PARAMETERS (
                CONTEXT,
                RETURN INDICATOR BY REFERENCE
            );

        -- destroy current perl interpreter, keeping loaded config
        PROCEDURE flush
            AS
            EXTERNAL NAME "ora_perl_flush"
            LIBRARY "TEST_PERL_LIB"
            WITH CONTEXT
            PARAMETERS (
                CONTEXT
            );

        -- enable/disable debugging
        PROCEDURE debug(enable in PLS_INTEGER)
            AS
            EXTERNAL NAME "ora_perl_debug"
            LIBRARY "TEST_PERL_LIB"
            WITH CONTEXT
            PARAMETERS (
                CONTEXT,
                enable INT
            );

        -- return path to debug file
        FUNCTION debug_file
            RETURN STRING AS
            EXTERNAL NAME "ora_perl_debug_file"
            LIBRARY "TEST_PERL_LIB"
            WITH CONTEXT
            PARAMETERS (
                CONTEXT,
                RETURN INDICATOR BY REFERENCE
            );

        -- return debugging status
        FUNCTION debug_status
            RETURN STRING AS
            EXTERNAL NAME "ora_perl_debug_status"
            LIBRARY "TEST_PERL_LIB"
            WITH CONTEXT
            PARAMETERS (
                CONTEXT,
                RETURN INDICATOR BY REFERENCE
            );

        -- return session package name, if any
        FUNCTION package
            RETURN STRING AS
            EXTERNAL NAME "ora_perl_package"
            LIBRARY "TEST_PERL_LIB"
            WITH CONTEXT
            PARAMETERS (
                CONTEXT,
                RETURN INDICATOR BY REFERENCE
            );

        -- return most recent stringified system error ($!)
        FUNCTION errno
            RETURN STRING AS
            EXTERNAL NAME "ora_perl_errno"
            LIBRARY "TEST_PERL_LIB"
            WITH CONTEXT
            PARAMETERS (
                CONTEXT,
                RETURN INDICATOR BY REFERENCE
            );

        -- return most recent perl eval error (ERRSV, or $@)
        FUNCTION errsv
            RETURN STRING AS
            EXTERNAL NAME "ora_perl_errsv"
            LIBRARY "TEST_PERL_LIB"
            WITH CONTEXT
            PARAMETERS (
                CONTEXT,
                RETURN INDICATOR BY REFERENCE
            );

        -- return configuration parameters
        FUNCTION config(param in VARCHAR2)
            RETURN STRING AS
            EXTERNAL NAME "ora_perl_config"
            LIBRARY "TEST_PERL_LIB"
            WITH CONTEXT
            PARAMETERS (
                CONTEXT,
                RETURN INDICATOR BY REFERENCE,
                param STRING,
                param INDICATOR short
            );

        -- eval arbitrary perl code
        PROCEDURE eval(code in VARCHAR2)
            AS
            EXTERNAL NAME "ora_perl_eval"
            LIBRARY "TEST_PERL_LIB"
            WITH CONTEXT
            PARAMETERS (
                CONTEXT,
                code STRING
            );

        -- import code from trusted directory
        PROCEDURE import_perl(name in VARCHAR2, fname in VARCHAR2, spec in VARCHAR2 default NULL)
            IS
            BEGIN
                proc('ExtProc::Code::import_code', name, fname, spec);
            END;
    
        -- drop code from code table
        PROCEDURE drop_perl(name in VARCHAR2)
            IS
            BEGIN
                proc('ExtProc::Code::drop_code', name);
            END;

        -- create external procedure based on spec
        PROCEDURE create_extproc(spec in VARCHAR2, lib in VARCHAR2 default NULL)
            IS
            BEGIN
                proc('ExtProc::Code::create_extproc', spec, lib);
            END;

        -- initialize config for testing
        PROCEDURE test
            AS
            EXTERNAL NAME "ora_perl_test"
            LIBRARY "TEST_PERL_LIB"
            WITH CONTEXT
            PARAMETERS (
                CONTEXT
            );
    END TestPerl;
} );
print "done.\n";

# create code table
print "  Creating tables...";
local $dbh->{'RaiseError'} = 0;
local $dbh->{'PrintError'} = 0;
$dbh->do('DROP TABLE EPTEST_USER_PERL_SOURCE');
local $dbh->{'RaiseError'} = 1;
local $dbh->{'PrintError'} = 1;
$r = $dbh->do(qq{
-- create code table
    CREATE TABLE EPTEST_USER_PERL_SOURCE (
        name VARCHAR2(255) primary key,
        plsql_spec VARCHAR2(255),
        language VARCHAR2(255),
        version NUMBER(11),
        code CLOB
    )
});

# create test table
local $dbh->{'RaiseError'} = 0;
local $dbh->{'PrintError'} = 0;
$dbh->do('DROP TABLE EPTEST_TABLE');
local $dbh->{'RaiseError'} = 1;
local $dbh->{'PrintError'} = 1;
$r = $dbh->do(qq{
    CREATE TABLE EPTEST_TABLE (
        junk VARCHAR2(255)
    )
});
print "done.\n";

# create perl_config view
print "  Creating views...";
$r = $dbh->do(qq{
CREATE OR REPLACE VIEW eptest_perl_config AS (
    select
        TestPerl.config('bootstrap_file') as BOOTSTRAP_FILE,
        TestPerl.config('code_table') as CODE_TABLE,
        TestPerl.config('inc_path') as INC_PATH,
        TestPerl.config('debug_directory') as DEBUG_DIRECTORY,
        TestPerl.config('max_code_size') as MAX_CODE_SIZE,
        TestPerl.config('max_sub_args') as MAX_SUB_ARGS,
        TestPerl.config('trusted_code_directory') as TRUSTED_CODE_DIRECTORY,
        TestPerl.config('tainting') as TAINTING,
        TestPerl.config('ddl_format') as DDL_FORMAT,
        TestPerl.config('session_namespace') as SESSION_NAMESPACE,
        TestPerl.config('package_subs') as PACKAGE_SUBS,
        TestPerl.config('reparse_subs') as REPARSE_SUBS
    from dual
) });

# create perl_status view
$r = $dbh->do(qq{
CREATE OR REPLACE VIEW eptest_perl_status AS (
    select
        TestPerl.version as EXTPROC_PERL_VERSION,
        TestPerl.debug_status as DEBUG_STATUS,
        TestPerl.debug_file as DEBUG_FILE,
        TestPerl.package as PACKAGE,
        TestPerl.errno as ERRNO,
        TestPerl.errsv as ERRSV
    from dual
) });
print "done.\n\n";

# run the tests
runtests @ARGV;

# cleanup
print "\nCleaning up database...";
$dbh->do('DROP VIEW eptest_perl_config');
$dbh->do('DROP VIEW eptest_perl_status');
$dbh->do('DROP TABLE EPTEST_TABLE');
$dbh->do('DROP TABLE EPTEST_USER_PERL_SOURCE');
$dbh->do('DROP PACKAGE TestPerl');
$dbh->do('DROP LIBRARY TEST_PERL_LIB');
$dbh->disconnect;
chmod(0755, "$build_dir/t");
print "done.\n\n";
print "Testing complete.\n\n";
