use Test::More;

BEGIN {
    use Config;
    plan skip_all => "Perl not compiled with 'useithreads'\n"
        if ( !$Config{'useithreads'} );
    eval 'use threads; 1' or die "could not load threads module";

    use_ok( 'Thread::Task::Concurrent', 'tmsg' );
}

my @data   = ( 0 .. 4 );
my $tq     = Thread::Task::Concurrent->new( task => \&task, max_instances => 2, arg => [qw/a b c d e/] );
my $result = $tq->enqueue(@data)->start->join->result;

is_deeply( $result, [qw/A B C D E/] );

sub task {
    my ( $arg, $task_arg ) = @_;
    return uc( $task_arg->[$arg] );
}

done_testing();

