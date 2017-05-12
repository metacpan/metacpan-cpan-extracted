#!perl

BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
    $^W = 0;
}

#eval { require threads; use threads; $have_threads = 1; } if( 'define' eq $Config{usethreads} );
use threads;
use threads::variables::reap::attr;
use Test::More;

INIT {
    # for debugging
    1;
}

#plan( skip_all => "Test 01-basic isn't reasonable without threads" ) unless $threads::threads;
plan( tests => 9 );

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
	foreach my $thr (threads->list(threads::joinable) )
	{
	    $thr->join();
	}
    } while( scalar( threads->list(threads::all) ) > 0 );
}

our $dbh1 : reap;
$dbh1 = 0;
our @ary1 : reap;
@ary1 = qw(Hello world);
our %h1 : reap;
%h1 = ( Hello => 'world' );

runThreads( \&runThreadScalar, \&runThreadArray, \&runThreadHash );
++$dbh1;
is( $dbh1, 1, 'attributed scalar' );
is( join(' ', @ary1), 'Hello world', 'attributed array' );
is( join(' ', %h1), 'Hello world', 'attributed hash' );

sub runThreadScalar
{
    is( $dbh1, undef, 'new thread attributed scalar in ' . threads->tid() );
    $dbh1 = 2;
    threads->create( \&runThreadScalar, 1 ) unless( $_[0] );
}

sub runThreadArray
{
    is( join(' ', @ary1), '', 'new thread attributed array in ' . threads->tid() );
    @ary1 = qw(Hello Perl);
    threads->create( \&runThreadArray, 1 ) unless( $_[0] );
}

sub runThreadHash
{
    is( join(' ', %h1), '', 'new thread attributed hash in ' . threads->tid() );
    %h1 = ( Hello => 'world' );
    threads->create( \&runThreadHash, 1 ) unless( $_[0] );
}
