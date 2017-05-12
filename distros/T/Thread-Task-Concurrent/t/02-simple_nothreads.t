use warnings;

use Test::More;

BEGIN { use_ok('Thread::Task::Concurrent', 'tmsg'); }

my @data = ( 0..4);
my $tq = Thread::Task::Concurrent->new( task => \&task, max_instances => 2, arg => [ qw/a b c d e/]);
$tq->start;
$tq->enqueue(@data);
$tq->join;
my $result = $tq->result;

is_deeply($result, [qw/A B C D E/]);

sub task {
    my ($arg, $task_arg) = @_;
    return uc($task_arg->[$arg]);
}


done_testing();

