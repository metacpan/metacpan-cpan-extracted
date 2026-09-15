#!perl
##----------------------------------------------------------------------------
## WebAuthn - t/08.threads.t
## Thread safety tests.
## Skipped entirely when Perl is not compiled with useithreads.
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    use Config;
    use Web::Authn;
    use Web::Authn::Parse;
    if( !$Config{useithreads} )
    {
        plan( skip_all => "Perl $^V is not compiled with useithreads, skipping thread safety tests" );
    }
    elsif( !eval { require threads; 1 } )
    {
        plan( skip_all => 'threads.pm not installed' );
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;
require threads;

# NOTE: challenge from several ithreads
subtest 'challenge from several ithreads' => sub
{
    my @thr;
    for( 1 .. 4 )
    {
        push( @thr, threads->create(sub
        {
            my $authn = Web::Authn->new(
                rp_id           => 'example.com',
                rp_name         => 'Example',
                expected_origin => 'https://example.com',
            );
            my $opts = $authn->generate_registration_options(
                user_name => 'thread-user',
            );
            return( $opts ? $opts->{challenge} : undef );
        }) );
    }
    my @ch;
    foreach my $t ( @thr )
    {
        push( @ch, $t->join );
    }
    is( scalar( @ch ), 4, 'four challenges returned' );
    foreach my $c ( @ch )
    {
        ok( defined( $c ) && length( $c ) == 64, 'challenge is 64 bytes' );
    }
    my %seen;
    $seen{ $_ }++ for( @ch );
    is( scalar( keys( %seen ) ), 4, 'challenges are distinct' );
};

# NOTE: Parse::generate_challenge in a thread
subtest 'Parse::generate_challenge in a thread' => sub
{
    my $thr = threads->create(sub
    {
        return( Web::Authn::Parse::generate_challenge(16) );
    });
    my $c = $thr->join;
    is( length( $c ), 16, '16-byte challenge from worker' );
};

done_testing;

__END__
