#!perl

BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

#eval { require threads; use threads; $have_threads = 1; } if( 'define' eq $Config{usethreads} );
use threads;
use threads::variables::reap;
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

my $dbh2 = 6;
reap($dbh2);
my @ary2;
@ary2 = qw'Perl rocks';
reap(@ary2);
my %h2;
%h2 = ( Perl => 'rocks' );
reap(%h2);

runThreads( \&runThreadScalar, \&runThreadArray, \&runThreadHash );
++$dbh2;
is( $dbh2, 7, 'function scalar' );
is( join(' ', @ary2), 'Perl rocks', 'function array' );
is( join(' ', %h2), 'Perl rocks', 'function hash' );

sub runThreadScalar
{
    is( $dbh2, undef, 'new thread function scalar in ' . threads->tid() );
    $dbh2 = 4;
    threads->create( \&runThreadScalar, 1 ) unless( $_[0] );
}

sub runThreadArray
{
    is( join(' ', @ary2), '', 'new thread function array in ' . threads->tid() );
    @ary2 = qw'NetBSD rocks';
    threads->create( \&runThreadArray, 1 ) unless( $_[0] );
}

sub runThreadHash
{
    is( join(' ', %h2), '', 'new thread function hash in ' . threads->tid() );
    %h2 = ( NetBSD => 'rocks' );
    threads->create( \&runThreadHash, 1 ) unless( $_[0] );
}
