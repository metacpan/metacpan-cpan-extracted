package Vayne::Tracker;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use MooX::late;

use Coro;
use MongoDB;
use Clone qw(clone);
use Data::Dumper;
use Log::Log4perl qw(:easy);


use Vayne;
use Vayne::Task;
use Vayne::Zk;
use Vayne::Queue;

has db => (is => 'rw', isa => 'MongoDB::Database');

use constant CONF           => 'mongo';
use constant ADD_JOB_WORKER => 4;
use constant MAX_UP_JOB     => 30;
use constant POISON         => 'POISON_PILL';

sub collection_job{$_[0]->db->get_collection("job")};
sub collection_task{$_[0]->db->get_collection("task")};

sub add_task
{
    my ($this, $policy, $opt, $workload, $concurency, $zk, $task) = splice @_, 0, 5;

    $task = Vayne::Task->make($opt, @$workload);
    $zk = Vayne::Zk->new;
    my($code, $param) = @$policy;

    my $time = time;

    #apply region policy
    if( 
        my($region) = $code =~ /^region\:(.+)$/
    )
    {
        $_->region( $region ) for @{$task->jobs}    

    }else{

        my $sub = Vayne->strategy( $code );
        my(%meta, @regions) = $zk->meta;
        @regions = grep{ %{ $meta{$_} } }keys %meta or die "no defined regions";

        for my $job( @{$task->jobs} )
        {
            my $region = $sub->($param, clone($job), @regions);
            $region ||= $regions[0];
            $job->region($region);
        }
        
    }
    $task->start(time);
    

    #add task
    __PACKAGE__->new->collection_task->insert_one({ _id => $task->taskid, $task->to_hash });
    DEBUG sprintf "add task, using %s s", time - $time;
    
    $time = time;
    #send jobs to queue
    my($channel, @worker) = Coro::Channel->new(MAX_UP_JOB);
    for( 1 .. $concurency||ADD_JOB_WORKER )
    {
        push @worker, async
        {
            my %queue;
            while(1)
            {
                my $job = $channel->get;
                last if $job eq POISON;
                my $r = $job->region;
                $queue{$r} ||= Vayne::Queue->new( $zk->queue( $r ) );
                $job->taskid($task->taskid);
                $queue{$r}->add_job($job);
            }
        }
    }
    DEBUG sprintf "concurency: %s", scalar @worker;
    $channel->put($_) for @{$task->jobs};
    $channel->put(POISON) for @worker;
    $_->join for @worker;

    DEBUG sprintf "enqueue job(%d), using %s s", scalar @{$task->jobs}, time - $time;
    $task->taskid;
}

sub update_task
{
    my ($this, @taskid) = shift;
    my $c_task = $this->collection_task; 

    my $time = time;

    my @task = $c_task->find( { status=>{'$nin'=>[STATUS_COMPLETE, STATUS_CANCEL, STATUS_TIMEOUT]}} )->all;
    INFO sprintf "find [%s] tasks to track, using %s s", scalar @task, time - $time;

    for my $task(@task)
    {

        my $time = time;

        my $count = $this->collection_job->count({ taskid=> $task->{taskid} });
        my $status = $count != @{ $task->{job} } ? time > $task->{start} + $task->{expire} ? STATUS_TIMEOUT : STATUS_RUN : STATUS_COMPLETE;

        $c_task->update_one({'_id' => $task->{taskid}}, { '$set' => { status => $status, complete=>$count } });

        INFO sprintf "up task: %s, name: %s, status: %s, complete: %s/%s, using: %ss", $task->{taskid}, $task->{name}, $status, $count||0, scalar @{$task->{job}}, time - $time;

        push @taskid, $task->{taskid} if grep{ $status eq $_ }(STATUS_TIMEOUT, STATUS_COMPLETE);
    }
    INFO sprintf "update task over using %s s", time - $time if @task;
    wantarray ? @taskid : \@taskid;
}

sub query_task
{
    my ($this, $taskid) = @_;
    my $task = $this->collection_task->find_one({ _id => $taskid });
}

sub BUILD
{
    my $self = shift;

    my $conf = Vayne->conf(CONF);
    my $mc = MongoDB::MongoClient->new( %$conf );
    $self->db($mc->db( $conf->{db_name} || $Vayne::NAMESPACE ));
}

1;
