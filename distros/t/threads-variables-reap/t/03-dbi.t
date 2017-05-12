#!perl

BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use threads;
my $have_threads_reap = 0;
eval { require threads::variables::reap; $have_threads_reap = 1; };
my $have_dbd_csv = 0;
eval { require DBD::File; require DBD::CSV; $have_dbd_csv = 1 if( $DBD::File::VERSION >= 0.38 ); };
my $have_dbd_sqlite = 0;
eval { require DBD::SQLite; $have_dbd_sqlite = 1; };
my $have_file_path = 0;
eval { require File::Path; File::Path->import( qw(make_path remove_tree) ); $have_file_path = 1; };
my $have_log4perl = 0;
eval { require Log::Log4perl; $have_log4perl = 1; };
use FindBin;
use Test::More;

INIT {
    # for debugging
    1;
}

plan( skip_all => "Test 03-dbi isn't reasonable without threads::variable::reap" ) unless $have_threads_reap;
plan( skip_all => "Test 03-dbi isn't reasonable without Log::Log4perl" ) unless $have_log4perl;

threads::variables::reap->import;

my $nTests = 0;
++$nTests if( $have_dbd_csv );
++$nTests if( $have_dbd_sqlite );

plan( skip_all => "Test 03-dbi requires at least one of 'DBD::CSV', 'DBD::SQLite'" ) unless $nTests;

plan( tests => $nTests );

sub runThreads(@)
{
    my @threads = @_;
    foreach my $thr (@threads)
    {
        threads->create($thr);
    }
    do
    {
        threads->yield();
        foreach my $thr ( threads->list(threads::joinable) )
        {
            $thr->join();
        }
    } while ( scalar( threads->list(threads::all) ) > 0 );
}

my %dsns;
my $dbdir;
if( $have_file_path )
{
    $dbdir = File::Spec->catdir( $FindBin::Bin, "output" );
    make_path( $dbdir ) unless( -d $dbdir );
}
else
{
    $dbdir = $FindBin::Bin;
}

if( $have_dbd_csv )
{
    $dsns{'DBD::CSV'} = "DBI:CSV:f_dir=$dbdir;f_ext=.csv;f_lock=2";
    go4Test('DBD::CSV');
}

if( $have_dbd_sqlite )
{
    my $dbfile = File::Spec->catfile( $dbdir, "log4perltest.db" );
    $dsns{'DBD::SQLite'} = "DBI:SQLite:dbname=$dbfile";
    go4Test('DBD::SQLite');
}

if( $have_file_path )
{
    remove_tree( $dbdir ) unless( $ENV{AUTHOR_WANTS_KEEP_TABLES} );
}

sub go4Test
{
    my $driver = shift;
    SKIP: {
	local $@ = '';
	eval {
	    my $dsn = $dsns{$driver};
	    my $dbh = DBI->connect($dsn) or die "Can't connect to '$dsn': $DBI::errstr";
	    my $sth = $dbh->prepare( 'CREATE TABLE log4perltest ('
				     . 'log_time CHAR, log_level CHAR, log_user CHAR, source CHAR, log_text CHAR)' )
			or die "Can't prepare 'create table log4perltest ...' " . $dbh->errstr();
	    $sth->execute() or die "Can't execute 'create table log4perltest ...' " . $dbh->errstr();
	    $sth->finish();
	    log4thread($driver);
	    unless( $ENV{AUTHOR_WANTS_KEEP_TABLES} )
	    {
		$sth = $dbh->prepare( "DROP TABLE log4perltest" );
		$sth->execute();
	    }
	    $dbh->disconnect();
	};
	skip "DBI/DBD error: $@", 1 if $@;
    }
}

sub log4thread
{
    my $driver = shift;
    my $dsn = $dsns{$driver};
    my $log4perlCfg = <<"EOC";
log4perl.rootLogger = TRACE, DBAppndr
log4perl.appender.DBAppndr             = Log::Log4perl::Appender::DBI::threadsafe
log4perl.appender.DBAppndr.datasource  = $dsn
log4perl.appender.DBAppndr.sql         =  insert into log4perltest \\
   (log_time, log_level, log_user, source, log_text) \\
   values (?,?,?,?,?)
log4perl.appender.DBAppndr.params.1 = %d
log4perl.appender.DBAppndr.params.2 = %p
log4perl.appender.DBAppndr.params.3 = %X{USERNAME}
log4perl.appender.DBAppndr.params.4 = %F{1}
                              #5 is the message from log() call
    
log4perl.appender.DBAppndr.usePreparedStmt = 1
 #--or--
log4perl.appender.DBAppndr.bufferSize = 2

#just pass through the array of message items in the log statement 
log4perl.appender.DBAppndr.layout    = Log::Log4perl::Layout::NoopLayout
log4perl.appender.DBAppndr.warp_message = 0
EOC
    
    Log::Log4perl->init(\$log4perlCfg);
    Log::Log4perl::MDC->put('USERNAME', $ENV{ $^O eq 'MSWin32' ? 'USERNAME' : 'USER'} );

    runThreads( \&thrLogTrace, \&thrLogDebug, \&thrLogInfo, \&thrLogWarn, \&thrLogError, \&thrLogFatal );

    my $dbh = DBI->connect($dsn) or die "Can't connect to '$dsn': $DBI::errstr";
    my $sth = $dbh->prepare( "SELECT count(*) FROM log4perltest" );
    $sth->execute();
    my $row = $sth->fetchrow_arrayref();
    is( $row->[0], 6, "Number of log entries for $dsn" );
    $dbh->disconnect();
}

sub thrLogTrace
{
    my $logger = Log::Log4perl->get_logger();
    $logger->trace( 'message from thread ' . threads->tid() );
}

sub thrLogDebug
{
    my $logger = Log::Log4perl->get_logger();
    $logger->debug( 'message from thread ' . threads->tid() );
}

sub thrLogInfo
{
    my $logger = Log::Log4perl->get_logger();
    $logger->info( 'message from thread ' . threads->tid() );
}

sub thrLogWarn
{
    my $logger = Log::Log4perl->get_logger();
    $logger->warn( 'message from thread ' . threads->tid() );
}

sub thrLogError
{
    my $logger = Log::Log4perl->get_logger();
    $logger->error( 'message from thread ' . threads->tid() );
}

sub thrLogFatal
{
    my $logger = Log::Log4perl->get_logger();
    $logger->fatal( 'message from thread ' . threads->tid() );
}

package Log::Log4perl::Appender::DBI::threadsafe;

use strict;
use warnings;

use threads::variables::reap;

BEGIN {
    eval { require Log::Log4perl::Appender::DBI; };
    @Log::Log4perl::Appender::DBI::threadsafe::ISA = qw(Log::Log4perl::Appender::DBI);
}

sub new
{
    my($proto, %p) = @_;
    my $self = $proto->SUPER::new(%p);
    if( $self->{usePreparedStmt} )
    {
	$self->{sql} = $p{sql};
    }
    reap($self->{dbh});
    reap($self->{sth});
    return $self;
}

sub log
{
    my $self = shift;
    unless( defined( $self->{dbh} ) )
    {
	$self->{dbh} = $self->{connect}->();
	if( $self->{usePreparedStmt} && !defined($self->{sth}) )
	{
	    $self->{sth} = $self->create_statement($self->{sql});
	}
    }
    
    $self->SUPER::log(@_);
}

